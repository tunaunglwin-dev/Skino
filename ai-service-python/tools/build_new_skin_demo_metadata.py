import argparse
import csv
import json
from collections import Counter
from pathlib import Path


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
SKIN_TYPE_LABELS = {
    "normal": ("normal", ""),
    "dry": ("dry", "dryness"),
    "oily": ("oily", "oiliness"),
}
ACNE_SEVERITY_LABELS = {
    "IGA0": ("", "", "none"),
    "IGA1": ("", "acne", "mild"),
    "IGA2": ("", "acne", "mild"),
    "IGA3": ("", "acne", "moderate"),
    "IGA4": ("", "acne", "severe"),
}
SPLIT_MAP = {
    "train": "train",
    "valid": "validation",
    "validation": "validation",
    "test": "test",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Skino demo metadata from the new raw dataset bundle.")
    parser.add_argument("--raw-dir", required=True, help="datasets/new_skin_data/raw")
    args = parser.parse_args()

    raw_dir = Path(args.raw_dir).resolve()
    skin_rows = build_skin_type_rows(raw_dir)
    concern_rows = build_concern_rows(raw_dir)

    write_csv(raw_dir / "metadata_skin_types.csv", skin_rows)
    write_csv(raw_dir / "metadata_concerns.csv", concern_rows)
    write_report(raw_dir / "metadata_build_report.json", skin_rows, concern_rows)

    print(f"Wrote {len(skin_rows)} skin-type row(s).")
    print(f"Wrote {len(concern_rows)} concern row(s).")


def build_skin_type_rows(raw_dir: Path) -> list[dict[str, str]]:
    dataset_dir = raw_dir / "normal, dry, oil" / "Oily-Dry-Skin-Types"
    rows: list[dict[str, str]] = []

    for split_dir in sorted(path for path in dataset_dir.iterdir() if path.is_dir()):
        split = SPLIT_MAP.get(split_dir.name.lower())
        if not split:
            continue

        for class_dir in sorted(path for path in split_dir.iterdir() if path.is_dir()):
            label = class_dir.name.strip().lower()
            if label not in SKIN_TYPE_LABELS:
                continue

            skin_type, concern = SKIN_TYPE_LABELS[label]
            for image_path in image_files(class_dir):
                rows.append(
                    row(
                        raw_dir,
                        image_path,
                        split,
                        skin_type,
                        concern,
                        "oily_dry_normal_skin_types",
                        "dataset_license_unspecified",
                        "research_dataset",
                        "none",
                        label,
                    )
                )

    return rows


def build_concern_rows(raw_dir: Path) -> list[dict[str, str]]:
    rows = []
    rows.extend(build_skin_type_rows(raw_dir))
    rows.extend(build_acne_rows(raw_dir))
    rows.extend(build_redness_rows(raw_dir))
    return rows


def build_acne_rows(raw_dir: Path) -> list[dict[str, str]]:
    dataset_dir = raw_dir / "Acne Severity Classification"
    rows: list[dict[str, str]] = []

    for split_dir in sorted(path for path in dataset_dir.iterdir() if path.is_dir()):
        split = SPLIT_MAP.get(split_dir.name.lower())
        if not split:
            continue

        for class_dir in sorted(path for path in split_dir.iterdir() if path.is_dir()):
            label = class_dir.name.strip()
            if label not in ACNE_SEVERITY_LABELS:
                continue

            skin_type, concern, severity = ACNE_SEVERITY_LABELS[label]
            for image_path in image_files(class_dir):
                rows.append(
                    row(
                        raw_dir,
                        image_path,
                        split,
                        skin_type,
                        concern,
                        "roboflow_acne_severity_classification",
                        "CC BY 4.0",
                        "research_dataset",
                        severity,
                        label,
                    )
                )

    return rows


def build_redness_rows(raw_dir: Path) -> list[dict[str, str]]:
    dataset_dir = raw_dir / "skin tone diversity" / "files" / "redness"
    rows: list[dict[str, str]] = []

    if not dataset_dir.exists():
        return rows

    for image_path in image_files(dataset_dir):
        rows.append(
            row(
                raw_dir,
                image_path,
                "train",
                "sensitive",
                "redness",
                "skin_defects_redness_subset",
                "dataset_license_unspecified",
                "research_dataset",
                "none",
                "redness",
            )
        )

    return rows


def image_files(directory: Path) -> list[Path]:
    return sorted(
        path
        for path in directory.rglob("*")
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    )


def row(
    raw_dir: Path,
    image_path: Path,
    split: str,
    skin_type: str,
    concerns: str,
    source: str,
    license_note: str,
    consent: str,
    acne_severity: str,
    original_labels: str,
) -> dict[str, str]:
    return {
        "image_path": str(image_path.relative_to(raw_dir)).replace("\\", "/"),
        "split": split,
        "skin_type": skin_type,
        "concerns": concerns,
        "source": source,
        "license": license_note,
        "consent": consent,
        "acne_severity": acne_severity,
        "original_labels": original_labels,
    }


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    fieldnames = [
        "image_path",
        "split",
        "skin_type",
        "concerns",
        "source",
        "license",
        "consent",
        "acne_severity",
        "original_labels",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_report(path: Path, skin_rows: list[dict[str, str]], concern_rows: list[dict[str, str]]) -> None:
    payload = {
        "skin_type_metadata": summarize(skin_rows),
        "concern_metadata": summarize(concern_rows),
    }
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)


def summarize(rows: list[dict[str, str]]) -> dict[str, object]:
    by_split = Counter(row["split"] for row in rows)
    by_skin_type = Counter(row["skin_type"] for row in rows if row["skin_type"])
    by_concern = Counter()
    by_acne_severity = Counter(row["acne_severity"] for row in rows if row["acne_severity"])

    for item in rows:
        for concern in item["concerns"].split(";"):
            if concern:
                by_concern[concern] += 1

    return {
        "total_rows": len(rows),
        "by_split": dict(sorted(by_split.items())),
        "by_skin_type": dict(sorted(by_skin_type.items())),
        "by_concern": dict(sorted(by_concern.items())),
        "by_acne_severity": dict(sorted(by_acne_severity.items())),
    }


if __name__ == "__main__":
    main()
