import argparse
import csv
import json
import sys
from dataclasses import asdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.calibration import HeuristicCalibration
from app.vision import SkinVisionAnalyzer


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate heuristic predictions and write a calibration report.")
    parser.add_argument("--dataset-dir", required=True, help="Prepared dataset directory.")
    parser.add_argument("--metadata", default="metadata_prepared.csv", help="Prepared metadata CSV.")
    parser.add_argument("--output", default="../models/heuristic_calibration_report.json", help="Report JSON path.")
    parser.add_argument("--calibration-output", default="../models/heuristic_calibration.json", help="Calibration JSON path.")
    args = parser.parse_args()

    dataset_dir = Path(args.dataset_dir).resolve()
    metadata_path = dataset_dir / args.metadata
    rows = read_rows(metadata_path)

    analyzer = SkinVisionAnalyzer()
    evaluations = []

    for row in rows:
        image_path = dataset_dir / row["image_path"]
        with image_path.open("rb") as handle:
            image_bytes = handle.read()

        metrics = analyzer.extract_metrics(image_bytes)
        prediction = analyzer.predict(metrics)
        expected_concerns = set(split_concerns(row["concerns"]))
        predicted_concerns = {concern.name for concern in prediction.concerns}

        evaluations.append(
            {
                "image_path": row["image_path"],
                "expected_skin_type": row["skin_type"],
                "predicted_skin_type": prediction.skin_type,
                "skin_type_match": prediction.skin_type == row["skin_type"],
                "expected_concerns": sorted(expected_concerns),
                "predicted_concerns": sorted(predicted_concerns),
                "concern_precision": precision(predicted_concerns, expected_concerns),
                "concern_recall": recall(predicted_concerns, expected_concerns),
                "metrics": asdict(metrics),
                "response": prediction.model_dump(),
            }
        )

    report = build_report(evaluations)
    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    calibration = suggest_calibration(evaluations)
    calibration.dump(Path(args.calibration_output).resolve())

    print(f"Evaluated {len(evaluations)} prepared image(s).")
    print(f"Skin type accuracy: {report['skin_type_accuracy']}")
    print(f"Concern precision: {report['concern_precision']}")
    print(f"Concern recall: {report['concern_recall']}")
    print(f"Wrote report to {output_path}")
    print(f"Wrote calibration to {Path(args.calibration_output).resolve()}")


def read_rows(metadata_path: Path) -> list[dict[str, str]]:
    with metadata_path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def split_concerns(value: str) -> list[str]:
    return [item.strip() for item in value.replace(",", ";").split(";") if item.strip()]


def precision(predicted: set[str], expected: set[str]) -> float:
    if not predicted:
        return 1.0 if not expected else 0.0

    return len(predicted & expected) / len(predicted)


def recall(predicted: set[str], expected: set[str]) -> float:
    if not expected:
        return 1.0 if not predicted else 0.0

    return len(predicted & expected) / len(expected)


def average(values: list[float]) -> float:
    if not values:
        return 0.0

    return round(sum(values) / len(values), 3)


def build_report(evaluations: list[dict]) -> dict:
    skin_type_accuracy = average([1.0 if item["skin_type_match"] else 0.0 for item in evaluations])

    return {
        "total_images": len(evaluations),
        "skin_type_accuracy": skin_type_accuracy,
        "concern_precision": average([item["concern_precision"] for item in evaluations]),
        "concern_recall": average([item["concern_recall"] for item in evaluations]),
        "evaluations": evaluations,
    }


def suggest_calibration(evaluations: list[dict]) -> HeuristicCalibration:
    red_values = [
        item["metrics"]["red_ratio"]
        for item in evaluations
        if {"acne", "redness"} & set(item["expected_concerns"])
    ]
    dark_values = [
        item["metrics"]["dark_ratio"]
        for item in evaluations
        if "dark_spots" in set(item["expected_concerns"])
    ]
    highlight_values = [
        item["metrics"]["highlight_ratio"]
        for item in evaluations
        if "oiliness" in set(item["expected_concerns"])
    ]

    calibration = HeuristicCalibration()

    if red_values:
        red_weight = min(max(0.55 / max(average(red_values), 0.01), 3.0), 9.0)
        calibration = HeuristicCalibration(
            acne_red_weight=red_weight,
            redness_red_weight=max(red_weight - 1.0, 2.5),
            dark_spots_weight=calibration.dark_spots_weight,
            oiliness_highlight_weight=calibration.oiliness_highlight_weight,
        )

    if dark_values or highlight_values:
        calibration = HeuristicCalibration(
            acne_red_weight=calibration.acne_red_weight,
            redness_red_weight=calibration.redness_red_weight,
            dark_spots_weight=min(max(0.55 / max(average(dark_values), 0.01), 3.0), 9.0) if dark_values else calibration.dark_spots_weight,
            oiliness_highlight_weight=min(max(0.55 / max(average(highlight_values), 0.01), 3.0), 10.0)
            if highlight_values
            else calibration.oiliness_highlight_weight,
        )

    return calibration


if __name__ == "__main__":
    main()
