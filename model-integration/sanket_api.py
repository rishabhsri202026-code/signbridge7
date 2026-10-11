"""Local HTTP bridge from SignBridge browser clips to a separately installed Sanket model."""
import json
import os
import tempfile
import traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SANKET = ROOT / "sanket-upstream" / "Sanket - ISL Translator"
if not SANKET.exists():
    raise RuntimeError(
        f"Sanket source not found at {SANKET}. Put your existing sanket-upstream folder at the repository root."
    )

os.chdir(SANKET)
import sys
sys.path.insert(0, str(SANKET))

import torch
from transformers import AutoTokenizer
from architecture import DualStreamGMTFormer
from extract_features import process_continuous_video
from gemini_nlp import construct_sentence

MODEL = None
TOKENIZER = None
DEVICE = None


def load_model():
    global MODEL, TOKENIZER, DEVICE
    if MODEL is not None:
        return
    model_path = SANKET / "weights" / "model_best.pth"
    tok_path = SANKET / "cache" / "t5-base"
    if not model_path.exists():
        raise RuntimeError(f"Model checkpoint not found: {model_path}")
    if not tok_path.exists():
        raise RuntimeError(f"T5 tokenizer cache not found: {tok_path}. Run upstream setup_cache.py first.")
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    TOKENIZER = AutoTokenizer.from_pretrained(str(tok_path), local_files_only=True)
    MODEL = DualStreamGMTFormer(t5_model_name="t5-base")
    checkpoint = torch.load(str(model_path), map_location=DEVICE)
    state_dict = checkpoint.get("model_state_dict", checkpoint) if isinstance(checkpoint, dict) else checkpoint
    incompatible = MODEL.load_state_dict(state_dict, strict=False)
    # strict=False permits harmless upstream extras, but missing model parameters
    # would mean random/untrained weights and must never be reported as loaded.
    if incompatible.missing_keys:
        raise RuntimeError(
            "Checkpoint is missing " + str(len(incompatible.missing_keys)) +
            " model parameters; refusing to report the model as loaded. First missing keys: " +
            ", ".join(incompatible.missing_keys[:8])
        )
    MODEL.to(DEVICE).eval()


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_OPTIONS(self):
        self._send(200, {"ok": True})

    def do_GET(self):
        if self.path.rstrip("/") == "/health":
            self._send(200, {"ok": True, "service": "SignBridge-Sanket bridge", "model_loaded": MODEL is not None})
        else:
            self._send(404, {"error": "Use /health or POST /translate"})

    def do_POST(self):
        if self.path.rstrip("/") != "/translate":
            return self._send(404, {"error": "Unknown endpoint"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > 80 * 1024 * 1024:
            return self._send(400, {"error": "Video body missing or larger than 80 MB."})
        suffix = ".webm" if "webm" in self.headers.get("Content-Type", "").lower() else ".mp4"
        tmp = None
        try:
            payload = self.rfile.read(length)
            load_model()
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
                f.write(payload)
                tmp = f.name
            chunks = process_continuous_video(tmp, frames_per_chunk=8)
            predictions = []
            for video_tensor, pose_tensor in chunks:
                with torch.no_grad():
                    pred = MODEL.generate_translation(
                        video_frames=video_tensor.to(DEVICE),
                        pose_data=pose_tensor.to(DEVICE),
                        tokenizer=TOKENIZER,
                        max_length=15,
                    )
                pred = (pred or "").strip()
                if pred and (not predictions or pred != predictions[-1]):
                    predictions.append(pred)
            raw = " ".join(predictions).strip()
            if not raw:
                return self._send(200, {
                    "ok": True, "raw": "",
                    "sentence": "No words predicted. Try better lighting and a longer, clear signing clip.",
                    "chunks": len(chunks),
                })
            vocab = getattr(MODEL, "vocab_list", None)
            try:
                sentence = construct_sentence(raw, vocab_list=vocab)
            except Exception:
                sentence = raw
            self._send(200, {"ok": True, "raw": raw, "sentence": sentence, "chunks": len(chunks), "device": str(DEVICE)})
        except Exception as e:
            traceback.print_exc()
            self._send(500, {"ok": False, "error": str(e)})
        finally:
            if tmp and os.path.exists(tmp):
                try:
                    os.remove(tmp)
                except OSError:
                    pass

    def log_message(self, fmt, *args):
        print("[SignBridge bridge]", fmt % args)


if __name__ == "__main__":
    print("Loading Sanket model; first startup can take a while...")
    try:
        load_model()
        print(f"Model loaded on {DEVICE}")
    except Exception as e:
        print(f"WARNING: model not preloaded: {e}\nIt will retry when a clip is submitted.")
    print("Bridge listening at http://127.0.0.1:8765 (keep this terminal open)")
    ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
