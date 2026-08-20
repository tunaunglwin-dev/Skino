from __future__ import annotations

from PIL import Image, ImageDraw


# MediaPipe Face Landmarker indices. Polygons follow facial anatomy and adapt to pose/scale.
ZONE_POLYGONS = {
    "forehead": ("Forehead", [127, 34, 139, 71, 68, 104, 69, 108, 10, 337, 299, 333, 298, 301, 368, 264, 356, 300, 293, 334, 296, 336, 107, 66, 105, 63, 70]),
    "left_cheek": ("Left cheek", [50, 101, 205, 187, 123, 116, 111, 117, 118, 119, 100, 36, 206, 216, 212, 202]),
    "right_cheek": ("Right cheek", [280, 330, 425, 411, 352, 345, 340, 346, 347, 348, 329, 266, 426, 436, 432, 422]),
    "nose": ("Nose", [168, 6, 197, 195, 5, 4, 45, 220, 115, 48, 64, 98, 97, 2, 326, 327, 294, 278, 344, 440, 275]),
    "chin": ("Chin", [61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291, 375, 321, 405, 314, 17, 84, 181, 91, 146]),
}


def landmark_zone_images(
    image: Image.Image,
    landmarks: list[dict[str, float]] | None,
) -> list[tuple[str, str, Image.Image]]:
    if not valid_landmarks(landmarks):
        return []

    width, height = image.size
    zones = []
    for key, (label, indices) in ZONE_POLYGONS.items():
        points = [
            (
                round(float(landmarks[index]["x"]) * width),
                round(float(landmarks[index]["y"]) * height),
            )
            for index in indices
        ]
        left = max(min(point[0] for point in points), 0)
        top = max(min(point[1] for point in points), 0)
        right = min(max(point[0] for point in points) + 1, width)
        bottom = min(max(point[1] for point in points) + 1, height)
        if right - left < 8 or bottom - top < 8:
            continue

        mask = Image.new("L", image.size, 0)
        ImageDraw.Draw(mask).polygon(points, fill=255)
        crop = image.crop((left, top, right, bottom))
        crop_mask = mask.crop((left, top, right, bottom))
        masked = Image.composite(crop, Image.new("RGB", crop.size, (0, 0, 0)), crop_mask)
        zones.append((key, label, masked))
    return zones


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
