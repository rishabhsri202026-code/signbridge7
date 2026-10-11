$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$UpstreamRoot = Join-Path $ProjectRoot "sanket-upstream"
$SanketDir = Join-Path $UpstreamRoot "Sanket - ISL Translator"
$WeightsDir = Join-Path $SanketDir "weights"
$Python = Join-Path $UpstreamRoot ".venv\Scripts\python.exe"

Write-Host "=== SignBridge Connect: Sanket setup ===" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required. Install Git for Windows, then run this script again."
}

if (-not (Test-Path (Join-Path $SanketDir "architecture.py"))) {
    if (Test-Path $UpstreamRoot) {
        throw "The folder '$UpstreamRoot' exists but Sanket source was not found inside it. Move/rename the existing folder or inspect it before rerunning."
    }
    Write-Host "Downloading upstream Sanket source..."
    git clone https://github.com/ayush2635/Sanket-ISL-Translator.git $UpstreamRoot
    if ($LASTEXITCODE -ne 0) { throw "Git clone failed." }
}

if (-not (Test-Path $Python)) {
    if (-not (Get-Command py -ErrorAction SilentlyContinue)) {
        throw "Python launcher 'py' was not found. Install Python 3.11 (64-bit), then rerun."
    }
    Write-Host "Creating Python 3.11 virtual environment..."
    py -3.11 -m venv (Join-Path $UpstreamRoot ".venv")
    if ($LASTEXITCODE -ne 0) { throw "Could not create virtual environment. Ensure Python 3.11 is installed." }
}

Write-Host "Installing Sanket dependencies (this can take several minutes)..."
& $Python -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed." }
& $Python -m pip install -r (Join-Path $SanketDir "requirements.txt") pandas huggingface_hub
if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed." }

New-Item -ItemType Directory -Force -Path $WeightsDir | Out-Null
$Checkpoint = Join-Path $WeightsDir "model_best.pth"
if (-not (Test-Path $Checkpoint)) {
    Write-Host "Downloading Sanket checkpoint from Hugging Face. It is large; keep this window open..." -ForegroundColor Yellow
    & $Python -m pip install --upgrade "huggingface_hub[cli]"
    if ($LASTEXITCODE -ne 0) { throw "Could not install Hugging Face download CLI." }
    & $Python -c "from huggingface_hub import hf_hub_download; import shutil,sys; p=hf_hub_download(repo_id='ayush2635/sanket-isl-translator', filename='model_best.pth'); shutil.copy2(p, sys.argv[1])" $Checkpoint
    if ($LASTEXITCODE -ne 0) { throw "Hugging Face checkpoint download failed." }
    if (-not (Test-Path $Checkpoint)) {
        throw "Checkpoint download did not create $Checkpoint. Check Hugging Face access/network and download model_best.pth manually into that folder."
    }
} else {
    Write-Host "Checkpoint already exists; keeping it."
}

$T5Config = Join-Path $SanketDir "cache\t5-base\config.json"
$TSConfig = Join-Path $SanketDir "cache\timesformer\config.json"
if (-not (Test-Path $T5Config) -or -not (Test-Path $TSConfig)) {
    Write-Host "Downloading required T5 and TimeSformer caches (multiple GB possible)..."
    Push-Location $SanketDir
    try {
        & $Python "setup_cache.py"
        if ($LASTEXITCODE -ne 0) { throw "setup_cache.py failed." }
    } finally { Pop-Location }
} else {
    Write-Host "Hugging Face model caches already exist; keeping them."
}

Write-Host ""
Write-Host "Setup files are present. Next run .\model-integration\start-sanket-bridge.ps1 from the repository root." -ForegroundColor Green
Write-Host "Important: this confirms setup steps completed, not that translation accuracy has been validated."
