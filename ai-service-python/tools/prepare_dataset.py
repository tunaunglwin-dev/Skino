import argparse
import csv
import hashlib
import json
from pathlib import Path

from PIL import Image, UnidentifiedImageError


VALID_SKIN_TYPES = {"oily", "dry", "combination", "normal", "sensitive"}
VALID_CONCERNS = {"acne", "redness", "dark_spots", "texture", "oiliness", "dryness"}
NO_CONCERN_ALIASES = {"clear", "healthy", "none", "no_concern", "no_concerns", "normal"}
VALID_SPLITS = {"train", "validation", "test", "calibration"}
OPTIONAL_METADATA_FIELDS = ["acne_severity", "original_labels"]


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate metadata and normalize images into a prepared dataset.")
    parser.add_argument("--raw-dir", required=True, help="Directory containing raw images and metadata.csv.")
    parser.add_argument("--metadata", default="metadata.csv", help="Metadata CSV file name or path.")
    parser.add_argument("--output-dir", required=True, help="Prepared dataset output directory.")
    parser.add_argument("--size", type=int, default=512, help="Maximum width/height for prepared images.")
    args = parser.parse_args()

    raw_dir = Path(args.raw_dir).resolve()
    metadata_path = Path(args.metadata)
    if not metadata_path.is_absolute():
        metadata_path = raw_dir / metadata_path

    output_dir = Path(args.output_dir).resolve()
    images_dir = output_dir / "images"
    images_dir.mkdir(parents=True, exist_ok=True)

    rows = []
    errors = []

    with metadata_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)

        for index, row in enumerate(reader, start=2):
            prepared, row_errors = prepare_row(row, index, raw_dir, images_dir, args.size)
            errors.extend(row_errors)

            if prepared:
                rows.append(prepared)

    write_metadata(output_dir / "metadata_prepared.csv", rows)
    write_summary(output_dir / "summary.json", rows, errors)

    if errors:
        print(f"Prepared {len(rows)} images with {len(errors)} warning/error(s). See summary.json.")
    else:
        print(f"Prepared {len(rows)} images successfully.")


def prepare_row(
    row: dict[str, str],
    index: int,
    raw_dir: Path,
    images_dir: Path,
    size: int,
) -> tuple[dict[str, str] | None, list[str]]:
    errors = []
    image_path = row.get("image_path", "").strip()
    split = row.get("split", "").strip() or "train"
    skin_type = row.get("skin_type", "").strip()
    concerns = normalize_concerns(row.get("concerns", ""))

    if not image_path:
        return None, [f"Row {index}: missing image_path."]

    if split not in VALID_SPLITS:
        errors.append(f"Row {index}: split '{split}' is not one of {sorted(VALID_SPLITS)}.")

    if skin_type and skin_type not in VALID_SKIN_TYPES:
        errors.append(f"Row {index}: skin_type '{skin_type}' is not one of {sorted(VALID_SKIN_TYPES)}.")

    invalid_concerns = sorted(set(concerns) - VALID_CONCERNS)
    if invalid_concerns:
        errors.append(f"Row {index}: invalid concerns {invalid_concerns}.")

    source_path = raw_dir / image_path
    if not source_path.exists():
        return None, errors + [f"Row {index}: image file does not exist: {source_path}."]

    try:
        with Image.open(source_path) as image:
            image = image.convert("RGB")
            image.thumbnail((size, size))
            digest = file_digest(source_path)[:12]
            output_name = f"{source_path.stem}-{digest}.jpg"
            output_path = images_dir / output_name
            image.save(output_path, format="JPEG", quality=92, optimize=True)
    except (OSError, UnidentifiedImageError) as exc:
        return None, errors + [f"Row {index}: unreadable image {source_path}: {exc}."]

    prepared = {
        "image_path": str(Path("images") / output_name).replace("\\", "/"),
        "split": split,
        "skin_type": skin_type,
        "concerns": ";".join(concerns),
        "source": row.get("source", "").strip(),
        "license": row.get("license", "").strip(),
        "consent": row.get("consent", "").strip(),
    }
    for field in OPTIONAL_METADATA_FIELDS:
        if field in row:
            prepared[field] = row.get(field, "").strip()

    return prepared, errors


def normalize_concerns(value: str) -> list[str]:
    concerns = set()

    for item in value.replace(",", ";").split(";"):
        concern = item.strip()
        if not concern or concern in NO_CONCERN_ALIASES:
            continue
        concerns.add(concern)

    return sorted(concerns)


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()

    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)

    return digest.hexdigest()


def write_metadata(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["image_path", "split", "skin_type", "concerns", "source", "license", "consent"]
    fieldnames.extend(field for field in OPTIONAL_METADATA_FIELDS if any(field in row for row in rows))

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=fieldnames,
        )
        writer.writeheader()
        writer.writerows(rows)


def write_summary(path: Path, rows: list[dict[str, str]], errors: list[str]) -> None:
    by_split: dict[str, int] = {}
    by_skin_type: dict[str, int] = {}
    by_concern: dict[str, int] = {}

    for row in rows:
        by_split[row["split"]] = by_split.get(row["split"], 0) + 1
        if row["skin_type"]:
            by_skin_type[row["skin_type"]] = by_skin_type.get(row["skin_type"], 0) + 1
        for concern in normalize_concerns(row["concerns"]):
            by_concern[concern] = by_concern.get(concern, 0) + 1

    with path.open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "total_images": len(rows),
                "by_split": by_split,
                "by_skin_type": by_skin_type,
                "by_concern": by_concern,
                "errors": errors,
            },
            handle,
            indent=2,
        )


if __name__ == "__main__":
    main()
