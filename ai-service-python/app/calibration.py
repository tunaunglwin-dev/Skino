import json
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass(frozen=True)
class HeuristicCalibration:
    red_dominance_threshold: float = 70.0
    red_min_value: float = 95.0
    dark_brightness_threshold: float = 0.38
    dark_saturation_threshold: float = 0.18
    highlight_brightness_threshold: float = 0.86
    highlight_saturation_threshold: float = 0.35
    texture_multiplier: float = 3.2
    concern_min_confidence: float = 0.28
    oily_highlight_weight: float = 3.2
    acne_red_weight: float = 6.0
    redness_red_weight: float = 5.0
    dark_spots_weight: float = 5.0
    oiliness_highlight_weight: float = 7.0
    stable_concern_floor: float = 0.24

    @classmethod
    def load(cls, path: str | Path | None) -> "HeuristicCalibration":
        if path is None:
            return cls()

        calibration_path = Path(path)

        if not calibration_path.exists():
            return cls()

        with calibration_path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)

        allowed_keys = set(cls.__dataclass_fields__.keys())
        return cls(**{key: value for key, value in data.items() if key in allowed_keys})

    def dump(self, path: str | Path) -> None:
        output_path = Path(path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with output_path.open("w", encoding="utf-8") as handle:
            json.dump(asdict(self), handle, indent=2)
