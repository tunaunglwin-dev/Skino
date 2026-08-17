import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import TYPE_CHECKING

from app.schemas import AnalysisResponse, Concern, TreatmentPackage

if TYPE_CHECKING:
    from app.vision import SkinMetrics


FEATURE_NAMES = [
    "brightness",
    "saturation",
    "red_ratio",
    "dark_ratio",
    "highlight_ratio",
    "texture_score",
    "skin_coverage",
]


@dataclass(frozen=True)
class ConcernProfile:
    label: str
    centroid: list[float]
    threshold: float
    severity: str


@dataclass(frozen=True)
class SkinTypeProfile:
    label: str
    centroid: list[float]
    confidence_radius: float


@dataclass(frozen=True)
class AcneSeverityProfile:
    label: str
    centroid: list[float]
    confidence_radius: float


class TrainedSkinModel:
    def __init__(
        self,
        skin_types: list[SkinTypeProfile],
        concerns: list[ConcernProfile],
        treatment_packages: dict[str, dict[str, object]],
        acne_severities: list[AcneSeverityProfile] | None = None,
    ) -> None:
        self.skin_types = skin_types
        self.concerns = concerns
        self.treatment_packages = treatment_packages
        self.acne_severities = acne_severities or []

    @classmethod
    def load(cls, path: str | Path | None) -> "TrainedSkinModel | None":
        if not path:
            return None

        model_path = Path(path)
        if not model_path.exists():
            return None

        with model_path.open("r", encoding="utf-8") as handle:
            payload = json.load(handle)

        return cls(
            skin_types=[
                SkinTypeProfile(**item)
                for item in payload.get("skin_type_profiles", [])
            ],
            concerns=[
                ConcernProfile(**item)
                for item in payload.get("concern_profiles", [])
            ],
            treatment_packages=payload.get("treatment_packages", {}),
            acne_severities=[
                AcneSeverityProfile(**item)
                for item in payload.get("acne_severity_profiles", [])
            ],
        )

    def save(self, path: str | Path, metadata: dict[str, object]) -> None:
        model_path = Path(path)
        model_path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "version": 1,
            "feature_names": FEATURE_NAMES,
            "metadata": metadata,
            "skin_type_profiles": [asdict(item) for item in self.skin_types],
            "concern_profiles": [asdict(item) for item in self.concerns],
            "acne_severity_profiles": [asdict(item) for item in self.acne_severities],
            "treatment_packages": self.treatment_packages,
        }

        with model_path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2)

    def predict(self, metrics: "SkinMetrics") -> AnalysisResponse:
        features = metrics_to_vector(metrics)
        skin_type, skin_confidence = self._predict_skin_type(features)
        concerns = self._predict_concerns(features)
        score = self._skin_health_score(metrics, concerns)

        return AnalysisResponse(
            skin_type=skin_type,
            skin_type_confidence=skin_confidence,
            concerns=concerns,
            acne_severity=self._acne_severity(features, concerns),
            skin_health_score=score,
            treatment_package=self._recommend_treatment_package(skin_type, concerns),
        )

    def _predict_skin_type(self, features: list[float]) -> tuple[str, float]:
        if not self.skin_types:
            return "unknown", 0.0

        distances = [
            (profile, euclidean_distance(features, profile.centroid))
            for profile in self.skin_types
        ]
        profile, distance = min(distances, key=lambda item: item[1])
        radius = max(profile.confidence_radius, 0.001)
        confidence = max(0.35, min(0.96, 1 - (distance / (radius * 2.5))))

        return profile.label, round(confidence, 2)

    def _predict_concerns(self, features: list[float]) -> list[Concern]:
        scored = []
        brightness = features[0]
        skin_coverage = features[6]
        lighting_factor = 0.58 if brightness < 0.42 or skin_coverage < 0.12 else 1.0

        for profile in self.concerns:
            distance = euclidean_distance(features, profile.centroid)
            if distance > profile.threshold:
                continue

            confidence = max(0.35, min(0.95, 1 - (distance / max(profile.threshold, 0.001)))) * lighting_factor
            scored.append(
                Concern(
                    name=profile.label,
                    confidence=round(confidence, 2),
                    severity=profile.severity,
                )
            )

        return sorted(scored, key=lambda concern: concern.confidence, reverse=True)[:4]

    def _skin_health_score(self, metrics: "SkinMetrics", concerns: list[Concern]) -> int:
        concern_penalty = sum(concern.confidence for concern in concerns) * 10
        coverage_penalty = 10 if metrics.skin_coverage < 0.12 else 0
        centering_penalty = 7 if metrics.face_centering < 0.42 else 0
        evenness_penalty = 5 if metrics.lighting_evenness < 0.45 else 0
        balance_penalty = abs(metrics.brightness - 0.62) * 12
        score = 92 - concern_penalty - coverage_penalty - centering_penalty - evenness_penalty - balance_penalty

        return int(max(35, min(round(score), 96)))

    def _acne_severity(self, features: list[float], concerns: list[Concern]) -> str:
        acne = next((concern for concern in concerns if concern.name == "acne"), None)
        if acne is None:
            return "none"
        if not self.acne_severities:
            return acne.severity

        profile, _ = min(
            (
                (profile, euclidean_distance(features, profile.centroid))
                for profile in self.acne_severities
            ),
            key=lambda item: item[1],
        )

        return profile.label

    def _recommend_treatment_package(
        self,
        skin_type: str,
        concerns: list[Concern],
    ) -> TreatmentPackage | None:
        key = concerns[0].name if concerns else skin_type
        package = self.treatment_packages.get(key) or self.treatment_packages.get(skin_type)

        if not package:
            return None

        reason = (
            f"Matched to {label(key)} from the latest scan."
            if concerns
            else f"Matched to {label(skin_type)} skin maintenance."
        )

        return TreatmentPackage(
            key=key,
            name=str(package["name"]),
            steps=[str(step) for step in package["steps"]],
            follow_up_days=int(package["follow_up_days"]),
            reason=reason,
        )


def metrics_to_vector(metrics: "SkinMetrics") -> list[float]:
    return [
        metrics.brightness,
        metrics.saturation,
        metrics.red_ratio,
        metrics.dark_ratio,
        metrics.highlight_ratio,
        metrics.texture_score,
        metrics.skin_coverage,
    ]


def euclidean_distance(left: list[float], right: list[float]) -> float:
    return sum((a - b) ** 2 for a, b in zip(left, right, strict=True)) ** 0.5


def label(value: str) -> str:
    return value.replace("_", " ")
