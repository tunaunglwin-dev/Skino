# Data Privacy and Learning Pipeline Foundation

## Principle

More users should make Skino smarter only when users clearly consent and the training data is reviewed. Raw uploads must not go straight into model training.

## Current Implementation

- Guest scans are analyzed but not saved.
- Authenticated scans save a private analysis history item.
- Every saved scan creates a `skin_analysis_images` privacy record.
- Model-improvement consent is stored in `ai_training_consents`.
- If consent is granted, the scan creates a `model_training_samples` queue item.
- Training samples are marked `pending` review and `queued`, not immediately exported.
- `model_versions` exists to track trained/deployed model versions later.

## User Consent

Current consent type:

- `model_training`: allows future eligible scans to enter the learning review queue.

Policy version:

- `2026-07-24`

Users can grant or revoke consent through:

- `GET /api/privacy/model-training-consent`
- `PUT /api/privacy/model-training-consent`

Mobile implementation:

- Settings shows an **AI learning privacy** control for logged-in users.
- The setting is fetched after login.
- Toggling the setting updates the backend consent record.
- The Scan page opt-in checkbox follows the same consent state.
- Guest users see that login is required before any scan can be shared for model improvement.

## Data Flow

1. User uploads scan.
2. Laravel validates image type and size.
3. Python AI service analyzes image.
4. Authenticated scan is saved to `skin_analyses`.
5. Image storage metadata is saved to `skin_analysis_images`.
6. If consent exists or `allow_model_training=true`, a `model_training_samples` record is created.
7. Admin/specialist review should approve, reject, or correct labels before training export.
8. A future training job creates a dataset snapshot and records a `model_versions` row.

## Privacy Rules

- Do not train from guest scans.
- Do not train from private scans.
- Do not export names, emails, Google IDs, phone numbers, or contacts into training datasets.
- Use `skin_analysis_id` only as an internal trace key.
- Admin access and future exports should be audited.
- Users should later be able to delete scan history and revoke future training use.

## Next Improvements

- Add image preview with privacy-safe signed URLs for approved reviewers.
- Add user-facing privacy screen in Settings.
- Add delete/export personal data endpoints.
- Add model version deployment controls.
- Add specialist-corrected labels as higher quality training data.

## Admin Training Review

Implemented admin endpoints:

- `GET /api/admin/training-samples`
- `GET /api/admin/training-samples/{trainingSample}`
- `POST /api/admin/training-samples/{trainingSample}/review`

Review actions:

- `approve`: marks sample reviewed and approved for training.
- `reject`: excludes sample from training.
- `correct`: stores corrected labels and approves the sample.
- `needs_specialist`: keeps the sample queued but marks it for specialist review.

The admin dashboard includes an **AI Learning Review** module connected to these endpoints.
