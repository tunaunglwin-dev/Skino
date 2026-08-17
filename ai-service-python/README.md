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
