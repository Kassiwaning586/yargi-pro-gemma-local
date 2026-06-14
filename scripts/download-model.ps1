# Gemma 4 26B-A4B QAT UD-Q4_K_XL GGUF dosyasini models/ klasorune indirir.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$models = Join-Path $root 'models'
$repoId = 'unsloth/gemma-4-26B-A4B-it-qat-GGUF'
$file = 'gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf'

New-Item -ItemType Directory -Force -Path $models | Out-Null

Write-Host "huggingface_hub kuruluyor/guncelleniyor..." -ForegroundColor Cyan
python -m pip install -U "huggingface_hub[cli]"
if ($LASTEXITCODE -ne 0) { throw "huggingface_hub kurulamadi" }

Write-Host "Indiriliyor: $repoId / $file (~14.2 GB)" -ForegroundColor Cyan
python -m huggingface_hub.commands.huggingface_cli download $repoId $file --local-dir $models
if ($LASTEXITCODE -ne 0) { throw "Indirme basarisiz" }

$target = Join-Path $models $file
if (Test-Path $target) {
    $gb = [math]::Round((Get-Item $target).Length/1GB,2)
    Write-Host "`nINDIRME TAMAM -> $target ($gb GB)" -ForegroundColor Green
} else {
    Write-Host "`nUYARI: Dosya beklenen yolda yok: $target" -ForegroundColor Yellow
}
