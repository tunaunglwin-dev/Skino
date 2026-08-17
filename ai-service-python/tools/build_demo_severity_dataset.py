import argparse
import csv
import hashlib
import json
import shutil
from collections import defaultdict
from pathlib import Path


LABELS = ["normal", "mild", "moderate", "severe"]
OUTPUT_FIELDNAMES = [
    "image_path",
    "split",
    "skin_type",
    "concerns",
    "acne_severity",
    "source",
    "license",
    "consent",
    "original_source",
    "original_labels",
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Build a balanced draft acne severity dataset for hackathon demos.")
    parser.add_argument("--normal-dir", default="../datasets/normal_skin/prepared", help="Prepared normal-skin dataset.")
    parser.add_argument("--acne-dir", default="../datasets/skino_acne_care/prepared", help="Prepared Acne Care dataset.")
    parser.add_argument("--output-dir", default="../datasets/skino_demo_severity_auto/raw", help="Raw output dataset directory.")
    parser.add_argument("--per-class", type=int, default=100, help="Maximum images per class.")
    args = parser.parse_args()

    normal_dir = Path(args.normal_dir).resolve()
    acne_dir = Path(args.acne_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    images_dir = output_dir / "images"
    images_dir.mkdir(parents=True, exist_ok=True)

    rows_by_label = {
        "normal": select_rows(load_rows(normal_dir), normal_dir, "normal", args.per_class),
        "mild": select_rows(load_rows(acne_dir), acne_dir, "mild", args.per_class),
        "moderate": select_rows(load_rows(acne_dir), acne_dir, "moderate", args.per_class),
        "severe": select_rows(load_rows(acne_dir), acne_dir, "severe", args.per_class),
    }

    output_rows = []
    for label in LABELS:
        for row in rows_by_label[label]:
            output_rows.append(copy_row(row, label, images_dir))

    metadata_path = output_dir / "metadata.csv"
    report_path = output_dir / "build_demo_severity_report.json"
    write_metadata(metadata_path, output_rows)
    write_report(report_path, rows_by_label, output_rows)

    print(f"Wrote {len(output_rows)} image(s) to {output_dir}")
    print(f"Wrote metadata: {metadata_path}")
    print(f"Wrote report: {report_path}")


def load_rows(dataset_dir: Path) -> list[dict[str, str]]:
    metadata_path = dataset_dir / "metadata_prepared.csv"
    if not metadata_path.exists():
        raise SystemExit(f"Missing prepared metadata: {metadata_path}")

    rows = []
    with metadata_path.open("r", newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            image_path = dataset_dir / row.get("image_path", "")
            if image_path.exists():
                row["_dataset_dir"] = str(dataset_dir)
                row["_absolute_image_path"] = str(image_path)
                rows.append(row)

    return rows


def select_rows(rows: list[dict[str, str]], dataset_dir: Path, label: str, limit: int) -> list[dict[str, str]]:
    candidates = [row for row in rows if row_label(row) == label]
    candidates = [row for row in candidates if is_clean_candidate(row, label)]
    candidates = sorted(candidates, key=lambda row: stable_digest(f"{dataset_dir}:{row['image_path']}"))
    return candidates[:limit]


def row_label(row: dict[str, str]) -> str:
    severity = row.get("acne_severity", "").strip().lower()
    if severity in {"mild", "moderate", "severe"}:
        return severity

    skin_type = row.get("skin_type", "").strip().lower()
    concerns = {item.strip() for item in row.get("concerns", "").replace(",", ";").split(";") if item.strip()}
    if skin_type == "normal" and "acne" not in concerns:
        return "normal"

    return "skip"


def is_clean_candidate(row: dict[str, str], label: str) -> bool:
    original_labels = {item.strip() for item in row.get("original_labels", "").split(";") if item.strip()}
    if label == "normal":
        return True

    if "non acne" in original_labels:
        return False
    if label == "mild":
        return original_labels in [{"papule"}, {"pustule"}]
    if label == "moderate":
        return bool(original_labels & {"papule", "pustule", "nodule"})
    if label == "severe":
        return "nodule" in original_labels and len(original_labels & {"papule", "pustule", "nodule"}) >= 2

    return False


def copy_row(row: dict[str, str], label: str, images_dir: Path) -> dict[str, str]:
    source_path = Path(row["_absolute_image_path"])
    digest = stable_digest(f"{row['_dataset_dir']}:{row['image_path']}")[:12]
    output_name = f"{label}_{digest}{source_path.suffix.lower()}"
    output_path = images_dir / output_name
    if not output_path.exists():
        shutil.copy2(source_path, output_path)

    is_normal = label == "normal"
    return {
        "image_path": str(Path("images") / output_name).replace("\\", "/"),
        "split": normalize_split(row.get("split", "")),
        "skin_type": "normal" if is_normal else "",
        "concerns": "healthy" if is_normal else "acne",
        "acne_severity": "none" if is_normal else label,
        "source": "auto_demo_severity",
        "license": row.get("license", "").strip(),
        "consent": row.get("consent", "").strip(),
        "original_source": f"{row['_dataset_dir']}|{row['image_path']}",
        "original_labels": row.get("original_labels", "").strip(),
    }


def normalize_split(value: str) -> str:
    split = value.strip().lower()
    if split == "valid":
        return "validation"
    if split in {"train", "validation", "test", "calibration"}:
        return split
    return "train"


def write_metadata(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=OUTPUT_FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)


def write_report(path: Path, rows_by_label: dict[str, list[dict[str, str]]], output_rows: list[dict[str, str]]) -> None:
    split_counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for row in output_rows:
        split_counts[row["acne_severity" if row["acne_severity"] != "none" else "skin_type"]][row["split"]] += 1

    payload = {
        "total_images": len(output_rows),
        "counts": {label: len(rows_by_label[label]) for label in LABELS},
        "split_counts": {label: dict(sorted(counts.items())) for label, counts in sorted(split_counts.items())},
        "notes": [
            "This is an automatic draft dataset, not a replacement for manual review.",
            "Acne rows with contradictory 'non acne' labels are excluded.",
            "Use review_severity_dataset.py to build a higher-quality final dataset.",
        ],
    }
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def stable_digest(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


if __name__ == "__main__":
    main()
