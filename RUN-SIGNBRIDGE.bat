@echo off
setlocal
cd /d "%~dp0"

if not exist "sanket-upstream\.venv\Scripts\python.exe" (
  echo Sanket Python environment not found.
  echo First run SETUP-SIGNBRIDGE.bat and wait for it to finish.
  pause
  exit /b 1
)

echo Starting local website server...
start "SignBridge Website Server" cmd /k ""%~dp0sanket-upstream\.venv\Scripts\python.exe" -m http.server 8000 --bind 127.0.0.1"
timeout /t 2 /nobreak >nul

echo Starting Sanket model bridge...
start "SignBridge Sanket Bridge" powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0model-integration\start-sanket-bridge.ps1"
timeout /t 4 /nobreak >nul
start "" http://localhost:8000

echo.
echo Keep both terminal windows open while using SignBridge.
echo Website: http://localhost:8000
echo Bridge health: http://127.0.0.1:8765/health
