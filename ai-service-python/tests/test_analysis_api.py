from io import BytesIO
import json
import math
from unittest import TestCase

from fastapi.testclient import TestClient
from PIL import Image, ImageDraw

from app.main import app


class AnalysisApiTest(TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_health_endpoint_returns_service_status(self) -> None:
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok", "service": "skin-ai-service"})

    def test_analyze_returns_stable_contract_for_image_upload(self) -> None:
        response = self.client.post(
            "/analyze",
            files={"image": ("face.png", self._sample_skin_image(), "image/png")},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()

        self.assertIn(payload["skin_type"], ["oily", "dry", "combination", "normal", "sensitive"])
        self.assertGreaterEqual(payload["skin_type_confidence"], 0)
        self.assertLessEqual(payload["skin_type_confidence"], 1)
        self.assertIsInstance(payload["concerns"], list)
        self.assertIsInstance(payload["skin_zones"], list)
        self.assertGreaterEqual(len(payload["skin_zones"]), 4)
        self.assertIn(payload["acne_severity"], ["none", "mild", "moderate", "severe"])
        self.assertGreaterEqual(payload["skin_health_score"], 0)
        self.assertLessEqual(payload["skin_health_score"], 100)
        self.assertIn("treatment_package", payload)

        if payload["treatment_package"] is not None:
            self.assertIn("name", payload["treatment_package"])
            self.assertIn("steps", payload["treatment_package"])
            self.assertIn("follow_up_days", payload["treatment_package"])

        for concern in payload["concerns"]:
            self.assertIn("name", concern)
            self.assertIn("confidence", concern)
            self.assertIn("severity", concern)
            self.assertGreaterEqual(concern["confidence"], 0)
            self.assertLessEqual(concern["confidence"], 1)

        for zone in payload["skin_zones"]:
            self.assertIn("key", zone)
            self.assertIn("label", zone)
            self.assertIn("score", zone)
            self.assertIn("concerns", zone)
            self.assertIn("oiliness", zone)
            self.assertIn("dark_spots", zone)
            self.assertIn("redness", zone)
            self.assertIn("texture", zone)
            self.assertIn("dryness", zone)
            self.assertGreaterEqual(zone["score"], 0)
            self.assertLessEqual(zone["score"], 100)

    def test_bad_lighting_dampens_confidence_and_flags_quality(self) -> None:
        response = self.client.post(
            "/analyze",
            files={"image": ("dark-face.png", self._dark_skin_image(), "image/png")},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()

        self.assertIn(payload["scan_quality"]["level"], ["low", "medium"])
        self.assertLessEqual(payload["skin_type_confidence"], 0.7)
        for concern in payload["concerns"]:
            self.assertLessEqual(concern["confidence"], 0.8)

    def test_analyze_rejects_invalid_image_upload(self) -> None:
        response = self.client.post(
            "/analyze",
            files={"image": ("notes.txt", b"not an image", "text/plain")},
        )

        self.assertEqual(response.status_code, 415)

    def test_analyze_accepts_landmarks_for_adaptive_skin_zones(self) -> None:
        landmarks = [
            {
                "x": 0.5 + (0.32 * math.cos(index * 0.37)),
                "y": 0.5 + (0.40 * math.sin(index * 0.37)),
                "z": 0,
            }
            for index in range(478)
        ]
        response = self.client.post(
            "/analyze",
            files={"image": ("face.png", self._sample_skin_image(), "image/png")},
            data={"face_landmarks": json.dumps(landmarks)},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [zone["key"] for zone in response.json()["skin_zones"]],
            ["forehead", "left_cheek", "right_cheek", "nose", "chin"],
        )
        self.assertGreaterEqual(len(response.json()["skin_zones"][0]["polygon"]), 8)

    def test_analyze_aggregates_three_frames(self) -> None:
        response = self.client.post(
            "/analyze",
            files=[
                ("image", ("frame-1.png", self._sample_skin_image(), "image/png")),
                ("frames", ("frame-2.png", self._sample_skin_image(), "image/png")),
                ("frames", ("frame-3.png", self._dark_skin_image(), "image/png")),
            ],
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertIn(payload["acne_severity"], ["none", "mild", "moderate", "severe"])
        self.assertIn(payload["scan_quality"]["level"], ["good", "medium", "low"])
        self.assertGreaterEqual(len(payload["skin_zones"]), 4)

    def test_analyze_rejects_malformed_landmarks(self) -> None:
        response = self.client.post(
            "/analyze",
            files={"image": ("face.png", self._sample_skin_image(), "image/png")},
            data={"face_landmarks": "[]"},
        )

        self.assertEqual(response.status_code, 422)

    def _sample_skin_image(self) -> bytes:
        image = Image.new("RGB", (320, 320), (190, 132, 105))
        draw = ImageDraw.Draw(image)

        for x, y, radius in [(88, 104, 8), (170, 130, 6), (218, 204, 7)]:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(178, 55, 58))

        for x, y, radius in [(120, 210, 9), (240, 92, 7)]:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(92, 58, 45))

        buffer = BytesIO()
        image.save(buffer, format="PNG")
        return buffer.getvalue()

    def _dark_skin_image(self) -> bytes:
        image = Image.new("RGB", (320, 320), (62, 42, 35))
        draw = ImageDraw.Draw(image)

        for x, y, radius in [(108, 120, 9), (202, 170, 7)]:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(88, 32, 35))

        buffer = BytesIO()
        image.save(buffer, format="PNG")
        return buffer.getvalue()
