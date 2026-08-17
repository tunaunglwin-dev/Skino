import argparse
import csv
import json
import shutil
from collections import Counter, defaultdict
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Import ACNE04-v2 annotations into Skino raw dataset format.")
    parser.add_argument("--annotations", required=True, help="Path to Acne04-v2_annotations.json.")
    parser.add_argument("--images-dir", required=True, help="Directory containing original ACNE04 image files.")
    parser.add_argument("--output-dir", required=True, help="Skino raw dataset output directory.")
    parser.add_argument("--source", default="acne04v2", help="Source name stored in metadata.")
    parser.add_argument("--license", default="citation_required", help="License/usage note stored in metadata.")
    parser.add_argument("--consent", default="research_dataset", help="Consent note stored in metadata.")
    parser.add_argument(
        "--weak-skin-type-labels",
        action="store_true",
        help="Assign weak skin_type labels from severity. Use only for experiments, not final training.",
    )
    args = parser.parse_args()

    annotations_path = Path(args.annotations).resolve()
    images_dir = Path(args.images_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    imported_dir = output_dir / "acne04v2"
    imported_dir.mkdir(parents=True, exist_ok=True)

    payload = json.loads(annotations_path.read_text(encoding="utf-8"))
    annotations_by_image = group_annotations(payload["annotations"])
    rows = []
    missing = []
    copied = 0

    for image in payload["images"]:
        file_name = image["file_name"]
        source_path = images_dir / file_name
        severity = severity_from_filename(file_name)
        lesion_count = len(annotations_by_image[image["id"]])

        if not source_path.exists():
            missing.append(file_name)
            continue

        target_name = f"acne04v2_{file_name}"
        target_path = imported_dir / target_name
        shutil.copy2(source_path, target_path)
        copied += 1

        rows.append(
            {
                "image_path": str(Path("acne04v2") / target_name).replace("\\", "/"),
                "split": split_for_index(copied),
                "skin_type": weak_skin_type(severity) if args.weak_skin_type_labels else "",
                "concerns": concerns_for_severity(severity),
                "source": args.source,
                "license": args.license,
                "consent": args.consent,
                "acne_severity": severity,
                "lesion_count": str(lesion_count),
            }
        )

    metadata_path = output_dir / "metadata_acne04v2.csv"
    report_path = output_dir / "import_acne04v2_report.json"
    write_metadata(metadata_path, rows)
    write_report(report_path, rows, missing, len(payload["images"]))

    print(f"Copied {copied} image(s).")
    print(f"Missing {len(missing)} image(s).")
    print(f"Wrote metadata: {metadata_path}")
    print(f"Wrote report: {report_path}")


def group_annotations(annotations: list[dict[str, object]]) -> dict[int, list[dict[str, object]]]:
    grouped: dict[int, list[dict[str, object]]] = defaultdict(list)
    for annotation in annotations:
        grouped[int(annotation["image_id"])].append(annotation)
    return grouped


def severity_from_filename(file_name: str) -> str:
    prefix = file_name.split("_", maxsplit=1)[0].replace("levle", "level")
    return {
        "level0": "clear_or_very_mild",
        "level1": "mild",
        "level2": "moderate",
        "level3": "severe",
    }.get(prefix, "unknown")


def concerns_for_severity(severity: str) -> str:
    if severity == "clear_or_very_mild":
        return ""
    if severity == "mild":
        return "acne"
    if severity in {"moderate", "severe"}:
        return "acne;redness"
    return "acne"


def weak_skin_type(severity: str) -> str:
    if severity == "clear_or_very_mild":
        return "normal"
    return "sensitive"


def split_for_index(index: int) -> str:
    bucket = index % 10
    if bucket == 0:
        return "test"
    if bucket in {1, 2}:
        return "validation"
    return "train"


def write_metadata(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "image_path",
        "split",
        "skin_type",
        "concerns",
        "source",
        "license",
        "consent",
        "acne_severity",
        "lesion_count",
    ]

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_report(path: Path, rows: list[dict[str, str]], missing: list[str], total_images: int) -> None:
    severity_counts = Counter(row["acne_severity"] for row in rows)
    split_counts = Counter(row["split"] for row in rows)
    concern_counts: Counter[str] = Counter()

    for row in rows:
        for concern in row["concerns"].split(";"):
            if concern:
                concern_counts[concern] += 1

    path.write_text(
        json.dumps(
            {
                "total_annotation_images": total_images,
                "copied_images": len(rows),
                "missing_images": len(missing),
                "severity_counts": dict(sorted(severity_counts.items())),
                "split_counts": dict(sorted(split_counts.items())),
                "concern_counts": dict(sorted(concern_counts.items())),
                "missing_preview": missing[:50],
                "notes": [
                    "This dataset is useful for acne concern training only.",
                    "It does not provide reliable labels for oily, dry, combination, sensitive, or normal skin type.",
                    "Do not train on README example images with drawn annotation circles.",
                ],
            },
            indent=2,
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
