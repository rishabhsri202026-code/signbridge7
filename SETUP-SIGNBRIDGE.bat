@echo off
setlocal
cd /d "%~dp0"
echo SignBridge Connect - Sanket setup
echo This downloads model source, Python packages, checkpoint and model caches.
echo Large downloads and several GB of free disk space are required.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0model-integration\setup-sanket.ps1"
if errorlevel 1 (
  echo.
  echo Setup did not finish. Read the error above, then try again after fixing it.
  pause
  exit /b 1
)
echo.
echo Setup finished. Next double-click RUN-SIGNBRIDGE.bat.
pause
