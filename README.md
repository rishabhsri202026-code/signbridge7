# SignBridge Connect — signbridge7

SignBridge Connect is a browser-first prototype for exploring Indian Sign Language (ISL) translation with a camera-based interface and a local Python bridge to the Sanket ISL Translator.

## Current status

**Prototype / integration work in progress — not a verified real-time translator.**

- The browser interface can request camera access and record a short clip.
- The optional local bridge is designed to pass recorded clips to an existing Sanket model installation.
- The pretrained checkpoint, Hugging Face caches, upstream Sanket source, and dataset are not bundled in this repository.
- Translation output and accuracy must be tested against the actual model before this project is described as working or suitable for communication support.

## Repository contents

- `index.html`, `app.js`, `styles.css`: browser interface
- `manifest.webmanifest`, `sw.js`: installable/offline web shell
- `model-integration/`: local bridge launch scripts and integration notes
- `c-baseline/`: earlier C prototype, kept as a separate baseline

## Run the browser prototype (Windows)

1. Download or clone this repository.
2. Open the folder in VS Code.
3. Use Live Server, or run a local static server, then open the local HTTP URL. Camera access usually does not work from a `file://` URL.
4. Grant the browser camera permission.

## Run with the Sanket model

The bridge expects a separate upstream Sanket installation containing the model source and checkpoint, including `Sanket - ISL Translator/architecture.py`, `extract_features.py`, `gemini_nlp.py`, and `weights/model_best.pth`. The compatible Python environment and Hugging Face caches must also be installed locally.

See [model-integration/README.md](model-integration/README.md) before starting the bridge. A healthy camera is not proof that the translation model has loaded. Check the bridge health endpoint and confirm `model_loaded: true`.

## Important limitations

- The current integration is short-clip translation, not continuous real-time subtitles.
- The model can make mistakes and is not a certified accessibility or medical communication tool.
- The local bridge is intended for local testing. A hosted website or phone cannot access a laptop's `127.0.0.1` service; remote deployment requires a secured, reachable backend.
- Do not commit virtual environments, checkpoints, datasets, API keys, or other secrets.

## License and model/data notices

Check the license of the upstream model, checkpoint, and any dataset before redistributing them. This repository's code license does not override upstream licenses or dataset restrictions.