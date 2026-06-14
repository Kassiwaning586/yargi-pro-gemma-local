# Gemma 4 26B-A4B QAT UD-Q4_K_XL GGUF dosyasini models/ klasorune indirir.
# curl.exe ile dogrudan indirme (Windows yerlesik). huggingface_hub/xet bazi
# aglarda redirect CDN'de takiliyordu; curl redirect'i takip eder, resume eder.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$models = Join-Path $root 'models'
New-Item -ItemType Directory -Force -Path $models | Out-Null

$file = 'gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf'
$url = "https://huggingface.co/unsloth/gemma-4-26B-A4B-it-qat-GGUF/resolve/main/$file"
$target = Join-Path $models $file
$expectedBytes = 14249045120

Write-Host "Indiriliyor: $file (~14.2 GB)" -ForegroundColor Cyan
Write-Host "Hedef: $target`n"

# -L: redirect takip, -C -: resume, --retry: aglanti kopmalarina dayanik
curl.exe -L -C - --retry 8 --retry-delay 5 --retry-all-errors -o "$target" "$url"
if ($LASTEXITCODE -ne 0) { throw "curl indirme basarisiz (exit $LASTEXITCODE)" }

if (Test-Path $target) {
    $len = (Get-Item $target).Length
    $gb = [math]::Round($len/1GB,2)
    if ($len -ge $expectedBytes) {
        Write-Host "`nINDIRME TAMAM -> $target ($gb GB)" -ForegroundColor Green
    } else {
        Write-Host "`nUYARI: Dosya eksik olabilir ($gb GB, beklenen ~13.3 GiB). Scripti tekrar calistir (resume eder)." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nUYARI: Dosya olusmadi: $target" -ForegroundColor Yellow
}
