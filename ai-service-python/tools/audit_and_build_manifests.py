import argparse
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image, UnidentifiedImageError


LABELS = ["none", "mild", "moderate", "severe"]
LICENSE_ALLOWLIST = {"cc by 4.0"}


class UnionFind:
    def __init__(self, size: int) -> None:
        self.parent = list(range(size))

    def find(self, value: int) -> int:
        while self.parent[value] != value:
            self.parent[value] = self.parent[self.parent[value]]
            value = self.parent[value]
        return value

    def union(self, left: int, right: int) -> None:
        left_root, right_root = self.find(left), self.find(right)
        if left_root != right_root:
            self.parent[right_root] = left_root


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit Skino datasets and create leakage-resistant acne severity manifests.")
    parser.add_argument("--datasets-root", default="../datasets")
    parser.add_argument("--candidate-dir", default="../datasets/skino_acne_care_normal/prepared")
    parser.add_argument("--output-dir", default="../datasets/ml_release_v1")
    parser.add_argument("--seed", type=int, default=20260820)
    args = parser.parse_args()

    datasets_root = Path(args.datasets_root).resolve()
    candidate_dir = Path(args.candidate_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    inventory = inventory_metadata(datasets_root)
    rows = load_candidate_rows(candidate_dir)
    audit, manifests = audit_candidate(rows, candidate_dir, args.seed)
    audit["repository_inventory"] = inventory
    audit["demographic_coverage"] = demographic_coverage(datasets_root, inventory)
    audit["licensing_decision"] = licensing_decision(inventory, rows)

    for split, split_rows in manifests.items():
        write_csv(output_dir / f"acne_severity_{split}.csv", split_rows)

    with (output_dir / "dataset_audit.json").open("w", encoding="utf-8") as handle:
        json.dump(audit, handle, indent=2)
    with (output_dir / "manifest_summary.json").open("w", encoding="utf-8") as handle:
        json.dump(manifest_summary(manifests, audit), handle, indent=2)
    (output_dir / "DATASET_AUDIT.md").write_text(render_markdown(audit, manifests), encoding="utf-8")

    print(f"Audited {len(rows)} candidate rows.")
    print(f"Wrote audit and manifests to {output_dir}")


def inventory_metadata(datasets_root: Path) -> dict[str, object]:
    prepared_files = sorted(datasets_root.rglob("metadata_prepared.csv"))
    datasets = []
    all_licenses: Counter[str] = Counter()
    all_sources: Counter[str] = Counter()

    for metadata in prepared_files:
        rows = read_csv(metadata)
        licenses = Counter((row.get("license") or "missing").strip() for row in rows)
        sources = Counter((row.get("source") or "missing").strip() for row in rows)
        labels = Counter()
        for row in rows:
            if row.get("skin_type"):
                labels[f"skin_type:{row['skin_type']}"] += 1
            for concern in split_labels(row.get("concerns", "")):
                labels[f"concern:{concern}"] += 1
            if row.get("acne_severity"):
                labels[f"acne_severity:{row['acne_severity']}"] += 1
        all_licenses.update(licenses)
        all_sources.update(sources)
        datasets.append({
            "metadata": metadata.relative_to(datasets_root).as_posix(),
            "rows": len(rows),
            "columns": list(rows[0]) if rows else [],
            "licenses": dict(licenses),
            "sources": dict(sources),
            "labels": dict(labels),
        })

    image_files = list(datasets_root.rglob("*.jpg")) + list(datasets_root.rglob("*.jpeg")) + list(datasets_root.rglob("*.png"))
    return {
        "prepared_metadata_files": len(prepared_files),
        "image_files_on_disk": len(image_files),
        "datasets": datasets,
        "license_totals_across_prepared_copies": dict(all_licenses),
        "source_totals_across_prepared_copies": dict(all_sources),
        "note": "Totals include repeated prepared copies and are not unique-image counts.",
    }


def demographic_coverage(datasets_root: Path, inventory: dict[str, object]) -> dict[str, object]:
    prepared_columns = {
        column.lower()
        for dataset in inventory["datasets"]
        for column in dataset["columns"]
    }
    fitz_csv = next(iter(datasets_root.rglob("fitzpatrick17k.csv")), None)
    fitz_rows = len(read_csv(fitz_csv)) if fitz_csv else 0
    fitz_images = 0
    if fitz_csv:
        fitz_images = count_images(fitz_csv.parent)
    scin_root = next(iter(datasets_root.rglob("scin-main")), None)
    scin_case_csv = scin_root / "scin_cases.csv" if scin_root else None
    return {
        "prepared_age_fields": sorted(column for column in prepared_columns if column in {"age", "age_group", "age_band", "subject_age"}),
        "prepared_skin_tone_fields": sorted(column for column in prepared_columns if "fitz" in column or "tone" in column or "monk" in column),
        "fitzpatrick17k_metadata_rows": fitz_rows,
        "fitzpatrick17k_images_on_disk": fitz_images,
        "scin_case_metadata_present": bool(scin_case_csv and scin_case_csv.exists()),
        "scin_images_on_disk": count_images(scin_root) if scin_root else 0,
        "conclusion": "No trainable local dataset currently joins images to age and skin-tone labels.",
    }


def licensing_decision(inventory: dict[str, object], candidate_rows: list[dict[str, str]]) -> dict[str, object]:
    candidate_licenses = Counter((row.get("license") or "missing").strip() for row in candidate_rows)
    blocked = {
        license_name: count
        for license_name, count in inventory["license_totals_across_prepared_copies"].items()
        if license_name.lower() not in LICENSE_ALLOWLIST
    }
    candidate_allowed = all(name.lower() in LICENSE_ALLOWLIST for name in candidate_licenses)
    return {
        "candidate_licenses": dict(candidate_licenses),
        "candidate_allowed_for_experimental_training": candidate_allowed,
        "blocked_or_unverified_rows_across_prepared_copies": blocked,
        "fitzpatrick17k": "CC BY-NC-SA 3.0 metadata present; images absent; non-commercial restriction blocks normal product promotion.",
        "scin": "Custom SCIN Data Use License present; metadata/images absent; attribution and no-reidentification obligations apply.",
        "decision": "Use only CC BY 4.0 acne-care and normal-skin rows for this candidate.",
    }


def load_candidate_rows(candidate_dir: Path) -> list[dict[str, str]]:
    metadata = candidate_dir / "metadata_prepared.csv"
    rows = read_csv(metadata)
    prepared = []
    for row in rows:
        image_path = candidate_dir / row["image_path"]
        concerns = set(split_labels(row.get("concerns", "")))
        severity = row.get("acne_severity", "none").strip().lower()
        label = severity if "acne" in concerns and severity in LABELS[1:] else "none"
        prepared.append({
            **row,
            "resolved_path": str(image_path.resolve()),
            "repo_path": image_path.resolve().relative_to(candidate_dir.parents[2]).as_posix(),
            "label": label,
            "subject_proxy": subject_proxy(row["image_path"], row.get("source", "unknown")),
        })
    return prepared


def audit_candidate(rows: list[dict[str, str]], candidate_dir: Path, seed: int) -> tuple[dict[str, object], dict[str, list[dict[str, str]]]]:
    union = UnionFind(len(rows))
    by_proxy: dict[str, int] = {}
    by_sha: dict[str, int] = {}
    hashes: list[int | None] = []
    unreadable = []

    for index, row in enumerate(rows):
        proxy = row["subject_proxy"]
        if proxy in by_proxy:
            union.union(index, by_proxy[proxy])
        else:
            by_proxy[proxy] = index

        path = Path(row["resolved_path"])
        try:
            digest = sha256(path)
            if digest in by_sha:
                union.union(index, by_sha[digest])
            else:
                by_sha[digest] = index
            hashes.append(dhash(path))
        except (OSError, UnidentifiedImageError) as exc:
            hashes.append(None)
            unreadable.append({"image": row["repo_path"], "error": str(exc)})

    # A strict near-duplicate threshold catches resized/compressed copies while avoiding broad visual clustering.
    for left in range(len(rows)):
        if hashes[left] is None:
            continue
        for right in range(left + 1, len(rows)):
            if hashes[right] is not None and (hashes[left] ^ hashes[right]).bit_count() <= 2:
                union.union(left, right)

    groups: dict[int, list[int]] = defaultdict(list)
    for index in range(len(rows)):
        groups[union.find(index)].append(index)

    conflict_groups = []
    clean_groups: list[tuple[str, str, list[int]]] = []
    cross_split_groups = 0
    for members in groups.values():
        labels = {rows[index]["label"] for index in members}
        original_splits = {rows[index].get("split", "") for index in members}
        if len(original_splits) > 1:
            cross_split_groups += 1
        group_id = hashlib.sha1("|".join(sorted(rows[index]["repo_path"] for index in members)).encode()).hexdigest()[:12]
        if len(labels) != 1:
            conflict_groups.append({"subject_id": group_id, "labels": sorted(labels), "images": [rows[index]["repo_path"] for index in members]})
            continue
        clean_groups.append((group_id, next(iter(labels)), members))

    manifests = split_groups(clean_groups, rows, seed)
    exact_duplicate_groups = sum(1 for count in Counter(sha256(Path(row["resolved_path"])) for row in rows if Path(row["resolved_path"]).exists()).values() if count > 1)
    proxy_duplicate_groups = sum(1 for count in Counter(row["subject_proxy"] for row in rows).values() if count > 1)
    return {
        "candidate": "CC BY 4.0 acne severity (acne-care + normal-skin)",
        "candidate_dir": str(candidate_dir),
        "rows": len(rows),
        "label_counts": dict(Counter(row["label"] for row in rows)),
        "sources": dict(Counter(row.get("source", "") for row in rows)),
        "licenses": dict(Counter(row.get("license", "") for row in rows)),
        "unreadable_images": unreadable,
        "subject_group_method": "Roboflow augmentation-family filename proxy + exact SHA-256 + dHash Hamming distance <= 2",
        "subject_group_limitation": "This is not a verified person/case identifier; distinct photographs of the same person may cross splits.",
        "subject_groups": len(groups),
        "proxy_duplicate_groups": proxy_duplicate_groups,
        "exact_duplicate_groups": exact_duplicate_groups,
        "near_or_proxy_duplicate_groups": sum(1 for members in groups.values() if len(members) > 1),
        "groups_crossing_original_splits": cross_split_groups,
        "conflicting_duplicate_groups_excluded": len(conflict_groups),
        "conflict_examples": conflict_groups[:20],
        "manifest_counts": {split: len(split_rows) for split, split_rows in manifests.items()},
    }, manifests


def split_groups(groups: list[tuple[str, str, list[int]]], rows: list[dict[str, str]], seed: int) -> dict[str, list[dict[str, str]]]:
    import random

    randomizer = random.Random(seed)
    by_label: dict[str, list[tuple[str, str, list[int]]]] = defaultdict(list)
    for group in groups:
        by_label[group[1]].append(group)

    assignments: dict[str, str] = {}
    for label in LABELS:
        label_groups = by_label[label]
        randomizer.shuffle(label_groups)
        total_images = sum(len(group[2]) for group in label_groups)
        targets = {"train": total_images * 0.70, "validation": total_images * 0.15}
        counts = Counter()
        for group_id, _, members in sorted(label_groups, key=lambda item: len(item[2]), reverse=True):
            if counts["train"] < targets["train"]:
                split = "train"
            elif counts["validation"] < targets["validation"]:
                split = "validation"
            else:
                split = "test"
            assignments[group_id] = split
            counts[split] += len(members)

    manifests = {"train": [], "validation": [], "test": []}
    for group_id, label, members in groups:
        split = assignments[group_id]
        for index in members:
            row = rows[index]
            manifests[split].append({
                "image_path": row["repo_path"],
                "label": label,
                "label_index": str(LABELS.index(label)),
                "subject_id": group_id,
                "source": row.get("source", ""),
                "license": row.get("license", ""),
                "skin_tone": "",
                "age_group": "",
            })
    for split_rows in manifests.values():
        split_rows.sort(key=lambda row: (row["label_index"], row["subject_id"], row["image_path"]))
    return manifests


def manifest_summary(manifests: dict[str, list[dict[str, str]]], audit: dict[str, object]) -> dict[str, object]:
    subject_splits: dict[str, set[str]] = defaultdict(set)
    summary = {}
    for split, rows in manifests.items():
        for row in rows:
            subject_splits[row["subject_id"]].add(split)
        summary[split] = {
            "images": len(rows),
            "subjects": len({row["subject_id"] for row in rows}),
            "labels": dict(Counter(row["label"] for row in rows)),
        }
    summary["subject_leakage_groups"] = sum(1 for splits in subject_splits.values() if len(splits) > 1)
    summary["seed"] = 20260820
    summary["promotion_blockers"] = [
        "No verified person/case identifier; subject separation is an augmentation-family proxy.",
        "No joined age or skin-tone labels for candidate images.",
        "No dermatologist re-review of the combined candidate labels inside this project.",
    ]
    return summary


def render_markdown(audit: dict[str, object], manifests: dict[str, list[dict[str, str]]]) -> str:
    coverage = audit["demographic_coverage"]
    licensing = audit["licensing_decision"]
    lines = [
        "# Skino dataset audit",
        "",
        "## Candidate decision",
        "",
        f"- Candidate rows: {audit['rows']}",
        f"- Labels: `{json.dumps(audit['label_counts'], sort_keys=True)}`",
        f"- Licenses: `{json.dumps(audit['licenses'], sort_keys=True)}`",
        f"- Subject grouping: {audit['subject_group_method']}",
        f"- Limitation: {audit['subject_group_limitation']}",
        f"- Duplicate/proxy groups: {audit['near_or_proxy_duplicate_groups']}",
        f"- Groups crossing the old splits: {audit['groups_crossing_original_splits']}",
        f"- Conflicting duplicate groups excluded: {audit['conflicting_duplicate_groups_excluded']}",
        "",
        "## Demographic coverage",
        "",
        f"- Prepared age fields: `{coverage['prepared_age_fields']}`",
        f"- Prepared skin-tone fields: `{coverage['prepared_skin_tone_fields']}`",
        f"- Fitzpatrick17k metadata rows/images: {coverage['fitzpatrick17k_metadata_rows']}/{coverage['fitzpatrick17k_images_on_disk']}",
        f"- SCIN case metadata present/images: {coverage['scin_case_metadata_present']}/{coverage['scin_images_on_disk']}",
        f"- Conclusion: {coverage['conclusion']}",
        "",
        "## Licensing",
        "",
        f"- Candidate: `{json.dumps(licensing['candidate_licenses'])}`",
        f"- Decision: {licensing['decision']}",
        f"- Fitzpatrick17k: {licensing['fitzpatrick17k']}",
        f"- SCIN: {licensing['scin']}",
        "",
        "## New splits",
        "",
    ]
    for split, rows in manifests.items():
        lines.append(f"- {split}: {len(rows)} images, {len({row['subject_id'] for row in rows})} proxy subjects, `{dict(Counter(row['label'] for row in rows))}`")
    lines.extend([
        "",
        "## Release blockers",
        "",
        "1. Obtain verified case/person IDs or an authoritative grouping key.",
        "2. Join candidate images to consented age-band and skin-tone metadata and evaluate each subgroup.",
        "3. Obtain dermatologist review of the exact labels used for training and evaluation.",
        "4. Keep sources with undefined/unspecified licenses out of deployable training.",
    ])
    return "\n".join(lines) + "\n"


def subject_proxy(image_path: str, source: str) -> str:
    name = Path(image_path).stem.lower()
    name = re.sub(r"-[0-9a-f]{12}$", "", name)
    name = re.sub(r"_(jpg|jpeg|png)\.rf\.[0-9a-f]+$", "", name)
    name = re.sub(r"^skino_(acne_care|normal_skin)_(train|valid|validation|test)_", "", name)
    return f"{source.lower()}:{name}"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def dhash(path: Path) -> int:
    with Image.open(path) as image:
        pixels = list(image.convert("L").resize((9, 8), Image.Resampling.LANCZOS).getdata())
    value = 0
    for row in range(8):
        for column in range(8):
            value = (value << 1) | int(pixels[(row * 9) + column] > pixels[(row * 9) + column + 1])
    return value


def split_labels(value: str) -> list[str]:
    return [item.strip().lower() for item in value.replace(",", ";").split(";") if item.strip()]


def count_images(root: Path | None) -> int:
    if not root or not root.exists():
        return 0
    return sum(1 for path in root.rglob("*") if path.suffix.lower() in {".jpg", ".jpeg", ".png"})


def read_csv(path: Path | None) -> list[dict[str, str]]:
    if not path or not path.exists():
        return []
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    fieldnames = ["image_path", "label", "label_index", "subject_id", "source", "license", "skin_tone", "age_group"]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
