# VRAM'e gore model secip models/ klasorune indirir (curl, resume).
#   VRAM >= 16 GB -> Gemma 4 26B-A4B QAT UD-Q4_K_XL (~14.2 GB)
#   VRAM <  16 GB -> Gemma 4 12B QAT UD-Q4_K_XL (~6.7 GB)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$models = Join-Path $root 'models'
New-Item -ItemType Directory -Force -Path $models | Out-Null

# VRAM (MiB) - nvidia-smi
$vram = 0
try { $vram = [int]((& nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>$null | Select-Object -First 1).Trim()) } catch {}
Write-Host "Toplam VRAM: $vram MiB" -ForegroundColor Cyan

if ($vram -ge 16000) {
    $repo = 'unsloth/gemma-4-26B-A4B-it-qat-GGUF'
    $file = 'gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf'
    $expected = 14249045120
    Write-Host "Secilen model: 26B-A4B (UD-Q4_K_XL, ~14.2 GB)" -ForegroundColor Green
} else {
    $repo = 'unsloth/gemma-4-12B-it-qat-GGUF'
    $file = 'gemma-4-12B-it-qat-UD-Q4_K_XL.gguf'
    $expected = 6716355328
    Write-Host "Secilen model: 12B (UD-Q4_K_XL, ~6.7 GB) - VRAM 16 GB altinda" -ForegroundColor Green
}

$url = "https://huggingface.co/$repo/resolve/main/$file"
$target = Join-Path $models $file

# Zaten tam indirilmisse atla (curl -C - tam dosyada 416 verip throw etmesin).
if ((Test-Path $target) -and ((Get-Item $target).Length -ge $expected)) {
    Write-Host "[VAR] Model zaten tam indirilmis, atlaniyor -> $target" -ForegroundColor Green
    return
}

Write-Host "Indiriliyor: $file`nHedef: $target`n"

curl.exe -L -C - --retry 8 --retry-delay 5 --retry-all-errors -o "$target" "$url"
if ($LASTEXITCODE -ne 0) { throw "curl indirme basarisiz (exit $LASTEXITCODE)" }

if (Test-Path $target) {
    $len = (Get-Item $target).Length
    $gb = [math]::Round($len/1GB,2)
    if ($len -ge $expected) {
        Write-Host "`nINDIRME TAMAM -> $target ($gb GB)" -ForegroundColor Green
    } else {
        Write-Host "`nUYARI: Dosya eksik olabilir ($gb GB). Scripti tekrar calistir (resume eder)." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nUYARI: Dosya olusmadi: $target" -ForegroundColor Yellow
}
