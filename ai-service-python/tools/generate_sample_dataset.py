import argparse
import csv
from pathlib import Path

from PIL import Image, ImageDraw


SAMPLES = [
    {
        "filename": "sensitive_redness.png",
        "skin_type": "sensitive",
        "concerns": "redness;acne",
        "base": (190, 132, 105),
        "spots": [((88, 104), 9, (178, 55, 58)), ((170, 130), 7, (178, 55, 58))],
    },
    {
        "filename": "oily_highlight.png",
        "skin_type": "oily",
        "concerns": "oiliness",
        "base": (204, 156, 130),
        "spots": [((145, 108), 24, (240, 222, 204)), ((202, 170), 18, (238, 221, 204))],
    },
    {
        "filename": "dark_spots.png",
        "skin_type": "normal",
        "concerns": "dark_spots",
        "base": (178, 126, 100),
        "spots": [((120, 210), 12, (92, 58, 45)), ((240, 92), 9, (92, 58, 45))],
    },
    {
        "filename": "normal_healthy.png",
        "skin_type": "normal",
        "concerns": "healthy",
        "base": (190, 138, 112),
        "spots": [],
    },
    {
        "filename": "dry_texture.png",
        "skin_type": "dry",
        "concerns": "dryness;texture",
        "base": (165, 118, 96),
        "spots": [],
        "texture": True,
    },
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate synthetic skin-like fixtures for pipeline checks.")
    parser.add_argument("--output", default="../../datasets/samples/raw", help="Output directory for sample images.")
    args = parser.parse_args()

    output_dir = Path(args.output).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata_path = output_dir / "metadata.csv"

    with metadata_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["image_path", "split", "skin_type", "concerns", "source", "license", "consent"],
        )
        writer.writeheader()

        for sample in SAMPLES:
            image = Image.new("RGB", (360, 360), sample["base"])
            draw = ImageDraw.Draw(image)

            for center, radius, color in sample["spots"]:
                x, y = center
                draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)

            if sample.get("texture"):
                for offset in range(20, 340, 14):
                    draw.line((20, offset, 340, offset + 26), fill=(120, 88, 75), width=1)

            image_path = output_dir / sample["filename"]
            image.save(image_path)

            writer.writerow(
                {
                    "image_path": sample["filename"],
                    "split": "calibration",
                    "skin_type": sample["skin_type"],
                    "concerns": sample["concerns"],
                    "source": "synthetic-fixture",
                    "license": "project-generated",
                    "consent": "not-human-subject",
                }
            )

    print(f"Wrote sample dataset to {output_dir}")
    print(f"Wrote metadata to {metadata_path}")


if __name__ == "__main__":
    main()
