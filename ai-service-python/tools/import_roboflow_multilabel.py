import argparse
import csv
import json
import shutil
from collections import Counter
from pathlib import Path


ACNE_CLASS_COLUMNS = {
    "blackheads",
    "nodules",
    "papules",
    "pustules",
    "whiteheads",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Import a Roboflow multi-label classification export into Skino format.")
    parser.add_argument("--dataset-dir", required=True, help="Roboflow dataset directory containing train/valid/test folders.")
    parser.add_argument("--output-dir", required=True, help="Skino raw dataset output directory.")
    parser.add_argument("--source", default="roboflow_acne", help="Source name stored in metadata.")
    parser.add_argument("--license", default="undefined", help="License/usage note stored in metadata.")
    parser.add_argument("--consent", default="research_dataset", help="Consent note stored in metadata.")
    args = parser.parse_args()

    dataset_dir = Path(args.dataset_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    image_output_dir = output_dir / args.source
    image_output_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    missing = []

    for split_dir_name, split in [("train", "train"), ("valid", "validation"), ("test", "test")]:
        classes_path = dataset_dir / split_dir_name / "_classes.csv"
        if not classes_path.exists():
            continue

        with classes_path.open("r", newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                file_name = row["filename"].strip()
                source_path = dataset_dir / split_dir_name / file_name
                if not source_path.exists():
                    missing.append(str(source_path))
                    continue

                target_name = f"{split_dir_name}_{file_name}"
                target_path = image_output_dir / target_name
                shutil.copy2(source_path, target_path)

                rows.append(
                    {
                        "image_path": str(Path(args.source) / target_name).replace("\\", "/"),
                        "split": split,
                        "skin_type": "",
                        "concerns": concerns_from_row(row),
                        "source": args.source,
                        "license": args.license,
                        "consent": args.consent,
                        "original_labels": original_labels(row),
                    }
                )

    metadata_path = output_dir / f"metadata_{args.source}.csv"
    report_path = output_dir / f"import_{args.source}_report.json"
    write_metadata(metadata_path, rows)
    write_report(report_path, rows, missing)

    print(f"Imported {len(rows)} image(s).")
    print(f"Missing {len(missing)} image(s).")
    print(f"Wrote metadata: {metadata_path}")
    print(f"Wrote report: {report_path}")


def concerns_from_row(row: dict[str, str]) -> str:
    active_labels = set(original_labels(row).split(";")) if original_labels(row) else set()
    concerns = set()

    if active_labels & ACNE_CLASS_COLUMNS:
        concerns.add("acne")
    if "dark spot" in active_labels:
        concerns.add("dark_spots")

    return ";".join(sorted(concerns))


def original_labels(row: dict[str, str]) -> str:
    labels = []
    for key, value in row.items():
        if key == "filename":
            continue
        if value.strip() == "1":
            labels.append(key.strip())
    return ";".join(sorted(labels))


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
                "source",
                "license",
                "consent",
                "original_labels",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def write_report(path: Path, rows: list[dict[str, str]], missing: list[str]) -> None:
    split_counts = Counter(row["split"] for row in rows)
    concern_counts: Counter[str] = Counter()
    original_label_counts: Counter[str] = Counter()

    for row in rows:
        for concern in row["concerns"].split(";"):
            if concern:
                concern_counts[concern] += 1
        for label in row["original_labels"].split(";"):
            if label:
                original_label_counts[label] += 1

    path.write_text(
        json.dumps(
            {
                "total_images": len(rows),
                "split_counts": dict(sorted(split_counts.items())),
                "concern_counts": dict(sorted(concern_counts.items())),
                "original_label_counts": dict(sorted(original_label_counts.items())),
                "missing_count": len(missing),
                "missing_preview": missing[:30],
                "notes": [
                    "Roboflow license is undefined in README; use for local research/hackathon unless permission is clarified.",
                    "skin_type is left blank because this dataset does not provide reliable skin type labels.",
                    "dark spot is mapped to Skino dark_spots concern.",
                    "blackheads, nodules, papules, pustules, and whiteheads are mapped to Skino acne concern.",
                ],
            },
            indent=2,
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
