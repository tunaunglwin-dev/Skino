import argparse
import csv
import json
from collections import Counter
from pathlib import Path


SPLIT_MAP = {
    "train": "train",
    "valid": "validation",
    "validation": "validation",
    "test": "test",
}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
NORMAL_LABELS = {"normal", "normal skin", "healthy", "healthy skin", "clear", "clear skin"}


def main() -> None:
    parser = argparse.ArgumentParser(description="Import a folder classification dataset into Skino metadata format.")
    parser.add_argument("--dataset-dir", required=True, help="Dataset directory containing train/valid/test class folders.")
    parser.add_argument("--metadata", default="metadata.csv", help="Output metadata CSV path.")
    parser.add_argument("--report", default="import_folder_classification_report.json", help="Output report JSON path.")
    parser.add_argument("--source", required=True, help="Source name stored in metadata.")
    parser.add_argument("--license", default="undefined", help="License/usage note stored in metadata.")
    parser.add_argument("--consent", default="research_dataset", help="Consent note stored in metadata.")
    args = parser.parse_args()

    dataset_dir = Path(args.dataset_dir).resolve()
    metadata_path = Path(args.metadata)
    if not metadata_path.is_absolute():
        metadata_path = dataset_dir / metadata_path
    report_path = Path(args.report)
    if not report_path.is_absolute():
        report_path = dataset_dir / report_path

    rows, skipped = import_rows(dataset_dir, args.source, args.license, args.consent)
    write_metadata(metadata_path, rows)
    write_report(report_path, rows, skipped)

    print(f"Imported {len(rows)} image(s).")
    print(f"Wrote metadata: {metadata_path}")
    print(f"Wrote report: {report_path}")


def import_rows(dataset_dir: Path, source: str, license_note: str, consent: str) -> tuple[list[dict[str, str]], list[str]]:
    rows = []
    skipped = []

    for split_dir in sorted(path for path in dataset_dir.iterdir() if path.is_dir()):
        split = SPLIT_MAP.get(split_dir.name.lower())
        if not split:
            skipped.append(f"Skipped split folder with unsupported name: {split_dir}")
            continue

        for class_dir in sorted(path for path in split_dir.iterdir() if path.is_dir()):
            label = class_dir.name.strip().lower()
            skin_type, concerns = skino_labels(label)
            if not skin_type and not concerns:
                skipped.append(f"Skipped unsupported class folder: {class_dir}")
                continue

            for image_path in sorted(path for path in class_dir.iterdir() if path.is_file()):
                if image_path.suffix.lower() not in IMAGE_EXTENSIONS:
                    skipped.append(f"Skipped non-image file: {image_path}")
                    continue

                rows.append(
                    {
                        "image_path": str(image_path.relative_to(dataset_dir)).replace("\\", "/"),
                        "split": split,
                        "skin_type": skin_type,
                        "concerns": concerns,
                        "source": source,
                        "license": license_note,
                        "consent": consent,
                    }
                )

    return rows, skipped


def skino_labels(label: str) -> tuple[str, str]:
    if label in NORMAL_LABELS:
        return "normal", "healthy"

    return "", ""


def write_metadata(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["image_path", "split", "skin_type", "concerns", "source", "license", "consent"],
        )
        writer.writeheader()
        writer.writerows(rows)


def write_report(path: Path, rows: list[dict[str, str]], skipped: list[str]) -> None:
    split_counts = Counter(row["split"] for row in rows)
    skin_type_counts = Counter(row["skin_type"] for row in rows if row["skin_type"])
    concern_counts = Counter(row["concerns"] for row in rows if row["concerns"])

    with path.open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "total_images": len(rows),
                "by_split": dict(sorted(split_counts.items())),
                "by_skin_type": dict(sorted(skin_type_counts.items())),
                "by_concern_alias": dict(sorted(concern_counts.items())),
                "skipped": skipped,
            },
            handle,
            indent=2,
        )


if __name__ == "__main__":
    main()
