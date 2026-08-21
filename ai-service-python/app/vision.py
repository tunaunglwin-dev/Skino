from collections import Counter
from dataclasses import dataclass, replace
from io import BytesIO
from statistics import mean, median

from PIL import Image, ImageFilter, ImageOps, UnidentifiedImageError

from app.calibration import HeuristicCalibration
from app.cnn_model import TorchScriptAcneModel
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
    sharpness: float


class SkinVisionAnalyzer:
    def __init__(
        self,
        calibration: HeuristicCalibration | None = None,
        trained_model: TrainedSkinModel | None = None,
        acne_model: TorchScriptAcneModel | None = None,
    ) -> None:
        self.calibration = calibration or HeuristicCalibration()
        self.trained_model = trained_model
        self.acne_model = acne_model

    def analyze(self, image_bytes: bytes, face_landmarks: list[dict[str, float]] | None = None) -> AnalysisResponse:
        raw_image = self._resize_for_analysis(self._decode_image(image_bytes))
        quality_metrics = self._extract_image_metrics(raw_image)
        image = self._normalize_luminance(raw_image)
        metrics = self._extract_image_metrics(image)
        skin_zones = self._extract_skin_zones(image, face_landmarks, metrics)
        scan_quality = self._scan_quality(quality_metrics)
        if self.trained_model:
            trained_result = self.trained_model.predict(metrics)
            if trained_result.skin_type != "unknown":
                result = self._stabilize_result(
                    trained_result.model_copy(
                        update={
                            "skin_zones": skin_zones,
                            "scan_quality": scan_quality,
                        }
                    ),
                    quality_metrics,
                )
                return self._apply_acne_model(result, image, scan_quality)

            fallback_result = self.predict(metrics)
            result = self._stabilize_result(
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
                quality_metrics,
            )
            return self._apply_acne_model(result, image, scan_quality)

        result = self._stabilize_result(
            self.predict(metrics).model_copy(
                update={
                    "skin_zones": skin_zones,
                    "scan_quality": scan_quality,
                }
            ),
            quality_metrics,
        )
        return self._apply_acne_model(result, image, scan_quality)

    def analyze_many(
        self,
        image_frames: list[bytes],
        face_landmarks: list[dict[str, float]] | None = None,
    ) -> AnalysisResponse:
        if not image_frames:
            raise InvalidImageError("Empty image upload.")
        results = [self.analyze(frame, face_landmarks) for frame in image_frames[:3]]
        return results[0] if len(results) == 1 else self._median_result(results)

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
        if metrics.sharpness < 0.34:
            factor *= 0.72

        return max(0.42, min(factor, 1.0))

    def extract_metrics(self, image_bytes: bytes) -> SkinMetrics:
        image = self._decode_image(image_bytes)
        image = self._resize_for_analysis(image)
        image = self._normalize_luminance(image)
        return self._extract_image_metrics(image)

    def _extract_image_metrics(self, image: Image.Image) -> SkinMetrics:
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
        return self._extract_skin_zones(image, face_landmarks, self.extract_metrics(image_bytes))

    def _extract_skin_zones(
        self,
        image: Image.Image,
        face_landmarks: list[dict[str, float]] | None,
        global_metrics: SkinMetrics,
    ) -> list[SkinZone]:
        width, height = image.size

        landmark_regions = landmark_zone_images(image, face_landmarks)
        if landmark_regions:
            return [
                self._zone_from_crop(
                    region.key,
                    region.label,
                    region.image,
                    mask=region.mask,
                    global_metrics=global_metrics,
                    polygon=region.polygon,
                )
                for region in landmark_regions
            ]

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
            zones.append(self._zone_from_crop(key, label, crop, global_metrics=global_metrics))

        return zones

    def _zone_from_crop(
        self,
        key: str,
        label: str,
        crop: Image.Image,
        *,
        mask: Image.Image | None = None,
        global_metrics: SkinMetrics | None = None,
        polygon: list[dict[str, float]] | None = None,
    ) -> SkinZone:
        effective_mask = self._refine_skin_mask(crop, mask) if mask is not None else None
        pixels, coverage, face_centering, lighting_evenness = self._skin_pixels(crop, effective_mask)
        metrics = self._extract_metrics(
            crop,
            pixels,
            coverage,
            face_centering,
            lighting_evenness,
            effective_mask,
        )
        if global_metrics is not None:
            metrics = self._normalize_zone_metrics(metrics, global_metrics)
        return self._skin_zone(key, label, metrics, polygon or [])

    def _refine_skin_mask(self, image: Image.Image, polygon_mask: Image.Image) -> Image.Image:
        resized_mask = polygon_mask.resize(image.size)
        polygon_values = list(resized_mask.get_flattened_data())
        pixels = self._rgb_pixels(image)
        refined_values = [
            255 if mask_value >= 128 and self._looks_like_skin(pixel) else 0
            for pixel, mask_value in zip(pixels, polygon_values, strict=True)
        ]
        polygon_count = sum(value >= 128 for value in polygon_values)
        if sum(value >= 128 for value in refined_values) < polygon_count * 0.08:
            return resized_mask
        refined = Image.new("L", image.size)
        refined.putdata(refined_values)
        return refined

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

    def _normalize_luminance(self, image: Image.Image) -> Image.Image:
        """Gently reduce camera exposure differences without changing skin chroma."""
        luminance, blue_chroma, red_chroma = image.convert("YCbCr").split()
        corrected = ImageOps.autocontrast(luminance, cutoff=(1, 1))
        luminance = Image.blend(luminance, corrected, 0.32)
        return Image.merge("YCbCr", (luminance, blue_chroma, red_chroma)).convert("RGB")

    def _resize_for_analysis(self, image: Image.Image) -> Image.Image:
        image.thumbnail((512, 512), Image.Resampling.LANCZOS)
        return image

    def _skin_pixels(
        self,
        image: Image.Image,
        analysis_mask: Image.Image | None = None,
    ) -> tuple[list[tuple[int, int, int]], float, float, float]:
        width, height = image.size
        if analysis_mask is not None:
            region = image
            eligible_mask = [value >= 128 for value in analysis_mask.resize(image.size).get_flattened_data()]
        else:
            crop_size = int(min(width, height) * 0.78)
            left = (width - crop_size) // 2
            top = (height - crop_size) // 2
            region = image.crop((left, top, left + crop_size, top + crop_size))
            eligible_mask = [True] * (region.width * region.height)
        pixels = self._rgb_pixels(region)

        skin_mask = [eligible and self._looks_like_skin(pixel) for pixel, eligible in zip(pixels, eligible_mask, strict=True)]
        skin_pixels = [
            pixel
            for pixel, is_skin in zip(pixels, skin_mask, strict=True)
            if is_skin
        ]
        eligible_pixels = sum(eligible_mask)
        coverage = len(skin_pixels) / max(eligible_pixels, 1)
        face_centering = 1.0 if analysis_mask is not None else self._face_centering_score(skin_mask, region.size)
        lighting_evenness = self._lighting_evenness(region, skin_mask)

        if coverage < 0.08:
            masked_pixels = [pixel for pixel, eligible in zip(pixels, eligible_mask, strict=True) if eligible]
            return masked_pixels or pixels, coverage, face_centering, lighting_evenness

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
        analysis_mask: Image.Image | None = None,
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

        texture_score = self._texture_score(image, analysis_mask)
        sharpness = self._sharpness_score(image, analysis_mask)

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
            sharpness=sharpness,
        )

    def _texture_score(self, image: Image.Image, analysis_mask: Image.Image | None = None) -> float:
        gray = image.convert("L")
        gray.thumbnail((512, 512))
        values = list(gray.get_flattened_data())
        width, height = gray.size
        valid = (
            [value >= 128 for value in analysis_mask.resize(gray.size).get_flattened_data()]
            if analysis_mask is not None
            else [True] * len(values)
        )
        differences = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                index = (y * width) + x
                neighbors = [index - 1, index + 1, index - width, index + width]
                if not valid[index] or not all(valid[position] for position in neighbors):
                    continue
                differences.append(abs((values[index] * 4) - sum(values[position] for position in neighbors)))
        edge_mean = (mean(differences) / 255) if differences else 0.0

        return min(edge_mean * self.calibration.texture_multiplier, 1.0)

    def _sharpness_score(self, image: Image.Image, analysis_mask: Image.Image | None = None) -> float:
        gray = image.convert("L")
        gray.thumbnail((512, 512))
        values = list(gray.get_flattened_data())
        width, height = gray.size
        valid = (
            [value >= 128 for value in analysis_mask.resize(gray.size).get_flattened_data()]
            if analysis_mask is not None
            else [True] * len(values)
        )
        gradients = []
        for y in range(1, height - 1, 2):
            for x in range(1, width - 1, 2):
                index = (y * width) + x
                if valid[index] and valid[index + 1] and valid[index + width]:
                    gradients.append(abs(values[index] - values[index + 1]) + abs(values[index] - values[index + width]))
        return round(min((mean(gradients) if gradients else 0.0) / 28.0, 1.0), 3)

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

    def _normalize_zone_metrics(self, zone: SkinMetrics, face: SkinMetrics) -> SkinMetrics:
        """Reduce camera/lighting bias while preserving local differences."""

        def relative(value: float, baseline: float, positive_weight: float = 0.9) -> float:
            difference = value - baseline
            adjusted = (value * 0.58) + (max(difference, 0.0) * positive_weight)
            return max(0.0, min(adjusted, 1.0))

        return replace(
            zone,
            brightness=max(0.24, min(0.92, 0.62 + ((zone.brightness - face.brightness) * 1.15))),
            saturation=max(0.05, min(0.85, 0.33 + ((zone.saturation - face.saturation) * 1.1))),
            red_ratio=relative(zone.red_ratio, face.red_ratio, 1.15),
            dark_ratio=relative(zone.dark_ratio, face.dark_ratio, 1.05),
            highlight_ratio=relative(zone.highlight_ratio, face.highlight_ratio, 1.0),
            texture_score=relative(zone.texture_score, face.texture_score, 0.85),
        )

    def _skin_zone(
        self,
        key: str,
        label: str,
        metrics: SkinMetrics,
        polygon: list[dict[str, float]],
    ) -> SkinZone:
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
            polygon=polygon,
        )

    def _apply_acne_model(
        self,
        result: AnalysisResponse,
        image: Image.Image,
        scan_quality: ScanQuality,
    ) -> AnalysisResponse:
        if self.acne_model is None or scan_quality.level == "low" or scan_quality.sharpness < 0.34:
            return result
        prediction = self.acne_model.predict(image)
        minimum = 0.78 if prediction.severity == "none" else 0.58
        if prediction.confidence < minimum:
            return result

        concerns = [concern for concern in result.concerns if concern.name != "acne"]
        if prediction.severity != "none":
            concerns.append(
                Concern(
                    name="acne",
                    confidence=round(min(prediction.confidence * 0.86, 0.88), 2),
                    severity=prediction.severity,
                )
            )
        concerns = sorted(concerns, key=lambda concern: concern.confidence, reverse=True)[:4]
        return result.model_copy(
            update={
                "concerns": concerns,
                "acne_severity": prediction.severity,
                "treatment_package": self._recommend_treatment_package(result.skin_type, concerns),
            }
        )

    def _median_result(self, results: list[AnalysisResponse]) -> AnalysisResponse:
        skin_type = Counter(result.skin_type for result in results).most_common(1)[0][0]
        concerns = self._median_concerns([result.concerns for result in results])
        zones = []
        zone_keys = [zone.key for zone in results[0].skin_zones]
        for key in zone_keys:
            samples = [next((zone for zone in result.skin_zones if zone.key == key), None) for result in results]
            samples = [sample for sample in samples if sample is not None]
            if not samples:
                continue
            zones.append(
                SkinZone(
                    key=key,
                    label=samples[0].label,
                    concerns=self._median_concerns([sample.concerns for sample in samples]),
                    score=round(median(sample.score for sample in samples)),
                    oiliness=round(median(sample.oiliness for sample in samples), 2),
                    dark_spots=round(median(sample.dark_spots for sample in samples), 2),
                    redness=round(median(sample.redness for sample in samples), 2),
                    texture=round(median(sample.texture for sample in samples), 2),
                    dryness=round(median(sample.dryness for sample in samples), 2),
                    polygon=samples[0].polygon,
                )
            )

        quality_order = {"good": 0, "medium": 1, "low": 2}
        quality_source = max(
            (result.scan_quality for result in results if result.scan_quality is not None),
            key=lambda quality: quality_order.get(quality.level, 2),
        )
        quality = quality_source.model_copy(
            update={
                "brightness": round(median(result.scan_quality.brightness for result in results if result.scan_quality), 2),
                "skin_coverage": round(median(result.scan_quality.skin_coverage for result in results if result.scan_quality), 2),
                "face_centering": round(median(result.scan_quality.face_centering for result in results if result.scan_quality), 2),
                "lighting_evenness": round(median(result.scan_quality.lighting_evenness for result in results if result.scan_quality), 2),
                "sharpness": round(median(result.scan_quality.sharpness for result in results if result.scan_quality), 2),
            }
        )
        severity_order = ["none", "mild", "moderate", "severe"]
        severity = severity_order[round(median(severity_order.index(result.acne_severity) for result in results))]
        return AnalysisResponse(
            skin_type=skin_type,
            skin_type_confidence=round(median(result.skin_type_confidence for result in results), 2),
            concerns=concerns,
            skin_zones=zones,
            scan_quality=quality,
            acne_severity=severity,
            skin_health_score=round(median(result.skin_health_score for result in results)),
            treatment_package=self._recommend_treatment_package(skin_type, concerns),
        )

    def _median_concerns(self, samples: list[list[Concern]]) -> list[Concern]:
        names = sorted({concern.name for concerns in samples for concern in concerns})
        severity_order = ["none", "mild", "moderate", "severe"]
        combined = []
        for name in names:
            matches = [next((concern for concern in concerns if concern.name == name), None) for concerns in samples]
            confidence = median(match.confidence if match else 0.0 for match in matches)
            if confidence < self.calibration.stable_concern_floor:
                continue
            severities = [match.severity for match in matches if match]
            severity = Counter(severities).most_common(1)[0][0] if severities else "mild"
            if severity not in severity_order:
                severity = "mild"
            combined.append(Concern(name=name, confidence=round(confidence, 2), severity=severity))
        return sorted(combined, key=lambda concern: concern.confidence, reverse=True)[:4]

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
                lighting_evenness=round(metrics.lighting_evenness, 2),
                sharpness=round(metrics.sharpness, 2),
                message="Face area is not clear enough. Retake with your full face inside the guide.",
            )
        if metrics.face_centering < 0.42:
            return ScanQuality(
                level="low",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                lighting_evenness=round(metrics.lighting_evenness, 2),
                sharpness=round(metrics.sharpness, 2),
                message="Face is turned, cropped, or off-center. Look straight and keep both cheeks inside the guide.",
            )
        if metrics.sharpness < 0.28:
            return ScanQuality(
                level="low",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                lighting_evenness=round(metrics.lighting_evenness, 2),
                sharpness=round(metrics.sharpness, 2),
                message="The image is too soft or blurred for stable zone matching. Clean the lens, hold still, and retake.",
            )
        if metrics.brightness < 0.42:
            return ScanQuality(
                level="low",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                lighting_evenness=round(metrics.lighting_evenness, 2),
                sharpness=round(metrics.sharpness, 2),
                message="Lighting is too dark, so acne and spots may be over-read. Retake near a window or soft light.",
            )
        if metrics.brightness > 0.84 or metrics.highlight_ratio > 0.62:
            return ScanQuality(
                level="medium",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                lighting_evenness=round(metrics.lighting_evenness, 2),
                sharpness=round(metrics.sharpness, 2),
                message="Lighting is too bright or shiny. Reduce glare for a more stable result.",
            )
        if metrics.lighting_evenness < 0.45:
            return ScanQuality(
                level="medium",
                brightness=round(metrics.brightness, 2),
                skin_coverage=round(metrics.skin_coverage, 2),
                face_centering=round(metrics.face_centering, 2),
                lighting_evenness=round(metrics.lighting_evenness, 2),
                sharpness=round(metrics.sharpness, 2),
                message="Lighting is uneven across the face. Face a soft light source directly before scanning.",
            )
        return ScanQuality(
            level="good",
            brightness=round(metrics.brightness, 2),
            skin_coverage=round(metrics.skin_coverage, 2),
            face_centering=round(metrics.face_centering, 2),
            lighting_evenness=round(metrics.lighting_evenness, 2),
            sharpness=round(metrics.sharpness, 2),
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
        if metrics.sharpness < 0.34:
            return 0.7
        return 1.0


def _label(value: str) -> str:
    return value.replace("_", " ")
