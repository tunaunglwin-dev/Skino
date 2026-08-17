from pathlib import Path

from app.trained_model import TrainedSkinModel
from app.vision import SkinVisionAnalyzer


def test_trained_model_artifact_can_predict_with_sample_image() -> None:
    model_path = Path(__file__).resolve().parents[2] / "models" / "sample_skin_model.json"
    image_path = (
        Path(__file__).resolve().parents[2]
        / "datasets"
        / "samples"
        / "prepared"
        / "images"
        / "oily_highlight-29447b3e371a.jpg"
    )

    trained_model = TrainedSkinModel.load(model_path)

    assert trained_model is not None

    analyzer = SkinVisionAnalyzer(trained_model=trained_model)
    result = analyzer.analyze(image_path.read_bytes())

    assert result.skin_type
    assert result.acne_severity in {"none", "mild", "moderate", "severe"}
    assert 0 <= result.skin_type_confidence <= 1
    assert 0 <= result.skin_health_score <= 100
    assert result.skin_zones
