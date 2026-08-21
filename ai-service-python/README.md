# AI Service Python

FastAPI service for skin analysis.

Version 2 uses a lightweight image-processing pipeline to return the same JSON contract Laravel already consumes. It is still a wellness prototype, not a diagnosis model. Later versions can load a trained model while keeping the same response shape.

## Run

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 127.0.0.1 --port 5000 --reload
```

Run with the combined acne + normal-skin trained model:

```powershell
$env:SKIN_AI_MODEL_PATH="D:\Skin_care_AI_platform\models\skino_acne_normal_model.json"
uvicorn app.main:app --host 127.0.0.1 --port 5000 --reload
```

## Test

```powershell
.\.venv\Scripts\python.exe -m unittest
```

## Reproducible ML baseline

The release-candidate workflow is deliberately separate from the runtime model. It audits the local data, rebuilds subject-grouped manifests, trains a MobileNetV3-Small baseline, and writes an evaluation report without changing production configuration.

```powershell
pip install -r requirements-ml.txt
.\.venv\Scripts\python.exe tools\audit_and_build_manifests.py
.\.venv\Scripts\python.exe tools\train_cnn_baseline.py `
  --manifest-dir ..\datasets\ml_release_v1 `
  --output-dir ..\models\cnn_acne_severity_v1 `
  --epochs 8 `
  --batch-size 32
```

The promotion decision is stored in `..\models\cnn_acne_severity_v1\evaluation_report.json`. A metric win alone does not promote the model: unresolved subject identity, demographic coverage, licensing, or expert-label review blockers keep the status at `hold`.

The web scanner can also submit MediaPipe face landmarks. The service uses those landmarks to create adaptive forehead, cheek, nose, and chin polygon masks, with the older fixed boxes retained as a fallback.

Production loads the evaluated CPU TorchScript acne-severity model from
`../models/cnn_acne_severity_v1/model.torchscript.pt` when available. Override
the artifact or calibration temperature with:

```dotenv
SKIN_AI_TORCHSCRIPT_PATH=../models/cnn_acne_severity_v1/model.torchscript.pt
SKIN_AI_TORCHSCRIPT_TEMPERATURE=1.125
```

Camera captures may include up to three `frames` parts. Each frame is analyzed
independently and numeric signals are aggregated by median to reduce transient
camera noise. Zone metrics use eroded landmark masks, exclude facial features,
and are normalized relative to the same face.

## Endpoints

- `GET /health`
- `POST /analyze`

`POST /analyze` accepts multipart form data with an `image` file and returns:

```json
{
  "skin_type": "oily",
  "skin_type_confidence": 0.82,
  "concerns": [
    {
      "name": "redness",
      "confidence": 0.61,
      "severity": "mild"
    }
  ],
  "acne_severity": "mild",
  "skin_health_score": 74
}
```
