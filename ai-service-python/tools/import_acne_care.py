import argparse
import csv
import json
import shutil
from collections import Counter
from pathlib import Path


ACNE_LABELS = {"nodule", "papule", "pustule"}
SPLITS = [("train", "train"), ("valid", "validation"), ("test", "test")]


def main() -> None:
    parser = argparse.ArgumentParser(description="Import the Acne Care Roboflow dataset into Skino raw format.")
    parser.add_argument("--dataset-dir", required=True, help="Roboflow Acne Care dataset with train/valid/test folders.")
    parser.add_argument("--output-dir", required=True, help="Skino raw dataset output directory.")
    parser.add_argument("--source", default="roboflow_acne_care", help="Source name stored in metadata.")
    parser.add_argument("--license", default="CC BY 4.0", help="License/usage note stored in metadata.")
    parser.add_argument("--consent", default="research_dataset", help="Consent note stored in metadata.")
    args = parser.parse_args()

    dataset_dir = Path(args.dataset_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    image_output_dir = output_dir / args.source
    image_output_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    missing = []
    skipped = []

    for split_dir_name, split in SPLITS:
        classes_path = dataset_dir / split_dir_name / "_classes.csv"
        if not classes_path.exists():
            skipped.append(f"Missing classes file: {classes_path}")
            continue

        with classes_path.open("r", newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for row_number, row in enumerate(reader, start=2):
                file_name = row["filename"].strip()
                source_path = dataset_dir / split_dir_name / file_name
                if not source_path.exists():
                    missing.append(str(source_path))
                    continue

                active_labels = labels_from_row(row)
                concerns, severity = skino_labels(active_labels)
                if not concerns and severity != "none":
                    skipped.append(f"{classes_path} row {row_number}: unsupported labels {sorted(active_labels)}")
                    continue

                target_name = f"{split_dir_name}_{file_name}"
                target_path = image_output_dir / target_name
                shutil.copy2(source_path, target_path)

                rows.append(
                    {
                        "image_path": str(Path(args.source) / target_name).replace("\\", "/"),
                        "split": split,
                        "skin_type": "normal" if severity == "none" else "",
                        "concerns": concerns,
                        "acne_severity": severity,
                        "source": args.source,
                        "license": args.license,
                        "consent": args.consent,
                        "original_labels": ";".join(sorted(active_labels)),
                    }
                )

    metadata_path = output_dir / f"metadata_{args.source}.csv"
    report_path = output_dir / f"import_{args.source}_report.json"
    write_metadata(metadata_path, rows)
    write_report(report_path, rows, missing, skipped)

    print(f"Imported {len(rows)} image(s).")
    print(f"Missing {len(missing)} image(s).")
    print(f"Skipped {len(skipped)} row(s).")
    print(f"Wrote metadata: {metadata_path}")
    print(f"Wrote report: {report_path}")


def labels_from_row(row: dict[str, str]) -> set[str]:
    labels = set()
    for key, value in row.items():
        if key == "filename":
            continue
        if value.strip() == "1":
            labels.add(key.strip().lower())
    return labels


def skino_labels(active_labels: set[str]) -> tuple[str, str]:
    acne_labels = active_labels & ACNE_LABELS
    if not acne_labels and "non acne" in active_labels:
        return "healthy", "none"
    if not acne_labels:
        return "", "unknown"

    score = 0
    if "papule" in acne_labels:
        score += 1
    if "pustule" in acne_labels:
        score += 1
    if "nodule" in acne_labels:
        score += 2

    if score >= 4 or ("nodule" in acne_labels and len(acne_labels) >= 2):
        return "acne", "severe"
    if score >= 2:
        return "acne", "moderate"
    return "acne", "mild"


def write_metadata(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "image_path",
                "split",
                "skin_type",
                "concerns",
                "acne_severity",
                "source",
                "license",
                "consent",
                "original_labels",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def write_report(path: Path, rows: list[dict[str, str]], missing: list[str], skipped: list[str]) -> None:
    split_counts = Counter(row["split"] for row in rows)
    concern_counts = Counter(row["concerns"] for row in rows if row["concerns"])
    severity_counts = Counter(row["acne_severity"] for row in rows if row["acne_severity"])
    original_label_counts: Counter[str] = Counter()
    contradictory_non_acne = 0

    for row in rows:
        original_labels = set(row["original_labels"].split(";")) if row["original_labels"] else set()
        original_label_counts.update(original_labels)
        if "non acne" in original_labels and original_labels & ACNE_LABELS:
            contradictory_non_acne += 1

    path.write_text(
        json.dumps(
            {
                "total_images": len(rows),
                "split_counts": dict(sorted(split_counts.items())),
                "concern_counts": dict(sorted(concern_counts.items())),
                "acne_severity_counts": dict(sorted(severity_counts.items())),
                "original_label_counts": dict(sorted(original_label_counts.items())),
                "contradictory_non_acne_with_acne_count": contradictory_non_acne,
                "missing_count": len(missing),
                "missing_preview": missing[:30],
                "skipped_count": len(skipped),
                "skipped_preview": skipped[:30],
                "notes": [
                    "Rows with acne labels plus non acne are treated as acne and counted as contradictory.",
                    "Severity is heuristic: papule/pustule are lighter signals, nodule is stronger.",
                    "Use this for hackathon baseline only; dermatologist-reviewed severity labels are needed for production.",
                ],
            },
            indent=2,
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
