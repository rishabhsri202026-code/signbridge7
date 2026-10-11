$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Python = Join-Path $ProjectRoot "sanket-upstream\.venv\Scripts\python.exe"
$Bridge = Join-Path $ProjectRoot "model-integration\sanket_api.py"

if (-not (Test-Path $Python)) {
    Write-Host "Could not find the Sanket Python environment at $Python" -ForegroundColor Red
    Write-Host "Place your existing sanket-upstream folder at the signbridge7 repository root."
    Read-Host "Press Enter to exit"
    exit 1
}
if (-not (Test-Path $Bridge)) {
    Write-Host "Bridge script missing: $Bridge" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
& $Python $Bridge
