# Gemma 4 26B-A4B QAT UD-Q4_K_XL GGUF dosyasini models/ klasorune indirir.
# CLI yerine stabil huggingface_hub Python API'si (hf_hub_download) kullanilir.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$models = Join-Path $root 'models'
New-Item -ItemType Directory -Force -Path $models | Out-Null

Write-Host "huggingface_hub kuruluyor/guncelleniyor..." -ForegroundColor Cyan
python -m pip install -U huggingface_hub hf_xet
if ($LASTEXITCODE -ne 0) { throw "huggingface_hub kurulamadi" }

# xet protokolu bazi aglarda takiliyor; standart HTTPS LFS indirmesine zorla.
$env:HF_HUB_DISABLE_XET = '1'
$env:YP_REPO = 'unsloth/gemma-4-26B-A4B-it-qat-GGUF'
$env:YP_FILE = 'gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf'
$env:YP_DIR  = $models

Write-Host "Indiriliyor: $($env:YP_REPO) / $($env:YP_FILE) (~14.2 GB)" -ForegroundColor Cyan
$py = @'
import os
from huggingface_hub import hf_hub_download
p = hf_hub_download(
    repo_id=os.environ["YP_REPO"],
    filename=os.environ["YP_FILE"],
    local_dir=os.environ["YP_DIR"],
)
print("OK:", p)
'@
$py | python -
if ($LASTEXITCODE -ne 0) { throw "Indirme basarisiz" }

$target = Join-Path $models $env:YP_FILE
if (Test-Path $target) {
    $gb = [math]::Round((Get-Item $target).Length/1GB,2)
    Write-Host "`nINDIRME TAMAM -> $target ($gb GB)" -ForegroundColor Green
} else {
    Write-Host "`nUYARI: Dosya beklenen yolda yok: $target" -ForegroundColor Yellow
}
