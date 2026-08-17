import argparse
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path
from statistics import mean

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.trained_model import (
    AcneSeverityProfile,
    ConcernProfile,
    SkinTypeProfile,
    TrainedSkinModel,
    euclidean_distance,
    metrics_to_vector,
)
from app.treatment_packages import DEFAULT_TREATMENT_PACKAGES
from app.vision import InvalidImageError, SkinVisionAnalyzer


MIN_IMAGES_PER_SKIN_TYPE = 20
MIN_IMAGES_PER_CONCERN = 20
NO_CONCERN_ALIASES = {"clear", "healthy", "none", "no_concern", "no_concerns", "normal"}


def main() -> None:
    parser = argparse.ArgumentParser(description="Train Skino's first custom skin model from a prepared dataset.")
    parser.add_argument("--dataset-dir", required=True, help="Prepared dataset directory containing metadata_prepared.csv.")
    parser.add_argument("--metadata", default="metadata_prepared.csv", help="Prepared metadata file name.")
    parser.add_argument("--output", required=True, help="Output JSON model path.")
    parser.add_argument("--report", help="Optional evaluation/training report JSON path.")
    parser.add_argument("--allow-small", action="store_true", help="Allow tiny proof-of-concept datasets.")
    parser.add_argument("--concern-only", action="store_true", help="Train concerns without requiring skin_type labels.")
    parser.add_argument("--skin-type-only", action="store_true", help="Train skin types without requiring concern labels.")
    args = parser.parse_args()

    if args.concern_only and args.skin_type_only:
        raise SystemExit("Use either --concern-only or --skin-type-only, not both.")

    dataset_dir = Path(args.dataset_dir).resolve()
    metadata_path = dataset_dir / args.metadata
    output_path = Path(args.output).resolve()
    report_path = Path(args.report).resolve() if args.report else output_path.with_suffix(".report.json")

    rows = read_rows(metadata_path)
    analyzer = SkinVisionAnalyzer()
    samples, skipped = extract_samples(dataset_dir, rows, analyzer, concern_only=args.concern_only)
    quality_errors = validate_training_quality(
        samples,
        concern_only=args.concern_only,
        skin_type_only=args.skin_type_only,
    )

    if quality_errors and not args.allow_small:
        write_report(report_path, samples, skipped, quality_errors, metrics={})
        raise SystemExit(
            "Dataset is not ready for training. See report JSON. "
            "Use --allow-small only for local proof-of-concept runs."
        )

    model = train_model(samples)
    metrics = evaluate_model(model, samples)
    model.save(
        output_path,
        metadata={
            "dataset_dir": str(dataset_dir),
            "total_samples": len(samples),
            "quality_errors": quality_errors,
            "warning": "Nearest-centroid baseline model. Replace with deep CNN after collecting enough data.",
        },
    )
    write_report(report_path, samples, skipped, quality_errors, metrics)

    print(f"Saved model: {output_path}")
    print(f"Saved report: {report_path}")


def read_rows(metadata_path: Path) -> list[dict[str, str]]:
    if not metadata_path.exists():
        raise SystemExit(f"Missing prepared metadata: {metadata_path}")

    with metadata_path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def extract_samples(
    dataset_dir: Path,
    rows: list[dict[str, str]],
    analyzer: SkinVisionAnalyzer,
    concern_only: bool = False,
) -> tuple[list[dict[str, object]], list[str]]:
    samples = []
    skipped = []

    for index, row in enumerate(rows, start=2):
        image_path = dataset_dir / row.get("image_path", "")
        skin_type = row.get("skin_type", "").strip()
        concerns = normalize_labels(row.get("concerns", ""))

        if not skin_type and not concern_only:
            skipped.append(f"Row {index}: missing skin_type.")
            continue
        if not image_path.exists():
            skipped.append(f"Row {index}: missing image file {image_path}.")
            continue

        try:
            metrics = analyzer.extract_metrics(image_path.read_bytes())
        except (OSError, InvalidImageError) as exc:
            skipped.append(f"Row {index}: could not extract image metrics: {exc}")
            continue

        samples.append(
            {
                "features": metrics_to_vector(metrics),
                "skin_type": skin_type,
                "concerns": concerns,
                "acne_severity": normalize_acne_severity(row.get("acne_severity", ""), concerns),
                "split": row.get("split", "train").strip() or "train",
            }
        )

    return samples, skipped


def validate_training_quality(
    samples: list[dict[str, object]],
    concern_only: bool = False,
    skin_type_only: bool = False,
) -> list[str]:
    by_skin_type = count_by_label(samples, "skin_type")
    by_concern: dict[str, int] = defaultdict(int)

    for sample in samples:
        for concern in sample["concerns"]:
            by_concern[concern] += 1

    errors = []
    if not concern_only:
        expected_skin_types = {"normal", "oily", "dry", "combination", "sensitive"}
        missing_skin_types = sorted(expected_skin_types - set(by_skin_type))
        if missing_skin_types:
            errors.append(f"Missing skin types: {missing_skin_types}.")

        for label, count in sorted(by_skin_type.items()):
            if count < MIN_IMAGES_PER_SKIN_TYPE:
                errors.append(f"Skin type '{label}' has {count} image(s); target at least {MIN_IMAGES_PER_SKIN_TYPE}.")

    if skin_type_only:
        return errors

    expected_concerns = {"acne"} if concern_only else {"acne", "dark_spots", "oiliness", "dryness", "redness"}
    missing_concerns = sorted(expected_concerns - set(by_concern))
    if missing_concerns:
        errors.append(f"Missing concern labels: {missing_concerns}.")

    for label, count in sorted(by_concern.items()):
        if count < MIN_IMAGES_PER_CONCERN:
            errors.append(f"Concern '{label}' has {count} image(s); target at least {MIN_IMAGES_PER_CONCERN}.")

    return errors


def train_model(samples: list[dict[str, object]]) -> TrainedSkinModel:
    skin_groups: dict[str, list[list[float]]] = defaultdict(list)
    concern_groups: dict[str, list[list[float]]] = defaultdict(list)
    acne_severity_groups: dict[str, list[list[float]]] = defaultdict(list)

    for sample in samples:
        features = sample["features"]
        if sample["skin_type"]:
            skin_groups[sample["skin_type"]].append(features)
        for concern in sample["concerns"]:
            concern_groups[concern].append(features)
        if sample["acne_severity"] in {"mild", "moderate", "severe"}:
            acne_severity_groups[sample["acne_severity"]].append(features)

    skin_profiles = [
        SkinTypeProfile(
            label=label,
            centroid=centroid(vectors),
            confidence_radius=max(mean_distance(vectors), 0.08),
        )
        for label, vectors in sorted(skin_groups.items())
    ]
    concern_profiles = [
        ConcernProfile(
            label=label,
            centroid=centroid(vectors),
            threshold=concern_threshold(label, vectors, samples),
            severity=default_severity(label),
        )
        for label, vectors in sorted(concern_groups.items())
    ]
    acne_severity_profiles = [
        AcneSeverityProfile(
            label=label,
            centroid=centroid(vectors),
            confidence_radius=max(mean_distance(vectors), 0.08),
        )
        for label, vectors in sorted(acne_severity_groups.items())
    ]

    return TrainedSkinModel(
        skin_types=skin_profiles,
        concerns=concern_profiles,
        treatment_packages=DEFAULT_TREATMENT_PACKAGES,
        acne_severities=acne_severity_profiles,
    )


def evaluate_model(model: TrainedSkinModel, samples: list[dict[str, object]]) -> dict[str, object]:
    if not samples:
        return {"skin_type_accuracy": None, "concern_label_recall": 0}

    skin_correct = 0
    skin_total = 0
    concern_hits = 0
    concern_total = 0
    concern_false_positives = 0
    no_concern_total = 0
    no_concern_false_positives = 0
    severity_correct = 0
    severity_total = 0

    for sample in samples:
        features = sample["features"]
        predicted_concerns_list = model._predict_concerns(features)
        predicted_concerns = {item.name for item in predicted_concerns_list}
        expected_concerns = set(sample["concerns"])

        if sample["skin_type"]:
            predicted_skin, _ = model._predict_skin_type(sample["features"])
            if predicted_skin == sample["skin_type"]:
                skin_correct += 1
            skin_total += 1
        concern_hits += len(predicted_concerns & expected_concerns)
        concern_total += len(expected_concerns)
        concern_false_positives += len(predicted_concerns - expected_concerns)
        if not expected_concerns:
            no_concern_total += 1
            if predicted_concerns:
                no_concern_false_positives += 1
        if sample["acne_severity"] in {"mild", "moderate", "severe"} and "acne" in predicted_concerns:
            predicted_severity = model._acne_severity(features, predicted_concerns_list)
            if predicted_severity == sample["acne_severity"]:
                severity_correct += 1
            severity_total += 1

    return {
        "skin_type_accuracy": round(skin_correct / skin_total, 3) if skin_total else None,
        "concern_label_recall": round(concern_hits / max(concern_total, 1), 3),
        "concern_label_precision": round(
            concern_hits / max(concern_hits + concern_false_positives, 1),
            3,
        ),
        "no_concern_false_positive_rate": round(
            no_concern_false_positives / max(no_concern_total, 1),
            3,
        ),
        "acne_severity_accuracy_when_acne_detected": round(severity_correct / severity_total, 3)
        if severity_total
        else None,
    }


def centroid(vectors: list[list[float]]) -> list[float]:
    return [round(mean(values), 6) for values in zip(*vectors, strict=True)]


def mean_distance(vectors: list[list[float]]) -> float:
    center = centroid(vectors)
    return mean([euclidean_distance(vector, center) for vector in vectors]) if vectors else 0.0


def concern_threshold(label: str, positive_vectors: list[list[float]], samples: list[dict[str, object]]) -> float:
    center = centroid(positive_vectors)
    scored_samples = [
        (
            euclidean_distance(sample["features"], center),
            label in sample["concerns"],
        )
        for sample in samples
    ]

    if not any(not is_positive for _, is_positive in scored_samples):
        positive_distances = [distance for distance, is_positive in scored_samples if is_positive]
        return round(max(mean_distance(positive_vectors) * 1.8, percentile(positive_distances, 0.9), 0.18), 6)

    best_threshold = 0.18
    best_score = -1.0
    best_recall = -1.0

    for threshold in sorted({max(distance, 0.05) for distance, _ in scored_samples}):
        true_positives = sum(1 for distance, is_positive in scored_samples if distance <= threshold and is_positive)
        false_positives = sum(1 for distance, is_positive in scored_samples if distance <= threshold and not is_positive)
        false_negatives = sum(1 for distance, is_positive in scored_samples if distance > threshold and is_positive)
        true_negatives = sum(1 for distance, is_positive in scored_samples if distance > threshold and not is_positive)

        precision = true_positives / max(true_positives + false_positives, 1)
        recall = true_positives / max(true_positives + false_negatives, 1)
        false_positive_rate = false_positives / max(false_positives + true_negatives, 1)
        f1 = (2 * precision * recall) / max(precision + recall, 0.001)
        score = f1 - (false_positive_rate * 0.45)

        if score > best_score or (score == best_score and recall > best_recall):
            best_threshold = threshold
            best_score = score
            best_recall = recall

    return round(best_threshold, 6)


def percentile(values: list[float], ratio: float) -> float:
    if not values:
        return 0.0

    ordered = sorted(values)
    index = round((len(ordered) - 1) * ratio)
    return ordered[index]


def count_by_label(samples: list[dict[str, object]], field: str) -> dict[str, int]:
    counts: dict[str, int] = defaultdict(int)
    for sample in samples:
        label = str(sample[field])
        if label:
            counts[label] += 1
    return dict(counts)


def normalize_labels(value: str) -> list[str]:
    labels = set()

    for item in value.replace(",", ";").split(";"):
        label = item.strip()
        if not label or label in NO_CONCERN_ALIASES:
            continue
        labels.add(label)

    return sorted(labels)


def normalize_acne_severity(value: str, concerns: list[str]) -> str:
    severity = value.strip().lower()
    if "acne" not in concerns:
        return "none"
    if severity in {"mild", "moderate", "severe"}:
        return severity
    return "moderate"


def default_severity(label: str) -> str:
    return "moderate" if label in {"acne", "dark_spots", "oiliness"} else "mild"


def write_report(
    path: Path,
    samples: list[dict[str, object]],
    skipped: list[str],
    quality_errors: list[str],
    metrics: dict[str, object],
) -> None:
    by_skin_type = count_by_label(samples, "skin_type")
    by_concern: dict[str, int] = defaultdict(int)
    by_acne_severity: dict[str, int] = defaultdict(int)

    for sample in samples:
        for concern in sample["concerns"]:
            by_concern[concern] += 1
        severity = str(sample.get("acne_severity", ""))
        if severity:
            by_acne_severity[severity] += 1

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "total_samples": len(samples),
                "by_skin_type": by_skin_type,
                "by_concern": dict(sorted(by_concern.items())),
                "by_acne_severity": dict(sorted(by_acne_severity.items())),
                "skipped": skipped,
                "quality_errors": quality_errors,
                "metrics": metrics,
            },
            handle,
            indent=2,
        )


if __name__ == "__main__":
    main()
