import argparse
import csv
import hashlib
import json
import mimetypes
import shutil
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse


LABELS = {"normal", "mild", "moderate", "severe", "skip"}
OUTPUT_FIELDNAMES = [
    "image_path",
    "split",
    "skin_type",
    "concerns",
    "acne_severity",
    "source",
    "license",
    "consent",
    "original_source",
    "original_labels",
]


@dataclass(frozen=True)
class Candidate:
    key: str
    dataset_dir: Path
    image_path: Path
    source_image_path: str
    split: str
    suggestion: str
    source: str
    license: str
    consent: str
    original_labels: str


class ReviewStore:
    def __init__(self, candidates: list[Candidate], output_dir: Path) -> None:
        self.candidates = candidates
        self.candidate_by_key = {candidate.key: candidate for candidate in candidates}
        self.output_dir = output_dir
        self.raw_dir = output_dir / "raw"
        self.images_dir = self.raw_dir / "images"
        self.metadata_path = self.raw_dir / "metadata.csv"
        self.state_path = output_dir / "review_state.json"
        self.images_dir.mkdir(parents=True, exist_ok=True)
        self.state = self._load_state()
        self._rebuild_metadata()

    def next_candidate(self) -> Candidate | None:
        reviewed = self.state["reviewed"]
        for candidate in self.candidates:
            if candidate.key not in reviewed:
                return candidate
        return None

    def label(self, key: str, label: str) -> dict[str, object]:
        if label not in LABELS:
            raise ValueError(f"Unsupported label: {label}")
        if key not in self.candidate_by_key:
            raise KeyError(f"Unknown candidate: {key}")

        candidate = self.candidate_by_key[key]
        entry: dict[str, object] = {
            "label": label,
            "candidate": candidate_to_payload(candidate),
        }

        if label != "skip":
            output_name = self._copy_candidate(candidate, label)
            entry["output_name"] = output_name
            entry["metadata_row"] = metadata_row(candidate, label, output_name)

        self.state["reviewed"][key] = entry
        self._save_state()
        self._rebuild_metadata()

        return self.stats()

    def stats(self) -> dict[str, object]:
        counts = {label: 0 for label in sorted(LABELS)}
        for entry in self.state["reviewed"].values():
            label = str(entry["label"])
            counts[label] = counts.get(label, 0) + 1

        selected = sum(counts[label] for label in counts if label != "skip")
        return {
            "total": len(self.candidates),
            "reviewed": len(self.state["reviewed"]),
            "remaining": len(self.candidates) - len(self.state["reviewed"]),
            "selected": selected,
            "counts": counts,
            "metadata_path": str(self.metadata_path),
        }

    def _copy_candidate(self, candidate: Candidate, label: str) -> str:
        suffix = candidate.image_path.suffix.lower() or ".jpg"
        digest = stable_digest(f"{candidate.key}:{candidate.image_path.name}")[:12]
        output_name = f"{label}_{digest}{suffix}"
        output_path = self.images_dir / output_name
        if not output_path.exists():
            shutil.copy2(candidate.image_path, output_path)
        return output_name

    def _load_state(self) -> dict[str, object]:
        if not self.state_path.exists():
            return {"reviewed": {}}

        with self.state_path.open("r", encoding="utf-8") as handle:
            payload = json.load(handle)

        if "reviewed" not in payload or not isinstance(payload["reviewed"], dict):
            return {"reviewed": {}}

        return payload

    def _save_state(self) -> None:
        self.output_dir.mkdir(parents=True, exist_ok=True)
        with self.state_path.open("w", encoding="utf-8") as handle:
            json.dump(self.state, handle, indent=2)

    def _rebuild_metadata(self) -> None:
        rows = [
            entry["metadata_row"]
            for entry in self.state["reviewed"].values()
            if entry.get("metadata_row")
        ]
        self.metadata_path.parent.mkdir(parents=True, exist_ok=True)
        with self.metadata_path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=OUTPUT_FIELDNAMES)
            writer.writeheader()
            writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Review and relabel skin images into a clean acne severity dataset.")
    parser.add_argument(
        "--source",
        action="append",
        default=[],
        help="Prepared dataset directory containing metadata_prepared.csv. Repeat for multiple sources.",
    )
    parser.add_argument(
        "--output-dir",
        default="../datasets/skino_demo_severity",
        help="Output dataset directory. The tool writes raw/images and raw/metadata.csv inside it.",
    )
    parser.add_argument("--host", default="127.0.0.1", help="Review server host.")
    parser.add_argument("--port", type=int, default=8765, help="Review server port.")
    args = parser.parse_args()

    root_dir = Path(__file__).resolve().parents[2]
    sources = [Path(item).resolve() for item in args.source]
    if not sources:
        sources = [
            root_dir / "datasets" / "normal_skin" / "prepared",
            root_dir / "datasets" / "skino_acne_care" / "prepared",
        ]

    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = (Path.cwd() / output_dir).resolve()

    candidates = load_candidates(sources)
    store = ReviewStore(candidates, output_dir)
    handler = make_handler(store)
    server = ThreadingHTTPServer((args.host, args.port), handler)

    print(f"Loaded {len(candidates)} candidate image(s).")
    print(f"Writing clean dataset to: {store.raw_dir}")
    print(f"Open http://{args.host}:{args.port}")
    server.serve_forever()


def load_candidates(sources: list[Path]) -> list[Candidate]:
    candidates: list[Candidate] = []
    for dataset_dir in sources:
        metadata_path = dataset_dir / "metadata_prepared.csv"
        if not metadata_path.exists():
            raise SystemExit(f"Missing prepared metadata: {metadata_path}")

        with metadata_path.open("r", newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                image_path = dataset_dir / row.get("image_path", "")
                if not image_path.exists():
                    continue

                source_image_path = row.get("image_path", "")
                key = stable_digest(f"{dataset_dir}:{source_image_path}")
                candidates.append(
                    Candidate(
                        key=key,
                        dataset_dir=dataset_dir,
                        image_path=image_path,
                        source_image_path=source_image_path,
                        split=normalize_split(row.get("split", "")),
                        suggestion=suggest_label(row),
                        source=row.get("source", dataset_dir.parent.name).strip() or dataset_dir.parent.name,
                        license=row.get("license", "").strip(),
                        consent=row.get("consent", "").strip(),
                        original_labels=row.get("original_labels", "").strip(),
                    )
                )

    return sorted(candidates, key=candidate_sort_key)


def candidate_sort_key(candidate: Candidate) -> tuple[int, str, str]:
    priority = {
        "normal": 0,
        "severe": 1,
        "moderate": 2,
        "mild": 3,
        "skip": 4,
    }.get(candidate.suggestion, 5)
    return priority, candidate.split, candidate.key


def normalize_split(value: str) -> str:
    split = value.strip().lower()
    if split == "valid":
        return "validation"
    if split in {"train", "validation", "test", "calibration"}:
        return split
    return "train"


def suggest_label(row: dict[str, str]) -> str:
    severity = row.get("acne_severity", "").strip().lower()
    if severity in {"mild", "moderate", "severe"}:
        return severity

    concerns = {item.strip() for item in row.get("concerns", "").replace(",", ";").split(";") if item.strip()}
    skin_type = row.get("skin_type", "").strip().lower()
    if "acne" not in concerns and skin_type == "normal":
        return "normal"

    return "skip"


def metadata_row(candidate: Candidate, label: str, output_name: str) -> dict[str, str]:
    is_normal = label == "normal"
    return {
        "image_path": str(Path("images") / output_name).replace("\\", "/"),
        "split": candidate.split,
        "skin_type": "normal" if is_normal else "",
        "concerns": "healthy" if is_normal else "acne",
        "acne_severity": "none" if is_normal else label,
        "source": "manual_review_demo_severity",
        "license": candidate.license,
        "consent": candidate.consent,
        "original_source": f"{candidate.dataset_dir}|{candidate.source_image_path}",
        "original_labels": candidate.original_labels,
    }


def make_handler(store: ReviewStore) -> type[BaseHTTPRequestHandler]:
    class ReviewHandler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path == "/":
                self._send_text(INDEX_HTML, "text/html; charset=utf-8")
                return
            if parsed.path == "/api/state":
                self._send_json(store.stats())
                return
            if parsed.path == "/api/next":
                candidate = store.next_candidate()
                self._send_json({"candidate": candidate_to_payload(candidate) if candidate else None, "stats": store.stats()})
                return
            if parsed.path == "/image":
                query = parse_qs(parsed.query)
                key = query.get("key", [""])[0]
                self._send_image(key)
                return

            self.send_error(HTTPStatus.NOT_FOUND)

        def do_POST(self) -> None:
            parsed = urlparse(self.path)
            if parsed.path != "/api/label":
                self.send_error(HTTPStatus.NOT_FOUND)
                return

            try:
                length = int(self.headers.get("Content-Length", "0"))
                payload = json.loads(self.rfile.read(length) or b"{}")
                stats = store.label(str(payload.get("key", "")), str(payload.get("label", "")))
            except (KeyError, ValueError, json.JSONDecodeError) as exc:
                self._send_json({"error": str(exc)}, HTTPStatus.BAD_REQUEST)
                return

            self._send_json({"ok": True, "stats": stats})

        def log_message(self, format: str, *args: object) -> None:
            return

        def _send_image(self, key: str) -> None:
            candidate = store.candidate_by_key.get(key)
            if not candidate:
                self.send_error(HTTPStatus.NOT_FOUND)
                return

            content_type = mimetypes.guess_type(candidate.image_path.name)[0] or "application/octet-stream"
            data = candidate.image_path.read_bytes()
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _send_json(self, payload: object, status: HTTPStatus = HTTPStatus.OK) -> None:
            data = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _send_text(self, payload: str, content_type: str) -> None:
            data = payload.encode("utf-8")
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    return ReviewHandler


def candidate_to_payload(candidate: Candidate | None) -> dict[str, object] | None:
    if candidate is None:
        return None

    return {
        "key": candidate.key,
        "image_url": f"/image?key={candidate.key}",
        "split": candidate.split,
        "suggestion": candidate.suggestion,
        "source": candidate.source,
        "license": candidate.license,
        "consent": candidate.consent,
        "original_labels": candidate.original_labels,
        "source_image_path": candidate.source_image_path,
        "dataset": str(candidate.dataset_dir),
    }


def stable_digest(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


INDEX_HTML = r"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Skino Severity Review</title>
  <style>
    :root {
      color-scheme: light;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #f8f5ef;
      color: #26221d;
    }
    body {
      margin: 0;
      min-height: 100vh;
      background: linear-gradient(135deg, #fbf9f4 0%, #fff2ea 54%, #eaf6f1 100%);
    }
    main {
      width: min(1160px, calc(100vw - 32px));
      margin: 0 auto;
      padding: 22px 0 28px;
    }
    header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 18px;
      margin-bottom: 16px;
    }
    h1 {
      margin: 0;
      font-size: 28px;
      letter-spacing: 0;
    }
    p {
      margin: 6px 0 0;
      color: #69625b;
      font-weight: 650;
    }
    .stats {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      justify-content: flex-end;
    }
    .pill {
      border: 1px solid #ffd2b6;
      background: rgba(255,255,255,.76);
      border-radius: 999px;
      padding: 8px 11px;
      font-weight: 850;
      font-size: 13px;
    }
    .workspace {
      display: grid;
      grid-template-columns: minmax(0, 1fr) 320px;
      gap: 16px;
      align-items: start;
    }
    .viewer, .side {
      background: rgba(255,255,255,.92);
      border: 1px solid #ffe0ca;
      border-radius: 8px;
      box-shadow: 0 18px 34px rgba(38,34,29,.08);
    }
    .viewer {
      padding: 14px;
    }
    .image-frame {
      display: grid;
      place-items: center;
      min-height: 560px;
      background: #1f1d1a;
      border-radius: 8px;
      overflow: hidden;
    }
    img {
      max-width: 100%;
      max-height: 74vh;
      object-fit: contain;
      display: block;
    }
    .empty {
      padding: 64px 20px;
      text-align: center;
      font-weight: 850;
      color: #69625b;
    }
    .buttons {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-top: 12px;
    }
    button {
      border: 0;
      border-radius: 8px;
      min-height: 48px;
      padding: 12px;
      font-size: 15px;
      font-weight: 900;
      cursor: pointer;
    }
    button:disabled {
      cursor: not-allowed;
      opacity: .55;
    }
    .normal { background: #0e5c56; color: white; }
    .mild { background: #f2c14e; color: #211b10; }
    .moderate { background: #f98128; color: white; }
    .severe { background: #b42336; color: white; }
    .skip { background: #ebe5dc; color: #4d4740; grid-column: span 2; }
    .side {
      padding: 16px;
    }
    .section-title {
      margin: 0 0 10px;
      font-size: 13px;
      text-transform: uppercase;
      color: #c5620f;
      font-weight: 950;
    }
    dl {
      margin: 0;
      display: grid;
      gap: 10px;
    }
    dt {
      color: #69625b;
      font-size: 12px;
      font-weight: 900;
      text-transform: uppercase;
    }
    dd {
      margin: 3px 0 0;
      word-break: break-word;
      font-weight: 780;
    }
    .suggestion {
      display: inline-block;
      margin-top: 3px;
      padding: 6px 9px;
      border-radius: 999px;
      background: #eaf6f1;
      color: #0e5c56;
      font-weight: 950;
    }
    .hint {
      margin-top: 16px;
      padding: 12px;
      border-radius: 8px;
      background: #fff3ec;
      color: #675244;
      font-size: 13px;
      font-weight: 750;
    }
    @media (max-width: 880px) {
      header, .workspace {
        display: block;
      }
      .stats {
        justify-content: flex-start;
        margin-top: 12px;
      }
      .side {
        margin-top: 16px;
      }
      .image-frame {
        min-height: 360px;
      }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <div>
        <h1>Skino Severity Review</h1>
        <p>Build the clean hackathon dataset: Normal, Mild, Moderate, Severe, or Skip.</p>
      </div>
      <div class="stats" id="stats"></div>
    </header>

    <section class="workspace">
      <div class="viewer">
        <div class="image-frame" id="imageFrame">
          <div class="empty">Loading next image...</div>
        </div>
        <div class="buttons">
          <button class="normal" data-label="normal">1 Normal</button>
          <button class="mild" data-label="mild">2 Mild</button>
          <button class="moderate" data-label="moderate">3 Moderate</button>
          <button class="severe" data-label="severe">4 Severe</button>
          <button class="skip" data-label="skip">S Skip</button>
        </div>
      </div>
      <aside class="side">
        <h2 class="section-title">Candidate</h2>
        <dl id="meta"></dl>
        <div class="hint">Keyboard: 1 normal, 2 mild, 3 moderate, 4 severe, S skip. Pick only images you trust. Skip blurry, confusing, cropped, duplicate-looking, or mislabeled images.</div>
      </aside>
    </section>
  </main>
  <script>
    let current = null;
    const imageFrame = document.querySelector('#imageFrame');
    const meta = document.querySelector('#meta');
    const stats = document.querySelector('#stats');
    const buttons = [...document.querySelectorAll('button[data-label]')];

    async function loadNext() {
      setBusy(true);
      const response = await fetch('/api/next');
      const payload = await response.json();
      renderStats(payload.stats);
      current = payload.candidate;
      if (!current) {
        imageFrame.innerHTML = '<div class="empty">All candidates reviewed. Your clean metadata.csv is ready.</div>';
        meta.innerHTML = '';
        setBusy(false);
        return;
      }
      imageFrame.innerHTML = `<img src="${current.image_url}" alt="Skin review candidate">`;
      renderMeta(current);
      setBusy(false);
    }

    async function submitLabel(label) {
      if (!current) return;
      setBusy(true);
      const response = await fetch('/api/label', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({key: current.key, label})
      });
      if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        alert(payload.error || 'Could not save label.');
        setBusy(false);
        return;
      }
      await loadNext();
    }

    function renderStats(value) {
      stats.innerHTML = [
        `Reviewed ${value.reviewed}/${value.total}`,
        `Selected ${value.selected}`,
        `Normal ${value.counts.normal || 0}`,
        `Mild ${value.counts.mild || 0}`,
        `Moderate ${value.counts.moderate || 0}`,
        `Severe ${value.counts.severe || 0}`,
        `Skip ${value.counts.skip || 0}`
      ].map(item => `<span class="pill">${item}</span>`).join('');
    }

    function renderMeta(item) {
      meta.innerHTML = `
        <div><dt>Suggested</dt><dd><span class="suggestion">${titleCase(item.suggestion)}</span></dd></div>
        <div><dt>Original labels</dt><dd>${escapeHtml(item.original_labels || 'none')}</dd></div>
        <div><dt>Split</dt><dd>${escapeHtml(item.split)}</dd></div>
        <div><dt>Source</dt><dd>${escapeHtml(item.source)}</dd></div>
        <div><dt>License</dt><dd>${escapeHtml(item.license || 'unknown')}</dd></div>
        <div><dt>Path</dt><dd>${escapeHtml(item.source_image_path)}</dd></div>
      `;
    }

    function setBusy(isBusy) {
      buttons.forEach(button => button.disabled = isBusy);
    }

    function titleCase(value) {
      return String(value).replaceAll('_', ' ').replace(/\b\w/g, match => match.toUpperCase());
    }

    function escapeHtml(value) {
      return String(value).replace(/[&<>"']/g, char => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;'
      }[char]));
    }

    buttons.forEach(button => {
      button.addEventListener('click', () => submitLabel(button.dataset.label));
    });

    window.addEventListener('keydown', event => {
      const keyMap = { '1': 'normal', '2': 'mild', '3': 'moderate', '4': 'severe', 's': 'skip', 'S': 'skip' };
      if (keyMap[event.key]) submitLabel(keyMap[event.key]);
    });

    loadNext();
  </script>
</body>
</html>
"""


if __name__ == "__main__":
    main()
