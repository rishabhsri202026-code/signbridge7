# SignBridge Connect — signbridge7

SignBridge Connect is a browser-first ISL translation prototype. The browser records a short clip; a local Python bridge sends it through the Sanket model and returns text.

## Start here (Windows)

1. Download this repository using **Code → Download ZIP**, then extract it.
2. Install **Git for Windows** and **Python 3.11 (64-bit)** if not already installed.
3. Open the extracted folder. Right-click **SETUP-SIGNBRIDGE.bat** and choose **Run** (or double-click it). The setup downloads the upstream Sanket source, installs Python packages, downloads the model checkpoint, and downloads the required T5/TimeSformer caches. These downloads are large and need internet access and several GB of free disk space.
4. Wait for setup to finish. Do not close its window if downloads are running.
5. Double-click **RUN-SIGNBRIDGE.bat**. Keep the Sanket bridge terminal open.
6. Open the website on the same laptop at `http://localhost:8000`, allow camera access, and click **Start camera**, then **Record 5 seconds & translate**.
7. If the model status says **Bridge offline** or **Model not loaded**, check the bridge terminal for the actual error. The health endpoint is `http://127.0.0.1:8765/health`.

### If you already have the Sanket folder

The automatic setup creates `sanket-upstream` beside this README. If you already have a working `sanket-upstream` folder, copy it into the repository root first and ensure it contains `Sanket - ISL Translator/architecture.py`, `weights/model_best.pth`, the `.venv` and the required cache folders. Setup will preserve existing checkpoint/cache files.

## What is included

- `index.html`, `app.js`, `styles.css`: camera, clip recording, subtitles, speech and copy controls.
- `manifest.webmanifest`, `sw.js`: installable web shell.
- `model-integration/sanket_api.py`: local HTTP bridge using Sanket's actual `process_continuous_video(video_path, frames_per_chunk=8)` and `generate_translation(video_frames, pose_data, tokenizer, max_length=...)` APIs.
- `model-integration/setup-sanket.ps1`: downloads/install setup for Windows.
- `model-integration/start-sanket-bridge.ps1`: launches the bridge.

## Honest limitations

- This is **short-clip translation**, not continuous real-time subtitles.
- The model is not bundled in Git because the checkpoint and caches are large; the setup downloads them separately.
- The browser UI and bridge code have been connected to the upstream function signatures, but this repository has not been executed end-to-end on your laptop here. Setup success is not proof of correct translation. Test with known examples and inspect errors before presenting it as a working translator.
- This CPU-based laptop may process clips slowly. Results may be wrong; do not use it as the only channel for critical communication.
- A hosted website or phone cannot access a laptop's `127.0.0.1` service. Phone/remote use needs a secured backend reachable over the network.
- Check upstream model and dataset licenses before redistribution. Never commit model weights, datasets, virtual environments, or API keys.
