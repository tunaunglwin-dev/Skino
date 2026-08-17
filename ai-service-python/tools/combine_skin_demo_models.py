import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Combine Skino demo skin-type and concern model JSON files.")
    parser.add_argument("--skin-model", required=True)
    parser.add_argument("--concern-model", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    skin_model_path = Path(args.skin_model)
    concern_model_path = Path(args.concern_model)
    output_path = Path(args.output)
    report_path = Path(args.report)

    skin_model = read_json(skin_model_path)
    concern_model = read_json(concern_model_path)

    combined = dict(concern_model)
    combined["metadata"] = {
        "source": "combined_demo_model",
        "skin_model": str(skin_model_path),
        "concern_model": str(concern_model_path),
        "warning": (
            "Demo nearest-centroid model. Skin typing is trained for normal/dry/oily/combination; "
            "sensitive/redness has very low sample count."
        ),
        "skin_metadata": skin_model.get("metadata", {}),
        "concern_metadata": concern_model.get("metadata", {}),
    }
    combined["skin_type_profiles"] = skin_model.get("skin_type_profiles", [])
    combined["concern_profiles"] = concern_model.get("concern_profiles", [])
    combined["acne_severity_profiles"] = concern_model.get("acne_severity_profiles", [])

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(combined, handle, indent=2)

    report = {
        "output": str(output_path),
        "skin_type_profiles": [item.get("label") for item in combined["skin_type_profiles"]],
        "concern_profiles": [item.get("label") for item in combined["concern_profiles"]],
        "acne_severity_profiles": [item.get("label") for item in combined["acne_severity_profiles"]],
        "warning": combined["metadata"]["warning"],
    }
    with report_path.open("w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    print(f"Wrote combined model: {output_path}")
    print(f"Wrote report: {report_path}")


def read_json(path: Path) -> dict[str, object]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


if __name__ == "__main__":
    main()
