# API Contract Draft

## Laravel Backend

All protected mobile endpoints use Sanctum bearer tokens:

```http
Authorization: Bearer <token>
Accept: application/json
```

### `POST /api/auth/register`

Creates a mobile user account. The role is always assigned by the server as `user`.

```json
{
  "name": "Mobile User",
  "email": "mobile@example.com",
  "password": "Secure123",
  "password_confirmation": "Secure123"
}
```

### `POST /api/auth/login`

Returns the authenticated user and token.

```json
{
  "email": "mobile@example.com",
  "password": "Secure123"
}
```

### `GET /api/me`

Returns the authenticated user.

### `GET /api/privacy/model-training-consent`

Returns the authenticated user's current model-improvement consent. Default is not granted.

```json
{
  "data": {
    "consent_type": "model_training",
    "policy_version": "2026-07-24",
    "granted": false,
    "granted_at": null,
    "revoked_at": null
  }
}
```

### `PUT /api/privacy/model-training-consent`

Updates consent for using future scans in the AI learning pipeline.

```json
{
  "granted": true
}
```

### `POST /api/auth/logout`

Revokes the active API token.

### `POST /api/guest/skin-analysis`

Public guest scan endpoint. It accepts the same multipart image upload as the authenticated scan endpoint, but it does not save history and does not require login.

- `image`: required JPG, PNG, or WebP image, max 8 MB

Returns:

```json
{
  "data": {
    "id": null,
    "skin_type": "normal",
    "skin_type_confidence": 0.74,
    "concerns": [],
    "acne_severity": "none",
    "skin_health_score": 90,
    "beauty_routine": {
      "key": "normal",
      "name": "Daily Glow Maintenance",
      "steps": ["gentle cleanser", "light moisturizer", "broad-spectrum sunscreen"],
      "follow_up_days": 30,
      "reason": "Matched to normal skin maintenance."
    },
    "guest_mode": true,
    "login_required_for": ["save_history", "progress_tracking", "appointments"]
  }
}
```

### `GET /api/admin/me`

Admin-only route used to verify role middleware.

### `GET /api/admin/training-samples`

Admin-only queue of consented samples waiting for review. Supports:

- `review_status`: `pending`, `approved`, `rejected`, `needs_specialist`
- `training_status`
- `per_page`

### `POST /api/admin/training-samples/{id}/review`

Admin-only review action.

```json
{
  "action": "correct",
  "corrected_labels": {
    "skin_type": "combination",
    "acne_severity": "mild",
    "concerns": ["acne", "dark_spots"]
  },
  "review_note": "Severity looked milder than model prediction."
}
```

### Admin CRM

Admin-only CRM endpoints:

- `GET /api/admin/crm-records`
- `POST /api/admin/crm-records`
- `GET /api/admin/crm-records/{crmRecord}`
- `PUT /api/admin/crm-records/{crmRecord}`
- `POST /api/admin/crm-records/{crmRecord}/notes`

CRM records are contact-linked appointment/opportunity records. They do not duplicate user identity data from Contacts.

### `GET /api/skin-analyses`

Returns the authenticated user's skin analysis history.

### `POST /api/skin-analyses`

Accepts multipart form data:

- `image`: required JPG, PNG, or WebP image, max 8 MB
- `allow_model_training`: optional boolean. When true, the scan image/result can enter the review queue for improving future AI models.

Laravel sends the image to the Python AI service, stores the result, calculates product recommendations, and returns:

```json
{
  "data": {
    "id": 1,
    "skin_type": "oily",
    "skin_type_confidence": "0.8200",
    "concerns": [
      {
        "name": "acne",
        "confidence": 0.76,
        "severity": "moderate"
      }
    ],
    "acne_severity": "moderate",
    "skin_health_score": 68,
    "created_at": "2026-06-10T14:41:05.000000Z",
    "privacy": {
      "image_privacy_status": "training_allowed",
      "training_queued": true
    },
    "recommended_products": [
      {
        "slug": "gentle-gel-cleanser",
        "name": "Gentle Gel Cleanser"
      }
    ]
  }
}
```

Privacy behavior:

- Guest scans are not saved.
- Authenticated scans are saved for user history.
- Authenticated scans are private by default.
- A scan only enters `model_training_samples` when model-training consent is granted or `allow_model_training=true` is sent with that scan.
- Training samples store anonymized metadata and require review before export/training.

### `GET /api/skin-analyses/{id}`

Returns one of the authenticated user's previous analyses with fresh recommendations.

## AI Service

Laravel sends an uploaded image to the Python AI service. The AI service should keep the same response shape whether it is using mock logic, an external AI API, or a trained local model.

### `GET /health`

Returns service status.

```json
{
  "status": "ok",
  "service": "skin-ai-service"
}
```

### `POST /analyze`

Accepts multipart form data:

- `image`: uploaded skin image

Returns:

```json
{
  "skin_type": "oily",
  "skin_type_confidence": 0.82,
  "concerns": [
    {
      "name": "acne",
      "confidence": 0.76,
      "severity": "moderate"
    },
    {
      "name": "dark_spots",
      "confidence": 0.61,
      "severity": "mild"
    }
  ],
  "acne_severity": "moderate",
  "skin_health_score": 68
}
```
