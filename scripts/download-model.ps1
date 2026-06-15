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

# Kararsiz aglarda indirme takilabiliyor: hiz 0'a duser ama baglanti kopmaz, curl sonsuz bekler.
# --speed-limit 1024 --speed-time 30: 30 sn boyunca <1 KB/s ise curl'u durdur (exit 28) -> resume/retry devreye girer.
# Buyuk dosya icin: dosya TAM (>= beklenen boyut) olana kadar -C - ile tekrar tekrar dene.
$expGB = [math]::Round($expected/1GB,2)
$maxTries = 40
for ($i = 1; $i -le $maxTries; $i++) {
    curl.exe -L -C - --retry 5 --retry-delay 3 --retry-all-errors --speed-limit 1024 --speed-time 30 -o "$target" "$url"
    $code = $LASTEXITCODE
    if ((Test-Path $target) -and ((Get-Item $target).Length -ge $expected)) { break }
    $curGB = if (Test-Path $target) { [math]::Round((Get-Item $target).Length/1GB,2) } else { 0 }
    Write-Host "Indirme yarim ($curGB / $expGB GB, deneme $i/$maxTries, curl exit $code) - kaldigi yerden devam..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
}

if (-not ((Test-Path $target) -and ((Get-Item $target).Length -ge $expected))) {
    throw "model indirilemedi (eksik kaldi). Ag baglantisini kontrol edip scripti/kurulumu tekrar calistirin - kaldigi yerden devam eder."
}
$gb = [math]::Round((Get-Item $target).Length/1GB,2)
Write-Host "`nINDIRME TAMAM -> $target ($gb GB)" -ForegroundColor Green
