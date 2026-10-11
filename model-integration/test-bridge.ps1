$ErrorActionPreference = "Stop"
$healthUrl = "http://127.0.0.1:8765/health"
try {
    $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 5
} catch {
    Write-Host "Bridge is unreachable at $healthUrl" -ForegroundColor Red
    Write-Host "Start RUN-SIGNBRIDGE.bat and inspect the Sanket bridge terminal."
    exit 1
}
if (-not $health.model_loaded) {
    Write-Host "Bridge responds, but model_loaded is false." -ForegroundColor Red
    Write-Host "The website camera may work, but translation is not ready. Inspect the bridge terminal."
    exit 2
}
Write-Host "Bridge health check passed: model_loaded=true" -ForegroundColor Green
