from __future__ import annotations

from dataclasses import dataclass

from PIL import Image, ImageDraw, ImageFilter


ZONE_POLYGONS = {
    "forehead": ("Forehead", [127, 34, 139, 71, 68, 104, 69, 108, 10, 337, 299, 333, 298, 301, 368, 264, 356, 300, 293, 334, 296, 336, 107, 66, 105, 63, 70]),
    "left_cheek": ("Left cheek", [50, 101, 205, 187, 123, 116, 111, 117, 118, 119, 100, 36, 206, 216, 212, 202]),
    "right_cheek": ("Right cheek", [280, 330, 425, 411, 352, 345, 340, 346, 347, 348, 329, 266, 426, 436, 432, 422]),
    "nose": ("Nose", [168, 6, 197, 195, 5, 4, 45, 220, 115, 48, 64, 98, 97, 2, 326, 327, 294, 278, 344, 440, 275]),
    "chin": ("Chin", [61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291, 375, 321, 405, 314, 17, 84, 181, 91, 146]),
}

# Eye, brow, lip and nostril polygons are removed from every zone mask. Their
# strong boundaries otherwise look like texture, redness, or dark spots.
FEATURE_EXCLUSIONS = [
    [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246],
    [263, 249, 390, 373, 374, 380, 381, 382, 362, 398, 384, 385, 386, 387, 388, 466],
    [70, 63, 105, 66, 107, 55, 65, 52, 53, 46],
    [300, 293, 334, 296, 336, 285, 295, 282, 283, 276],
    [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 308, 324, 318, 402, 317, 14, 87, 178, 88, 95],
    [98, 97, 2, 326, 327, 294, 278, 344, 440, 275, 4, 45, 220, 115, 48, 64],
]


@dataclass(frozen=True)
class LandmarkZoneImage:
    key: str
    label: str
    image: Image.Image
    mask: Image.Image
    polygon: list[dict[str, float]]


def landmark_zone_images(
    image: Image.Image,
    landmarks: list[dict[str, float]] | None,
) -> list[LandmarkZoneImage]:
    if not valid_landmarks(landmarks):
        return []

    width, height = image.size
    exclusion_mask = Image.new("L", image.size, 255)
    exclusion_draw = ImageDraw.Draw(exclusion_mask)
    for indices in FEATURE_EXCLUSIONS:
        exclusion_draw.polygon(_points(landmarks, indices, width, height), fill=0)

    zones = []
    for key, (label, indices) in ZONE_POLYGONS.items():
        points = _points(landmarks, indices, width, height)
        left = max(min(point[0] for point in points), 0)
        top = max(min(point[1] for point in points), 0)
        right = min(max(point[0] for point in points) + 1, width)
        bottom = min(max(point[1] for point in points) + 1, height)
        if right - left < 12 or bottom - top < 12:
            continue

        mask = Image.new("L", image.size, 0)
        ImageDraw.Draw(mask).polygon(points, fill=255)
        erosion = 9 if min(width, height) >= 384 else 5
        mask = mask.filter(ImageFilter.MinFilter(erosion))
        mask = Image.composite(mask, Image.new("L", image.size, 0), exclusion_mask)

        crop = image.crop((left, top, right, bottom))
        crop_mask = mask.crop((left, top, right, bottom))
        if not crop_mask.getbbox():
            continue

        zones.append(
            LandmarkZoneImage(
                key=key,
                label=label,
                image=crop,
                mask=crop_mask,
                polygon=[
                    {
                        "x": round(point[0] / max(width, 1), 6),
                        "y": round(point[1] / max(height, 1), 6),
                    }
                    for point in points
                ],
            )
        )
    return zones


def _points(
    landmarks: list[dict[str, float]],
    indices: list[int],
    width: int,
    height: int,
) -> list[tuple[int, int]]:
    return [
        (
            round(float(landmarks[index]["x"]) * width),
            round(float(landmarks[index]["y"]) * height),
        )
        for index in indices
    ]


def valid_landmarks(landmarks: list[dict[str, float]] | None) -> bool:
    if not isinstance(landmarks, list) or len(landmarks) < 468:
        return False
    try:
        return all(
            -0.15 <= float(point["x"]) <= 1.15
            and -0.15 <= float(point["y"]) <= 1.15
            for point in landmarks[:468]
        )
    except (KeyError, TypeError, ValueError):
        return False
