from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageOps


CLASSES = ["none", "mild", "moderate", "severe"]


@dataclass(frozen=True)
class AcneModelPrediction:
    severity: str
    confidence: float
    probabilities: dict[str, float]


class TorchScriptAcneModel:
    """Optional calibrated CPU runtime for the evaluated MobileNetV3 model."""

    def __init__(self, model, torch_module, image_size: int = 224, temperature: float = 1.125) -> None:
        self.model = model
        self.torch = torch_module
        self.image_size = image_size
        self.temperature = max(float(temperature), 0.1)

    @classmethod
    def load(
        cls,
        path: str | Path | None,
        *,
        image_size: int = 224,
        temperature: float = 1.125,
    ) -> "TorchScriptAcneModel | None":
        if not path:
            return None
        model_path = Path(path)
        if not model_path.exists():
            return None
        try:
            import torch

            model = torch.jit.load(str(model_path), map_location="cpu")
            model.eval()
        except (ImportError, OSError, RuntimeError, ValueError):
            return None
        return cls(model, torch, image_size=image_size, temperature=temperature)

    def predict(self, image: Image.Image) -> AcneModelPrediction:
        prepared = ImageOps.fit(image.convert("RGB"), (self.image_size, self.image_size))
        tensor = self.torch.frombuffer(bytearray(prepared.tobytes()), dtype=self.torch.uint8)
        tensor = tensor.reshape(self.image_size, self.image_size, 3).permute(2, 0, 1).float().div(255.0)
        mean = self.torch.tensor([0.485, 0.456, 0.406]).reshape(3, 1, 1)
        std = self.torch.tensor([0.229, 0.224, 0.225]).reshape(3, 1, 1)
        tensor = tensor.sub(mean).div(std).unsqueeze(0)
        with self.torch.inference_mode():
            logits = self.model(tensor) / self.temperature
            probabilities = self.torch.softmax(logits, dim=1)[0]
        index = int(probabilities.argmax().item())
        values = {
            label: round(float(probabilities[position].item()), 4)
            for position, label in enumerate(CLASSES)
        }
        return AcneModelPrediction(
            severity=CLASSES[index],
            confidence=values[CLASSES[index]],
            probabilities=values,
        )
