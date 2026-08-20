import argparse
import csv
import hashlib
import json
import math
import random
import sys
import time
from collections import Counter
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import torch
from PIL import Image, ImageOps
from sklearn.calibration import calibration_curve
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    brier_score_loss,
    classification_report,
    confusion_matrix,
    f1_score,
)
from torch import nn
from torch.utils.data import DataLoader, Dataset, WeightedRandomSampler
from torchvision import models, transforms


ROOT_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = ROOT_DIR.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.trained_model import TrainedSkinModel
from app.vision import InvalidImageError, SkinVisionAnalyzer


CLASSES = ["none", "mild", "moderate", "severe"]


class ManifestDataset(Dataset):
    def __init__(self, rows: list[dict[str, str]], transform) -> None:
        self.rows = rows
        self.transform = transform

    def __len__(self) -> int:
        return len(self.rows)

    def __getitem__(self, index: int):
        row = self.rows[index]
        path = REPO_DIR / row["image_path"]
        with Image.open(path) as image:
            image = ImageOps.exif_transpose(image).convert("RGB")
        return self.transform(image), int(row["label_index"]), row["subject_id"], row["image_path"]


def main() -> None:
    parser = argparse.ArgumentParser(description="Train and evaluate a calibrated MobileNetV3 acne-severity baseline.")
    parser.add_argument("--manifest-dir", default="../datasets/ml_release_v1")
    parser.add_argument("--output-dir", default="../models/cnn_acne_severity_v1")
    parser.add_argument("--epochs", type=int, default=8)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--image-size", type=int, default=224)
    parser.add_argument("--seed", type=int, default=20260820)
    parser.add_argument("--patience", type=int, default=3)
    parser.add_argument("--existing-model", default="../models/skino_acne_care_normal_model.json")
    args = parser.parse_args()

    seed_everything(args.seed)
    manifest_dir = Path(args.manifest_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    train_rows = read_manifest(manifest_dir / "acne_severity_train.csv")
    val_rows = read_manifest(manifest_dir / "acne_severity_validation.csv")
    test_rows = read_manifest(manifest_dir / "acne_severity_test.csv")
    verify_subject_separation(train_rows, val_rows, test_rows)

    train_transform = transforms.Compose([
        transforms.RandomResizedCrop(args.image_size, scale=(0.82, 1.0), ratio=(0.9, 1.1)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(brightness=0.12, contrast=0.12),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    eval_transform = transforms.Compose([
        transforms.Resize((args.image_size, args.image_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    train_dataset = ManifestDataset(train_rows, train_transform)
    val_dataset = ManifestDataset(val_rows, eval_transform)
    test_dataset = ManifestDataset(test_rows, eval_transform)
    label_counts = Counter(int(row["label_index"]) for row in train_rows)
    sample_weights = [1.0 / label_counts[int(row["label_index"])] for row in train_rows]
    sampler = WeightedRandomSampler(sample_weights, num_samples=len(sample_weights), replacement=True)
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, sampler=sampler, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=args.batch_size, shuffle=False, num_workers=0)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model, pretrained = build_model()
    model.to(device)
    optimizer = torch.optim.AdamW((parameter for parameter in model.parameters() if parameter.requires_grad), lr=3e-4, weight_decay=1e-4)
    criterion = nn.CrossEntropyLoss(label_smoothing=0.04)

    history = []
    best_state = None
    best_macro_f1 = -1.0
    stale_epochs = 0
    started = time.time()

    for epoch in range(1, args.epochs + 1):
        train_loss = train_epoch(model, train_loader, optimizer, criterion, device)
        val_logits, val_labels, _, _ = predict(model, val_loader, device)
        val_predictions = val_logits.argmax(axis=1)
        val_macro_f1 = f1_score(val_labels, val_predictions, average="macro", zero_division=0)
        val_accuracy = accuracy_score(val_labels, val_predictions)
        record = {"epoch": epoch, "train_loss": round(train_loss, 5), "validation_macro_f1": round(float(val_macro_f1), 5), "validation_accuracy": round(float(val_accuracy), 5)}
        history.append(record)
        print(json.dumps(record), flush=True)
        if val_macro_f1 > best_macro_f1 + 1e-4:
            best_macro_f1 = float(val_macro_f1)
            best_state = {key: value.detach().cpu().clone() for key, value in model.state_dict().items()}
            stale_epochs = 0
        else:
            stale_epochs += 1
            if stale_epochs >= args.patience:
                break

    if best_state is None:
        raise RuntimeError("Training did not produce a checkpoint.")
    model.load_state_dict(best_state)
    model.to(device)

    val_logits, val_labels, _, _ = predict(model, val_loader, device)
    temperature = fit_temperature(val_logits, val_labels)
    test_logits, test_labels, test_subjects, test_paths = predict(model, test_loader, device)
    candidate_metrics = evaluate_logits(test_logits, test_labels, temperature)
    baseline_metrics = evaluate_existing_baseline(test_rows, Path(args.existing_model).resolve())
    promotion = promotion_decision(candidate_metrics, baseline_metrics, manifest_dir)

    checkpoint = {
        "architecture": "mobilenet_v3_small",
        "classes": CLASSES,
        "image_size": args.image_size,
        "temperature": temperature,
        "pretrained_imagenet": pretrained,
        "state_dict": best_state,
        "manifest_hashes": {split: file_sha256(manifest_dir / f"acne_severity_{split}.csv") for split in ["train", "validation", "test"]},
    }
    torch.save(checkpoint, output_dir / "model.pt")
    export_torchscript(model.cpu(), args.image_size, output_dir / "model.torchscript.pt")

    report = {
        "model": "MobileNetV3-Small acne severity baseline",
        "classes": CLASSES,
        "device": str(device),
        "pretrained_imagenet": pretrained,
        "temperature": temperature,
        "duration_seconds": round(time.time() - started, 1),
        "history": history,
        "candidate_test": candidate_metrics,
        "existing_baseline_test": baseline_metrics,
        "promotion": promotion,
        "limitations": [
            "Subject separation uses an augmentation-family proxy, not verified person IDs.",
            "No candidate image has joined age or skin-tone metadata.",
            "Labels were not re-reviewed by a dermatologist inside this project.",
            "This model is an experimental acne-severity classifier, not a medical diagnosis model.",
        ],
    }
    (output_dir / "evaluation_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    write_predictions(output_dir / "test_predictions.csv", test_paths, test_subjects, test_labels, test_logits, temperature)
    plot_confusion(candidate_metrics["confusion_matrix"], output_dir / "confusion_matrix.png", normalize=False)
    plot_confusion(candidate_metrics["confusion_matrix_normalized"], output_dir / "confusion_matrix_normalized.png", normalize=True)
    plot_reliability(test_logits, test_labels, temperature, output_dir / "reliability_diagram.png")
    print(f"Saved candidate report to {output_dir / 'evaluation_report.json'}")
    print(f"Promotion status: {promotion['status']}")


def build_model() -> tuple[nn.Module, bool]:
    pretrained = True
    try:
        model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    except Exception as exc:
        print(f"Pretrained weights unavailable ({exc}); training from random initialization.", flush=True)
        model = models.mobilenet_v3_small(weights=None)
        pretrained = False
    for parameter in model.features.parameters():
        parameter.requires_grad = False
    for block in list(model.features.children())[-3:]:
        for parameter in block.parameters():
            parameter.requires_grad = True
    model.classifier[3] = nn.Linear(model.classifier[3].in_features, len(CLASSES))
    return model, pretrained


def train_epoch(model, loader, optimizer, criterion, device) -> float:
    model.train()
    total_loss = 0.0
    total = 0
    for images, labels, _, _ in loader:
        images, labels = images.to(device), labels.to(device)
        optimizer.zero_grad(set_to_none=True)
        logits = model(images)
        loss = criterion(logits, labels)
        loss.backward()
        optimizer.step()
        total_loss += float(loss.item()) * labels.size(0)
        total += labels.size(0)
    return total_loss / max(total, 1)


@torch.no_grad()
def predict(model, loader, device):
    model.eval()
    logits, labels, subjects, paths = [], [], [], []
    for images, batch_labels, batch_subjects, batch_paths in loader:
        logits.append(model(images.to(device)).cpu())
        labels.append(batch_labels)
        subjects.extend(batch_subjects)
        paths.extend(batch_paths)
    return torch.cat(logits).numpy(), torch.cat(labels).numpy(), subjects, paths


def fit_temperature(logits: np.ndarray, labels: np.ndarray) -> float:
    candidates = np.linspace(0.5, 5.0, 181)
    losses = []
    for temperature in candidates:
        probabilities = softmax(logits / temperature)
        losses.append(-np.log(np.clip(probabilities[np.arange(len(labels)), labels], 1e-8, 1)).mean())
    return round(float(candidates[int(np.argmin(losses))]), 4)


def evaluate_logits(logits: np.ndarray, labels: np.ndarray, temperature: float) -> dict[str, object]:
    probabilities = softmax(logits / temperature)
    predictions = probabilities.argmax(axis=1)
    matrix = confusion_matrix(labels, predictions, labels=list(range(len(CLASSES))))
    normalized = matrix / np.maximum(matrix.sum(axis=1, keepdims=True), 1)
    report = classification_report(labels, predictions, labels=list(range(len(CLASSES))), target_names=CLASSES, output_dict=True, zero_division=0)
    return {
        "accuracy": round(float(accuracy_score(labels, predictions)), 5),
        "balanced_accuracy": round(float(balanced_accuracy_score(labels, predictions)), 5),
        "macro_f1": round(float(f1_score(labels, predictions, average="macro", zero_division=0)), 5),
        "expected_calibration_error": round(float(expected_calibration_error(probabilities, labels)), 5),
        "multiclass_brier_score": round(float(np.mean(np.sum((probabilities - np.eye(len(CLASSES))[labels]) ** 2, axis=1))), 5),
        "per_class": {label: {key: round(float(value), 5) if isinstance(value, (int, float)) else value for key, value in report[label].items()} for label in CLASSES},
        "confusion_matrix": matrix.tolist(),
        "confusion_matrix_normalized": np.round(normalized, 5).tolist(),
    }


def evaluate_existing_baseline(rows: list[dict[str, str]], model_path: Path) -> dict[str, object]:
    trained_model = TrainedSkinModel.load(model_path)
    analyzer = SkinVisionAnalyzer(trained_model=trained_model)
    expected, predicted, skipped = [], [], []
    for row in rows:
        path = REPO_DIR / row["image_path"]
        try:
            result = analyzer.analyze(path.read_bytes())
            label = result.acne_severity if result.acne_severity in CLASSES else "none"
            expected.append(int(row["label_index"]))
            predicted.append(CLASSES.index(label))
        except (OSError, InvalidImageError, ValueError) as exc:
            skipped.append({"image": row["image_path"], "error": str(exc)})
    matrix = confusion_matrix(expected, predicted, labels=list(range(len(CLASSES))))
    report = classification_report(expected, predicted, labels=list(range(len(CLASSES))), target_names=CLASSES, output_dict=True, zero_division=0)
    return {
        "accuracy": round(float(accuracy_score(expected, predicted)), 5),
        "balanced_accuracy": round(float(balanced_accuracy_score(expected, predicted)), 5),
        "macro_f1": round(float(f1_score(expected, predicted, average="macro", zero_division=0)), 5),
        "per_class": {label: {key: round(float(value), 5) if isinstance(value, (int, float)) else value for key, value in report[label].items()} for label in CLASSES},
        "confusion_matrix": matrix.tolist(),
        "skipped": skipped,
    }


def promotion_decision(candidate: dict[str, object], baseline: dict[str, object], manifest_dir: Path) -> dict[str, object]:
    summary = json.loads((manifest_dir / "manifest_summary.json").read_text(encoding="utf-8"))
    metric_win = candidate["macro_f1"] >= baseline["macro_f1"] + 0.03 and candidate["balanced_accuracy"] >= baseline["balanced_accuracy"]
    calibration_ok = candidate["expected_calibration_error"] <= 0.10
    blockers = list(summary.get("promotion_blockers", []))
    if not metric_win:
        blockers.append("Candidate did not clear the +0.03 macro-F1 and non-decreasing balanced-accuracy gate.")
    if not calibration_ok:
        blockers.append("Candidate expected calibration error is above 0.10.")
    return {
        "status": "promote" if metric_win and calibration_ok and not blockers else "hold",
        "metric_gate_passed": metric_win,
        "calibration_gate_passed": calibration_ok,
        "required_macro_f1": round(float(baseline["macro_f1"] + 0.03), 5),
        "blockers": blockers,
    }


def expected_calibration_error(probabilities: np.ndarray, labels: np.ndarray, bins: int = 10) -> float:
    confidence = probabilities.max(axis=1)
    predictions = probabilities.argmax(axis=1)
    edges = np.linspace(0, 1, bins + 1)
    total = 0.0
    for lower, upper in zip(edges[:-1], edges[1:]):
        mask = (confidence > lower) & (confidence <= upper)
        if mask.any():
            total += mask.mean() * abs((predictions[mask] == labels[mask]).mean() - confidence[mask].mean())
    return total


def plot_confusion(matrix, path: Path, normalize: bool) -> None:
    values = np.asarray(matrix)
    fig, axis = plt.subplots(figsize=(6.4, 5.4))
    image = axis.imshow(values, cmap="Oranges", vmin=0, vmax=1 if normalize else None)
    axis.set(xticks=range(len(CLASSES)), yticks=range(len(CLASSES)), xticklabels=CLASSES, yticklabels=CLASSES, xlabel="Predicted", ylabel="Actual", title="Normalized confusion matrix" if normalize else "Confusion matrix")
    threshold = values.max() / 2 if values.size else 0
    for row in range(values.shape[0]):
        for column in range(values.shape[1]):
            text = f"{values[row, column]:.2f}" if normalize else str(int(values[row, column]))
            axis.text(column, row, text, ha="center", va="center", color="white" if values[row, column] > threshold else "#30231d")
    fig.colorbar(image, ax=axis, fraction=.046, pad=.04)
    fig.tight_layout()
    fig.savefig(path, dpi=170)
    plt.close(fig)


def plot_reliability(logits: np.ndarray, labels: np.ndarray, temperature: float, path: Path) -> None:
    probabilities = softmax(logits / temperature)
    confidence = probabilities.max(axis=1)
    correct = (probabilities.argmax(axis=1) == labels).astype(int)
    observed, predicted = calibration_curve(correct, confidence, n_bins=10, strategy="uniform")
    fig, axis = plt.subplots(figsize=(6, 5))
    axis.plot([0, 1], [0, 1], "--", color="#8b817a", label="Perfect calibration")
    axis.plot(predicted, observed, marker="o", color="#f36a16", label="Candidate")
    axis.set(xlabel="Mean confidence", ylabel="Observed accuracy", xlim=(0, 1), ylim=(0, 1), title="Reliability diagram")
    axis.legend()
    axis.grid(alpha=.18)
    fig.tight_layout()
    fig.savefig(path, dpi=170)
    plt.close(fig)


def export_torchscript(model: nn.Module, image_size: int, path: Path) -> None:
    model.eval()
    traced = torch.jit.trace(model, torch.zeros(1, 3, image_size, image_size))
    traced.save(str(path))


def write_predictions(path: Path, paths, subjects, labels, logits, temperature) -> None:
    probabilities = softmax(logits / temperature)
    predictions = probabilities.argmax(axis=1)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["image_path", "subject_id", "actual", "predicted", "confidence", *[f"p_{label}" for label in CLASSES]])
        for image, subject, actual, predicted, probability in zip(paths, subjects, labels, predictions, probabilities):
            writer.writerow([image, subject, CLASSES[int(actual)], CLASSES[int(predicted)], round(float(probability.max()), 6), *[round(float(value), 6) for value in probability]])


def verify_subject_separation(*splits: list[dict[str, str]]) -> None:
    seen = {}
    for index, rows in enumerate(splits):
        for row in rows:
            subject = row["subject_id"]
            if subject in seen and seen[subject] != index:
                raise RuntimeError(f"Subject leakage detected for {subject}.")
            seen[subject] = index


def read_manifest(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def softmax(values: np.ndarray) -> np.ndarray:
    shifted = values - values.max(axis=1, keepdims=True)
    exponent = np.exp(shifted)
    return exponent / exponent.sum(axis=1, keepdims=True)


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def seed_everything(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


if __name__ == "__main__":
    main()
