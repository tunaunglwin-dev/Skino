import argparse
import csv
import json
import shutil
from collections import Counter
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge prepared Skino datasets into one prepared dataset directory.")
    parser.add_argument("--input", action="append", required=True, help="Prepared dataset directory. Repeat for each input.")
    parser.add_argument("--output-dir", required=True, help="Merged prepared dataset output directory.")
    args = parser.parse_args()

    input_dirs = [Path(item).resolve() for item in args.input]
    output_dir = Path(args.output_dir).resolve()
    images_dir = output_dir / "images"
    images_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    errors = []

    for input_dir in input_dirs:
        metadata_path = input_dir / "metadata_prepared.csv"
        if not metadata_path.exists():
            errors.append(f"Missing prepared metadata: {metadata_path}")
            continue

        source_prefix = input_dir.parent.name or input_dir.name
        with metadata_path.open("r", newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for index, row in enumerate(reader, start=2):
                image_path = input_dir / row.get("image_path", "")
                if not image_path.exists():
                    errors.append(f"{metadata_path} row {index}: missing image {image_path}")
                    continue

                target_name = f"{source_prefix}_{image_path.name}"
                target_path = images_dir / target_name
                shutil.copy2(image_path, target_path)

                merged = dict(row)
                merged["image_path"] = str(Path("images") / target_name).replace("\\", "/")
                rows.append(merged)

    write_metadata(output_dir / "metadata_prepared.csv", rows)
    write_summary(output_dir / "summary.json", rows, errors)

    print(f"Merged {len(rows)} image(s) into {output_dir}.")
    if errors:
        print(f"Finished with {len(errors)} warning/error(s). See summary.json.")


def write_metadata(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["image_path", "split", "skin_type", "concerns", "source", "license", "consent"]
    for field in ["acne_severity", "original_labels"]:
        if any(field in row for row in rows):
            fieldnames.append(field)

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=fieldnames,
            extrasaction="ignore",
        )
        writer.writeheader()
        writer.writerows(rows)


def write_summary(path: Path, rows: list[dict[str, str]], errors: list[str]) -> None:
    by_split = Counter(row["split"] for row in rows)
    by_skin_type = Counter(row["skin_type"] for row in rows if row["skin_type"])
    by_concern: Counter[str] = Counter()

    for row in rows:
        for concern in row["concerns"].replace(",", ";").split(";"):
            concern = concern.strip()
            if concern:
                by_concern[concern] += 1

    with path.open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "total_images": len(rows),
                "by_split": dict(sorted(by_split.items())),
                "by_skin_type": dict(sorted(by_skin_type.items())),
                "by_concern": dict(sorted(by_concern.items())),
                "errors": errors,
            },
            handle,
            indent=2,
        )


if __name__ == "__main__":
    main()
