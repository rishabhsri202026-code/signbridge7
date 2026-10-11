# SignBridge Connect ↔ Sanket bridge (beta)

This folder contains a local HTTP bridge between the browser camera UI and a separate Sanket ISL Translator installation. It does not train the model or include model weights.

## Required local layout

Place your existing `sanket-upstream` folder at the repository root:

```
signbridge7/
  model-integration/
  sanket-upstream/
    .venv/Scripts/python.exe
    Sanket - ISL Translator/
      architecture.py
      extract_features.py
      gemini_nlp.py
      cache/t5-base/
      weights/model_best.pth
```

Do not move or delete the original model files until this setup is verified.

## Run on Windows

1. Install the compatible Python dependencies in your existing Sanket virtual environment.
2. Ensure the checkpoint and Hugging Face caches are present locally.
3. From the repository root, open PowerShell and run:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\model-integration\start-sanket-bridge.ps1
   ```
4. Keep that terminal open. Visit `http://127.0.0.1:8765/health`; verify `model_loaded: true`.
5. In a second terminal, start a local web server from the repository root and open its HTTP URL (not a `file://` URL).
6. Start the camera and use **Record 5 seconds & translate**.

## Limitations

- This is short-clip translation, not continuous real-time captions.
- Camera permission does not prove the model has loaded. Check the health endpoint and bridge terminal.
- The bridge binds to `127.0.0.1` for local testing. A phone or hosted website cannot reach a laptop's localhost service; remote testing requires a secured, reachable backend.
- Model output may be wrong; do not rely on it for high-stakes communication.
- Upstream source, weights, caches, datasets, and API keys are not included. Check upstream licenses before redistribution.
