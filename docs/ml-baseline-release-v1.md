# ML baseline release v1

Date: 2026-08-20

## Outcome

The MobileNetV3-Small candidate beat the existing image-metric analyzer on the locked test manifest, but it was **not promoted**. The promotion gate is `hold` because the project does not yet have verified subject IDs, joined age/skin-tone metadata, or dermatologist re-review of the combined labels.

This is an experimental acne-severity classifier and must not be represented as a diagnosis model.

## Dataset audit

- Candidate: 3,049 CC BY 4.0 images from the locally prepared acne-care and normal-skin sources.
- Labels: none 2,564; mild 201; moderate 132; severe 152.
- Duplicate/augmentation-family groups: 933.
- Conflicting duplicate groups excluded: 7.
- Old split crossings discovered: 499 groups.
- New split leakage: zero proxy-subject crossings.
- Train: 2,121 images / 664 proxy subjects.
- Validation: 459 images / 169 proxy subjects.
- Test: 441 images / 224 proxy subjects.
- Demographic audit: no candidate image is joined to age or skin-tone metadata.
- Fitzpatrick17k: metadata exists locally but images do not; its local license is CC BY-NC-SA 3.0, so it is excluded from normal product promotion.
- SCIN: its local custom license exists, but case metadata and images do not; it is excluded.
- Sources with undefined or unspecified licenses are excluded from this release candidate.

The grouping key combines the normalized Roboflow source filename, exact SHA-256 duplicates, and perceptual dHash neighbors. It is only a proxy: different photos of the same person can still cross splits.

## Held-out results

| Metric | CNN candidate | Existing analyzer |
|---|---:|---:|
| Accuracy | 0.850 | 0.608 |
| Balanced accuracy | 0.431 | 0.344 |
| Macro-F1 | 0.434 | 0.228 |
| Expected calibration error | 0.053 | not available |
| Multiclass Brier score | 0.218 | not available |

Candidate per-class precision / recall:

| Class | Precision | Recall | F1 | Support |
|---|---:|---:|---:|---:|
| none | 0.938 | 0.945 | 0.941 | 381 |
| mild | 0.217 | 0.192 | 0.204 | 26 |
| moderate | 0.222 | 0.235 | 0.229 | 17 |
| severe | 0.375 | 0.353 | 0.364 | 17 |

The candidate clears the numerical comparison gate, but minority-class recall remains too weak for a user-facing medical-style claim.

## Artifacts

- Dataset audit: `datasets/ml_release_v1/DATASET_AUDIT.md`
- Machine-readable audit: `datasets/ml_release_v1/dataset_audit.json`
- Split summary: `datasets/ml_release_v1/manifest_summary.json`
- Manifests: `datasets/ml_release_v1/acne_severity_{train,validation,test}.csv`
- Evaluation: `models/cnn_acne_severity_v1/evaluation_report.json`
- Predictions: `models/cnn_acne_severity_v1/test_predictions.csv`
- Confusion matrices: `models/cnn_acne_severity_v1/confusion_matrix*.png`
- Calibration plot: `models/cnn_acne_severity_v1/reliability_diagram.png`
- Candidate weights: `models/cnn_acne_severity_v1/model.pt` and `model.torchscript.pt`

The weights are stored as evaluation artifacts only. The runtime model path was not changed.

## Face-zone reliability

The web scanner now runs MediaPipe Face Detector and Face Landmarker. It forwards normalized landmarks through Laravel to the AI service, which builds polygon masks for the forehead, left cheek, right cheek, nose, and chin. Uploaded photographs use the same flow. If landmark loading or detection fails, analysis falls back to fixed relative boxes instead of failing the scan.

This is landmark-guided polygon segmentation, not a trained semantic skin-segmentation model.

## Next tasks required before promotion

1. Add a stable, verified person/case ID to every image, then rebuild all manifests.
2. Collect consented age-band, Fitzpatrick or Monk skin-tone, device, and lighting metadata joined to each candidate image.
3. Have dermatologists re-label the exact candidate set with a written rubric and adjudicate disagreements.
4. Increase mild/moderate/severe subject counts and retrain with class-balanced sampling or focal loss.
5. Report subgroup recall, false-negative rates, and calibration by skin tone, age band, device, and lighting.
6. Add a dedicated skin/occlusion segmentation model and quantify zone-mask quality against manually reviewed masks.
7. Re-run the locked promotion gate. Promote only if the new candidate still beats the existing baseline and all release blockers are closed.
