import json
import os
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile

from app.calibration import HeuristicCalibration
from app.cnn_model import TorchScriptAcneModel
from app.schemas import AnalysisResponse
from app.trained_model import TrainedSkinModel
from app.vision import InvalidImageError, SkinVisionAnalyzer


app = FastAPI(title="Skin AI Service", version="0.3.0")
MAX_IMAGE_BYTES = 8 * 1024 * 1024
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
analyzer = SkinVisionAnalyzer(
    calibration=HeuristicCalibration.load(os.getenv("SKIN_AI_CALIBRATION_PATH")),
    trained_model=TrainedSkinModel.load(os.getenv("SKIN_AI_MODEL_PATH")),
    acne_model=TorchScriptAcneModel.load(
        os.getenv(
            "SKIN_AI_TORCHSCRIPT_PATH",
            str(Path(__file__).resolve().parents[2] / "models" / "cnn_acne_severity_v1" / "model.torchscript.pt"),
        ),
        temperature=float(os.getenv("SKIN_AI_TORCHSCRIPT_TEMPERATURE", "1.125")),
    ),
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "skin-ai-service"}


@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_skin(
    image: UploadFile = File(...),
    frames: list[UploadFile] | None = File(None),
    face_landmarks: str | None = Form(None),
) -> AnalysisResponse:
    uploads = [image, *(frames or [])][:3]
    for upload in uploads:
        if upload.content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(status_code=415, detail="Only JPEG, PNG, and WebP images are supported.")

    image_frames = [await upload.read() for upload in uploads]
    if any(len(frame) > MAX_IMAGE_BYTES for frame in image_frames):
        raise HTTPException(status_code=413, detail="Each image must be 8 MB or smaller.")

    try:
        landmarks = parse_landmarks(face_landmarks)
        return analyzer.analyze_many(image_frames, landmarks)
    except InvalidImageError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


def parse_landmarks(value: str | None) -> list[dict[str, float]] | None:
    if not value:
        return None
    try:
        payload = json.loads(value)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=422, detail="face_landmarks must be valid JSON.") from exc
    if not isinstance(payload, list) or len(payload) < 468:
        raise HTTPException(status_code=422, detail="face_landmarks must contain at least 468 points.")
    normalized = []
    for point in payload[:478]:
        if not isinstance(point, dict) or "x" not in point or "y" not in point:
            raise HTTPException(status_code=422, detail="Each face landmark needs x and y coordinates.")
        try:
            normalized.append({"x": float(point["x"]), "y": float(point["y"]), "z": float(point.get("z", 0))})
        except (TypeError, ValueError) as exc:
            raise HTTPException(status_code=422, detail="Face landmark coordinates must be numeric.") from exc
    return normalized
        
