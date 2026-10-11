@echo off
setlocal
cd /d "%~dp0"
if not exist "sanket-upstream\.venv\Scripts\python.exe" (
  echo Sanket Python environment not found.
  echo Put your existing sanket-upstream folder beside this file.
  pause
  exit /b 1
)
start "SignBridge Sanket Bridge" powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0model-integration\start-sanket-bridge.ps1"
timeout /t 3 /nobreak >nul
start "" http://localhost:8000
"%~dp0sanket-upstream\.venv\Scripts\python.exe" -m http.server 8000
