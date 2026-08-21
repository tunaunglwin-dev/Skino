from pydantic import BaseModel, Field


class Concern(BaseModel):
    name: str
    confidence: float = Field(ge=0, le=1)
    severity: str


class ZonePoint(BaseModel):
    x: float = Field(ge=-0.15, le=1.15)
    y: float = Field(ge=-0.15, le=1.15)


class TreatmentPackage(BaseModel):
    key: str
    name: str
    steps: list[str]
    follow_up_days: int = Field(gt=0)
    reason: str


class SkinZone(BaseModel):
    key: str
    label: str
    concerns: list[Concern]
    score: int = Field(ge=0, le=100)
    oiliness: float = Field(ge=0, le=1)
    dark_spots: float = Field(ge=0, le=1)
    redness: float = Field(ge=0, le=1)
    texture: float = Field(ge=0, le=1)
    dryness: float = Field(ge=0, le=1)
    polygon: list[ZonePoint] = Field(default_factory=list)


class ScanQuality(BaseModel):
    level: str
    brightness: float = Field(ge=0, le=1)
    skin_coverage: float = Field(ge=0, le=1)
    face_centering: float = Field(default=1.0, ge=0, le=1)
    lighting_evenness: float = Field(default=1.0, ge=0, le=1)
    sharpness: float = Field(default=1.0, ge=0, le=1)
    message: str


class AnalysisResponse(BaseModel):
    skin_type: str
    skin_type_confidence: float = Field(ge=0, le=1)
    concerns: list[Concern]
    skin_zones: list[SkinZone] = Field(default_factory=list)
    scan_quality: ScanQuality | None = None
    acne_severity: str = "none"
    skin_health_score: int = Field(ge=0, le=100)
    treatment_package: TreatmentPackage | None = None
