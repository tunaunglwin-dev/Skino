# Skino Custom Model Training Plan

This project should train in two stages.

## Stage 1: Baseline Model

The current baseline model uses image metrics extracted from face/skin images:

- brightness
- saturation
- redness ratio
- dark spot ratio
- highlight/oil ratio
- texture score
- skin coverage

It trains a nearest-centroid classifier for:

- skin type: `normal`, `oily`, `dry`, `combination`, `sensitive`
- concerns: `acne`, `dark_spots`, `oiliness`, `dryness`, `redness`

This is intentionally lightweight. It works on CPU and does not require GPU, PyTorch, or TensorFlow.

## Stage 2: Deep Learning Model

After enough real Myanmar-user data exists, replace the baseline with a CNN or vision transformer model.

Do not start here unless the dataset is strong enough. A deep model with weak labels will look impressive but behave badly.

## Dataset Folder Format

Put raw images here:

```text
datasets/skino/raw/
```

Create this metadata file:

```text
datasets/skino/raw/metadata.csv
```

Required columns:

```csv
image_path,split,skin_type,concerns,source,license,consent
```

Example:

```csv
person001_front.jpg,train,oily,acne;oiliness,own_collection,private_consent,yes
person002_front.jpg,validation,dry,dryness,own_collection,private_consent,yes
person003_front.jpg,test,combination,dark_spots;oiliness,own_collection,private_consent,yes
person004_front.jpg,train,normal,healthy,own_collection,private_consent,yes
```

## Label Rules

Use one skin type per image:

- `normal`
- `oily`
- `dry`
- `combination`
- `sensitive`

Use zero or more concerns per image:

- `acne`
- `dark_spots`
- `oiliness`
- `dryness`
- `redness`

Separate multiple concerns with `;`.

For healthy or clear skin, set `skin_type` to `normal` and leave `concerns` blank, or use one of these aliases:

- `healthy`
- `clear`
- `none`
- `no_concern`
- `no_concerns`

The prepare/training tools normalize those aliases to no concern. These rows are important negative examples: they teach the concern model what a clear face looks like, so acne does not fire on healthy skin.

## Healthy/Normal First Pass

Before retraining acne, collect normal healthy face images first:

- target at least 20 clear `normal` images for a proof baseline
- better target 100+ clear `normal` images across ages, genders, lighting, and Myanmar skin tones
- include front-facing and mild side-angle photos, but avoid makeup filters, heavy beauty retouching, screenshots, and drawn annotations
- keep consent/licensing clear in the metadata

Prepare the dataset:

```powershell
cd ai-service-python
python tools/prepare_dataset.py --raw-dir ../datasets/skino/raw --output-dir ../datasets/skino/prepared
```

Train a skin-type-only baseline when healthy/normal is the first available class set:

```powershell
python tools/train_skin_model.py --dataset-dir ../datasets/skino/prepared --output ../models/skino_normal_baseline_model.json --report ../models/skino_normal_baseline_report.json --skin-type-only
```

When acne and clear/healthy examples are both available, retrain the acne concern model with the healthy rows included. Healthy rows should stay in the metadata with blank/healthy concerns because the trainer uses them as negative examples for acne:

```powershell
python tools/train_skin_model.py --dataset-dir ../datasets/skino/prepared --output ../models/skino_acne_model.json --report ../models/skino_acne_model.report.json --concern-only
```

## Minimum Data Target

For the first real model:

- at least 20 images per skin type
- at least 20 images per concern

For a hackathon-quality demo:

- 50-100 images per skin type is better
- 50-100 images per concern is better

For a production-quality model:

- hundreds to thousands per class
- balanced lighting, age range, gender, and phone camera variation
- clear consent and privacy handling

## Commands

Prepare raw data:

```bash
cd ai-service-python
python tools/prepare_dataset.py --raw-dir ../datasets/skino/raw --output-dir ../datasets/skino/prepared
```

Train baseline model:

```bash
python tools/train_skin_model.py --dataset-dir ../datasets/skino/prepared --output ../models/skino_baseline_model.json --report ../models/skino_baseline_report.json
```

For a tiny proof-of-concept only:

```bash
python tools/train_skin_model.py --dataset-dir ../datasets/samples/prepared --output ../models/sample_skin_model.json --report ../models/sample_skin_model.report.json --allow-small
```

Run FastAPI with trained model:

```bash
set SKIN_AI_MODEL_PATH=../models/skino_baseline_model.json
uvicorn app.main:app --host 127.0.0.1 --port 5000
```

## Importing ACNE04-v2

The `datasets/acne04v2` repo contains annotation JSON, not the full raw image dataset.
It is useful for acne labels only.

Expected original image folder:

```text
datasets/acne04v2/ACNE04/Classification/JPEGImages/
```

Import command:

```bash
cd ai-service-python
python tools/import_acne04v2.py --annotations ../datasets/acne04v2/Acne04-v2_annotations.json --images-dir ../datasets/acne04v2/ACNE04/Classification/JPEGImages --output-dir ../datasets/skino/raw --source acne04v2 --license citation_required --consent research_dataset
```

The importer writes:

```text
datasets/skino/raw/metadata_acne04v2.csv
datasets/skino/raw/import_acne04v2_report.json
```

Do not train on `datasets/acne04v2/examples/`. Those images contain drawn annotation circles and will contaminate the model.

ACNE04-v2 cannot train all Skino classes by itself:

- useful: `acne`, partially `redness`
- not enough: `normal`, `oily`, `dry`, `combination`, `sensitive`, `dark_spots`, `oiliness`, `dryness`

## Importing Acne Care

`datasets/acne_care` is a Roboflow multi-label classification dataset with these labels:

- `nodule`
- `papule`
- `pustule`
- `non acne`

Import and prepare it:

```powershell
cd ai-service-python
python tools/import_acne_care.py --dataset-dir ../datasets/acne_care --output-dir ../datasets/skino_acne_care/raw --source roboflow_acne_care --license "CC BY 4.0" --consent research_dataset
python tools/prepare_dataset.py --raw-dir ../datasets/skino_acne_care/raw --metadata metadata_roboflow_acne_care.csv --output-dir ../datasets/skino_acne_care/prepared
```

The importer creates a heuristic `acne_severity` label:

- `none`
- `mild`
- `moderate`
- `severe`

The dataset is useful for hackathon acne-care demos, but it has noisy labels. Some rows contain both `non acne` and acne labels. The importer treats those rows as acne, preserves `original_labels`, and counts contradictions in the import report.

Current prepared counts:

- `none`: 196
- `mild`: 201
- `moderate`: 132
- `severe`: 152

Merge with healthy normal skin for scanner training:

```powershell
python tools/merge_prepared_datasets.py --input ../datasets/skino_acne_care/prepared --input ../datasets/normal_skin/prepared --output-dir ../datasets/skino_acne_care_normal/prepared
python tools/train_skin_model.py --dataset-dir ../datasets/skino_acne_care_normal/prepared --output ../models/skino_acne_care_normal_model.json --report ../models/skino_acne_care_normal_model.report.json --concern-only --allow-small
```

## Automatic Draft Severity Dataset

For a quick hackathon baseline, build a balanced draft dataset before manual review is complete:

```powershell
cd ai-service-python
python tools/build_demo_severity_dataset.py --per-class 100
python tools/prepare_dataset.py --raw-dir ../datasets/skino_demo_severity_auto/raw --output-dir ../datasets/skino_demo_severity_auto/prepared
python tools/train_skin_model.py --dataset-dir ../datasets/skino_demo_severity_auto/prepared --output ../models/skino_demo_severity_auto_model.json --report ../models/skino_demo_severity_auto_model.report.json --concern-only --allow-small
```

This writes 100 images each for:

- `normal`
- `mild`
- `moderate`
- `severe`

The builder excludes acne rows that also contain the contradictory `non acne` label. This is faster than manual review, but still not as trustworthy as a human-reviewed dataset.

## Manual Severity Review

Before retraining the hackathon demo model again, build a smaller clean dataset by manually reviewing images. The review tool shows one image at a time and writes selected labels into:

```text
datasets/skino_demo_severity/raw/metadata.csv
```

Start the review tool:

```powershell
cd ai-service-python
python tools/review_severity_dataset.py
```

Then open:

```text
http://127.0.0.1:8765
```

Use these labels:

- `Normal`: clear/healthy skin
- `Mild`: small visible acne, limited inflammation
- `Moderate`: obvious acne, multiple papules/pustules
- `Severe`: widespread, nodular, painful-looking, or specialist-worthy acne
- `Skip`: blurry, confusing, duplicate-looking, bad crop, wrong label, heavy makeup/filter, or uncertain severity

Keyboard shortcuts:

- `1`: Normal
- `2`: Mild
- `3`: Moderate
- `4`: Severe
- `S`: Skip

Hackathon target:

- 100 clean normal images
- 100 clean mild images
- 100 clean moderate images
- 100 clean severe images

After review, prepare and train the clean demo model:

```powershell
python tools/prepare_dataset.py --raw-dir ../datasets/skino_demo_severity/raw --output-dir ../datasets/skino_demo_severity/prepared
python tools/train_skin_model.py --dataset-dir ../datasets/skino_demo_severity/prepared --output ../models/skino_demo_severity_model.json --report ../models/skino_demo_severity_model.report.json --concern-only --allow-small
```

## Current Limitation

The baseline model is not medical diagnosis. It is a trainable product model for skincare guidance. Dermatologist referral should remain part of the app for severe or uncertain cases.
