import os

from fastapi import FastAPI, File, HTTPException, UploadFile

from app.calibration import HeuristicCalibration
from app.schemas import AnalysisResponse
from app.trained_model import TrainedSkinModel
from app.vision import InvalidImageError, SkinVisionAnalyzer


app = FastAPI(title="Skin AI Service", version="0.2.0")
MAX_IMAGE_BYTES = 8 * 1024 * 1024
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
analyzer = SkinVisionAnalyzer(
    calibration=HeuristicCalibration.load(os.getenv("SKIN_AI_CALIBRATION_PATH")),
    trained_model=TrainedSkinModel.load(os.getenv("SKIN_AI_MODEL_PATH")),
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "skin-ai-service"}


@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_skin(image: UploadFile = File(...)) -> AnalysisResponse:
    if image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=415, detail="Only JPEG, PNG, and WebP images are supported.")

    image_bytes = await image.read()
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image must be 8 MB or smaller.")

    try:
        return analyzer.analyze(image_bytes)
    except InvalidImageError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
        
