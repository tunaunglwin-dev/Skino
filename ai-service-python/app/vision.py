from dataclasses import dataclass
from io import BytesIO
from statistics import mean

from PIL import Image, ImageFilter, ImageOps, UnidentifiedImageError

from app.calibration import HeuristicCalibration
from app.landmark_zones import landmark_zone_images
from app.schemas import AnalysisResponse, Concern, ScanQuality, SkinZone, TreatmentPackage
from app.trained_model import TrainedSkinModel
from app.treatment_packages import DEFAULT_TREATMENT_PACKAGES


class InvalidImageError(ValueError):
    pass


@dataclass(frozen=True)
class SkinMetrics:
    brightness: float
    saturation: float
    red_ratio: float
    dark_ratio: float
    highlight_ratio: float
    texture_score: float
    skin_coverage: float
    face_centering: float
    lighting_evenness: float


class SkinVisionAnalyzer:
    def __init__(
        self,
        calibration: HeuristicCalibration | None = None,
        trained_model: TrainedSkinModel | None = None,
    ) -> None:
        self.calibration = calibration or HeuristicCalibration()
        self.trained_model = trained_model

    def analyze(self, image_bytes: bytes, face_landmarks: list[dict[str, float]] | None = None) -> AnalysisResponse:
        metrics = self.extract_metrics(image_bytes)
        skin_zones = self.extract_skin_zones(image_bytes, face_landmarks)
        scan_quality = self._scan_quality(metrics)
        if self.trained_model:
            trained_result = self.trained_model.predict(metrics)
            if trained_result.skin_type != "unknown":
                return self._stabilize_result(
                    trained_result.model_copy(
                        update={
                            "skin_zones": skin_zones,
                            "scan_quality": scan_quality,
                        }
                    ),
                    metrics,
                )

            fallback_result = self.predict(metrics)
            return self._stabilize_result(
                AnalysisResponse(
                    skin_type=fallback_result.skin_type,
                    skin_type_confidence=fallback_result.skin_type_confidence,
                    concerns=trained_result.concerns or fallback_result.concerns,
                    skin_zones=skin_zones,
                    scan_quality=scan_quality,
                    acne_severity=trained_result.acne_severity,
                    skin_health_score=trained_result.skin_health_score,
                    treatment_package=self._recommend_treatment_package(
                        fallback_result.skin_type,
                        trained_result.concerns or fallback_result.concerns,
                    ),
                ),
                metrics,
            )

        return self._stabilize_result(
            self.predict(metrics).model_copy(
                update={
                    "skin_zones": skin_zones,
                    "scan_quality": scan_quality,
                }
            ),
            metrics,
        )

    def _stabilize_result(
        self,
        result: AnalysisResponse,
        metrics: SkinMetrics,
    ) -> AnalysisResponse:
        quality_factor = self._result_stability_factor(metrics)
        concerns = [
            concern.model_copy(
                update={
                    "confidence": round(
                        min(concern.confidence, concern.confidence * quality_factor),
                        2,
                    )
                }
            )
            for concern in result.concerns
        ]
        concerns = [
            concern
            for concern in concerns
            if concern.confidence >= self.calibration.stable_concern_floor
        ][:3]
        confidence = round(
            min(result.skin_type_confidence, result.skin_type_confidence * quality_factor),
            2,
        )
        score = self._stabilized_score(result.skin_health_score, metrics)

        return result.model_copy(
            update={
                "skin_type_confidence": confidence,
                "concerns": concerns,
                "acne_severity": self._acne_severity(concerns),
                "skin_health_score": score,
                "treatment_package": self._recommend_treatment_package(
                    result.skin_type,
                    concerns,
                ),
            }
        )

    def _stabilized_score(self, score: int, metrics: SkinMetrics) -> int:
        if metrics.skin_coverage < 0.12 or metrics.face_centering < 0.42:
            return min(score, 58)
        if metrics.brightness < 0.38 or metrics.brightness > 0.88:
            return min(score, 68)
        if metrics.lighting_evenness < 0.45:
            return min(score, 74)
        return score

    def _result_stability_factor(self, metrics: SkinMetrics) -> float:
        factor = 1.0
        if metrics.skin_coverage < 0.12:
            factor *= 0.62
        if metrics.face_centering < 0.42:
            factor *= 0.68
        if metrics.brightness < 0.38:
            factor *= 0.72
        elif metrics.brightness < 0.44:
            factor *= 0.84
        if metrics.brightness > 0.88:
            factor *= 0.72
        elif metrics.brightness > 0.82:
            factor *= 0.86
        if metrics.highlight_ratio > 0.62:
            factor *= 0.82
        if metrics.lighting_evenness < 0.45:
            factor *= 0.82

        return max(0.42, min(factor, 1.0))

    def extract_metrics(self, image_bytes: bytes) -> SkinMetrics:
        image = self._decode_image(image_bytes)
        image = self._resize_for_analysis(image)
        pixels, coverage, face_centering, lighting_evenness = self._skin_pixels(image)
        return self._extract_metrics(
            image,
            pixels,
            coverage,
            face_centering,
            lighting_evenness,
        )

    def extract_skin_zones(self, image_bytes: bytes, face_landmarks: list[dict[str, float]] | None = None) -> list[SkinZone]:
        image = self._decode_image(image_bytes)
        image = self._resize_for_analysis(image)
        width, height = image.size

        landmark_crops = landmark_zone_images(image, face_landmarks)
        if landmark_crops:
            return [self._zone_from_crop(key, label, crop) for key, label, crop in landmark_crops]

        zone_boxes = [
            ("forehead", "Forehead", (0.28, 0.12, 0.72, 0.33)),
            ("left_cheek", "Left cheek", (0.16, 0.36, 0.43, 0.66)),
            ("right_cheek", "Right cheek", (0.57, 0.36, 0.84, 0.66)),
            ("nose", "Nose", (0.40, 0.32, 0.60, 0.68)),
            ("chin", "Chin", (0.32, 0.68, 0.68, 0.88)),
        ]

        zones = []
        for key, label, box in zone_boxes:
            left, top, right, bottom = box
            crop = image.crop(
                (
                    int(width * left),
                    int(height * top),
                    int(width * right),
                    int(height * bottom),
                )
            )
            zones.append(self._zone_from_crop(key, label, crop))

        return zones

    def _zone_from_crop(self, key: str, label: str, crop: Image.Image) -> SkinZone:
        pixels, coverage, face_centering, lighting_evenness = self._skin_pixels(crop)
        metrics = self._extract_metrics(
            crop,
            pixels,
            coverage,
            face_centering,
            lighting_evenness,
        )
        return self._skin_zone(key, label, metrics)

    def predict(self, metrics: SkinMetrics) -> AnalysisResponse:
        skin_type, confidence = self._classify_skin_type(metrics)
        concerns = self._detect_concerns(metrics)
        score = self._skin_health_score(metrics, concerns)

        return AnalysisResponse(
            skin_type=skin_type,
            skin_type_confidence=confidence,
            concerns=concerns,
            skin_zones=[],
            scan_quality=self._scan_quality(metrics),
            acne_severity=self._acne_severity(concerns),
            skin_health_score=score,
            treatment_package=self._recommend_treatment_package(
                skin_type,
                concerns,
            ),
        )

    def _recommend_treatment_package(
        self,
        skin_type: str,
        concerns: list[Concern],
    ) -> TreatmentPackage | None:
        key = concerns[0].name if concerns else skin_type
        package = DEFAULT_TREATMENT_PACKAGES.get(key) or DEFAULT_TREATMENT_PACKAGES.get(skin_type)

        if not package:
            return None

        reason = (
            f"Matched to {_label(key)} from the latest scan."
            if concerns
            else f"Matched to {_label(skin_type)} skin maintenance."
        )

        return TreatmentPackage(
            key=key,
            name=str(package["name"]),
            steps=[str(step) for step in package["steps"]],
            follow_up_days=int(package["follow_up_days"]),
            reason=reason,
        )

    def _decode_image(self, image_bytes: bytes) -> Image.Image:
        if not image_bytes:
            raise InvalidImageError("Empty image upload.")

        try:
            image = Image.open(BytesIO(image_bytes))
            image.load()
        except (OSError, UnidentifiedImageError) as exc:
            raise InvalidImageError("Uploaded file is not a readable image.") from exc

        return ImageOps.exif_transpose(image).convert("RGB")

    def _resize_for_analysis(self, image: Image.Image) -> Image.Image:
        image.thumbnail((180, 180))
        return image

    def _skin_pixels(self, image: Image.Image) -> tuple[list[tuple[int, int, int]], float, float, float]:
        width, height = image.size
        crop_size = int(min(width, height) * 0.78)
        left = (width - crop_size) // 2
        top = (height - crop_size) // 2
        region = image.crop((left, top, left + crop_size, top + crop_size))
        pixels = self._rgb_pixels(region)

        skin_mask = [self._looks_like_skin(pixel) for pixel in pixels]
        skin_pixels = [
            pixel
            for pixel, is_skin in zip(pixels, skin_mask, strict=True)
            if is_skin
        ]
        coverage = len(skin_pixels) / max(len(pixels), 1)
        face_centering = self._face_centering_score(skin_mask, region.size)
        lighting_evenness = self._lighting_evenness(region, skin_mask)

        if coverage < 0.08:
            return pixels, coverage, face_centering, lighting_evenness

        return skin_pixels, coverage, face_centering, lighting_evenness

    def _face_centering_score(self, skin_mask: list[bool], size: tuple[int, int]) -> float:
        width, height = size
        if not skin_mask:
            return 0.0

        left_count = 0
        right_count = 0
        top_count = 0
        bottom_count = 0

        for index, is_skin in enumerate(skin_mask):
            if not is_skin:
                continue
            x = index % width
            y = index // width
            if x < width / 2:
                left_count += 1
            else:
                right_count += 1
            if y < height / 2:
                top_count += 1
            else:
                bottom_count += 1

        horizontal = self._balance_ratio(left_count, right_count)
        vertical = self._balance_ratio(top_count, bottom_count)

        return round(min(horizontal, vertical), 2)

    def _lighting_evenness(self, image: Image.Image, skin_mask: list[bool]) -> float:
        width, _ = image.size
        pixels = self._rgb_pixels(image)
        left_values = []
        right_values = []

        for index, (pixel, is_skin) in enumerate(zip(pixels, skin_mask, strict=True)):
            if not is_skin:
                continue

            brightness = max(pixel) / 255
            if index % width < width / 2:
                left_values.append(brightness)
            else:
                right_values.append(brightness)

        if not left_values or not right_values:
            return 0.0

        difference = abs(mean(left_values) - mean(right_values))
        return round(max(0.0, min(1.0, 1 - (difference * 3.4))), 2)

    def _balance_ratio(self, left: int, right: int) -> float:
        larger = max(left, right)
        if larger == 0:
            return 0.0
        return min(left, right) / larger

    def _looks_like_skin(self, pixel: tuple[int, int, int]) -> bool:
        red, green, blue = pixel
        max_channel = max(pixel)
        min_channel = min(pixel)

        rgb_rule = (
            red > 80
            and green > 35
            and blue > 20
            and max_channel - min_channel > 12
            and red > blue
            and red >= green * 0.88
        )

        y = 0.299 * red + 0.587 * green + 0.114 * blue
        cb = 128 - 0.168736 * red - 0.331264 * green + 0.5 * blue
        cr = 128 + 0.5 * red - 0.418688 * green - 0.081312 * blue
        ycbcr_rule = y > 50 and 77 <= cb <= 135 and 133 <= cr <= 180

        return rgb_rule and ycbcr_rule

    def _extract_metrics(
        self,
        image: Image.Image,
        pixels: list[tuple[int, int, int]],
        skin_coverage: float,
        face_centering: float,
        lighting_evenness: float,
    ) -> SkinMetrics:
        brightness_values = []
        saturation_values = []
        red_flags = []
        dark_flags = []
        highlight_flags = []

        for red, green, blue in pixels:
            high = max(red, green, blue)
            low = min(red, green, blue)
            brightness = high / 255
            saturation = 0 if high == 0 else (high - low) / high

            brightness_values.append(brightness)
            saturation_values.append(saturation)
            red_flags.append(
                red - green > self.calibration.red_dominance_threshold
                and red - blue > self.calibration.red_dominance_threshold
                and red > self.calibration.red_min_value
                and saturation > 0.42
            )
            dark_flags.append(
                brightness < self.calibration.dark_brightness_threshold
                and saturation > self.calibration.dark_saturation_threshold
            )
            highlight_flags.append(
                brightness > self.calibration.highlight_brightness_threshold
                and saturation < self.calibration.highlight_saturation_threshold
            )

        texture_score = self._texture_score(image)

        raw_red_ratio = sum(red_flags) / len(red_flags)
        raw_dark_ratio = sum(dark_flags) / len(dark_flags)
        raw_highlight_ratio = sum(highlight_flags) / len(highlight_flags)

        return SkinMetrics(
            brightness=mean(brightness_values),
            saturation=mean(saturation_values),
            red_ratio=min(raw_red_ratio * 28, 1.0),
            dark_ratio=min(raw_dark_ratio * 28, 1.0),
            highlight_ratio=min(raw_highlight_ratio * 10, 1.0),
            texture_score=texture_score,
            skin_coverage=skin_coverage,
            face_centering=face_centering,
            lighting_evenness=lighting_evenness,
        )

    def _texture_score(self, image: Image.Image) -> float:
        gray = image.convert("L")
        gray.thumbnail((220, 220))
        edges = gray.filter(ImageFilter.FIND_EDGES)
        values = list(edges.tobytes())
        edge_mean = mean(values) / 255

        return min(edge_mean * self.calibration.texture_multiplier, 1.0)

    def _rgb_pixels(self, image: Image.Image) -> list[tuple[int, int, int]]:
        data = image.tobytes()
        return list(zip(data[0::3], data[1::3], data[2::3], strict=True))

    def _classify_skin_type(self, metrics: SkinMetrics) -> tuple[str, float]:
        if metrics.red_ratio >= 0.05:
            return "sensitive", 0.72

        if metrics.texture_score >= 0.13 and metrics.brightness < 0.68:
            return "dry", 0.71

        oily_score = (metrics.highlight_ratio * self.calibration.oily_highlight_weight) + (metrics.brightness * 0.45)
        dry_score = ((1 - metrics.brightness) * 0.45) + (metrics.texture_score * 0.6)
        sensitive_score = metrics.red_ratio * 4.0
        balanced_score = 1 - min(abs(metrics.brightness - 0.62) + abs(metrics.saturation - 0.33), 1)

        scores = {
            "oily": oily_score,
            "dry": dry_score,
            "sensitive": sensitive_score,
            "normal": balanced_score,
        }

        if oily_score > 0.5 and dry_score > 0.45:
            return "combination", 0.67

        skin_type, score = max(scores.items(), key=lambda item: item[1])
        confidence = min(0.55 + (score * 0.35), 0.92)
        return skin_type, round(float(confidence), 2)

    def _detect_concerns(self, metrics: SkinMetrics) -> list[Concern]:
        lighting_factor = self._lighting_confidence_factor(metrics)
        candidates = [
            ("acne", metrics.red_ratio * self.calibration.acne_red_weight * lighting_factor, "moderate"),
            ("redness", metrics.red_ratio * self.calibration.redness_red_weight * lighting_factor, "mild"),
            ("dark_spots", metrics.dark_ratio * self.calibration.dark_spots_weight * lighting_factor, "mild"),
            ("texture", metrics.texture_score * 2.1 * lighting_factor, "mild"),
            ("oiliness", metrics.highlight_ratio * self.calibration.oiliness_highlight_weight * lighting_factor, "moderate"),
            ("dryness", (((1 - metrics.brightness) * 0.45) + (metrics.texture_score * 1.1)) * lighting_factor, "mild"),
        ]

        concerns = [
            Concern(name=name, confidence=round(min(confidence, 0.95), 2), severity=self._severity(confidence, fallback))
            for name, confidence, fallback in candidates
            if confidence >= self.calibration.concern_min_confidence
        ]

        return sorted(concerns, key=lambda concern: concern.confidence, reverse=True)[:4]

    def _skin_zone(self, key: str, label: str, metrics: SkinMetrics) -> SkinZone:
        concerns = self._detect_concerns(metrics)[:3]
        score = self._skin_health_score(metrics, concerns)

        return SkinZone(
            key=key,
            label=label,
            concerns=concerns,
            score=score,
            oiliness=round(min(metrics.highlight_ratio * self.calibration.oiliness_highlight_weight, 1.0), 2),
            dark_spots=round(min(metrics.dark_ratio * self.calibration.dark_spots_weight, 1.0), 2),
            redness=round(min(metrics.red_ratio * self.calibration.redness_red_weight, 1.0), 2),
            texture=round(min(metrics.texture_score * 2.1, 1.0), 2),
            dryness=round(min(((1 - metrics.brightness) * 0.45) + (metrics.texture_score * 1.1), 1.0), 2),
        )

    def _severity(self, confidence: float, fallback: str) -> str:
        if confidence >= 0.84:
            return "severe"
        if confidence >= 0.72:
            return "moderate"
        if confidence >= 0.45:
            return fallback
        return "mild"

    def _acne_severity(self, concerns: list[Concern]) -> str:
        acne = next((concern for concern in concerns if concern.name == "acne"), None)
        if acne is None:
            return "none"

        return acne.severity

    def _skin_health_score(self, metrics: SkinMetrics, concerns: list[Concern]) -> int:
        concern_penalty = sum(concern.confidence for concern in concerns) * 9
        balance_penalty = abs(metrics.brightness - 0.62) * 18
        coverage_penalty = 10 if metrics.skin_coverage < 0.12 else 0
        centering_penalty = 7 if metrics.face_centering < 0.45 else 0
        evenness_penalty = 5 if metrics.lighting_evenness < 0.45 else 0
        score = 92 - concern_penalty - balance_penalty - coverage_penalty - centering_penalty - evenness_penalty

        return int(max(35, min(round(score), 96)))

    def _scan_quality(self, metrics: SkinMetrics) -> ScanQuality:
        if metrics.skin_coverage < 0.12:
            return ScanQuality(
                level="low",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                message="Face area is not clear enough. Retake with your full face inside the guide.",
            )
        if metrics.face_centering < 0.42:
            return ScanQuality(
                level="low",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                message="Face is turned, cropped, or off-center. Look straight and keep both cheeks inside the guide.",
            )
        if metrics.brightness < 0.42:
            return ScanQuality(
                level="low",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                message="Lighting is too dark, so acne and spots may be over-read. Retake near a window or soft light.",
            )
        if metrics.brightness > 0.84 or metrics.highlight_ratio > 0.62:
            return ScanQuality(
                level="medium",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                message="Lighting is too bright or shiny. Reduce glare for a more stable result.",
            )
        if metrics.lighting_evenness < 0.45:
            return ScanQuality(
                level="medium",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                message="Lighting is uneven across the face. Face a soft light source directly before scanning.",
            )
        return ScanQuality(
            level="good",
            brightness=round(metrics.brightness, 2),
            skin_coverage=round(metrics.skin_coverage, 2),
            face_centering=round(metrics.face_centering, 2),
            message="Lighting is good enough for routine guidance.",
        )

    def _lighting_confidence_factor(self, metrics: SkinMetrics) -> float:
        if metrics.skin_coverage < 0.12 or metrics.face_centering < 0.42:
            return 0.52
        if metrics.brightness < 0.42:
            return 0.58
        if metrics.brightness > 0.84 or metrics.highlight_ratio > 0.62:
            return 0.7
        if metrics.lighting_evenness < 0.45:
            return 0.76
        return 1.0


def _label(value: str) -> str:
    return value.replace("_", " ")
