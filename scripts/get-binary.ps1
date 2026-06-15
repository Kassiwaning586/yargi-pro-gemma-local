# Release'ten Windows CUDA prebuilt binary'sini indirip vendor altina acar.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$rel  = 'binaries-v1'
$url  = "https://github.com/saidsurucu/yargi-pro-gemma-local/releases/download/$rel/llama-turboquant-win-cuda.zip"
$dest = Join-Path $root 'vendor\llama-cpp-turboquant\build\bin\Release'
$exe  = Join-Path $dest 'llama-server.exe'

if (Test-Path $exe) { Write-Host "[VAR] llama-server.exe" -ForegroundColor Green; return }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$zip = Join-Path $env:TEMP 'llama-turboquant-win-cuda.zip'
Write-Host "Prebuilt indiriliyor..." -ForegroundColor Cyan
# aria2c varsa onunla indir (kararsiz agda cok-baglantili + saglam resume); yoksa curl'e dus.
$aria = Get-Command aria2c -ErrorAction SilentlyContinue
if ($aria) {
    aria2c --continue=true --max-connection-per-server=16 --split=16 --min-split-size=1M `
           --max-tries=0 --retry-wait=5 --timeout=60 --connect-timeout=60 `
           --file-allocation=none --auto-file-renaming=false --allow-overwrite=true `
           --console-log-level=warn --summary-interval=15 `
           --dir="$(Split-Path -Parent $zip)" --out="$(Split-Path -Leaf $zip)" "$url"
    if ($LASTEXITCODE -ne 0) { throw "binary indirilemedi (aria2 exit $LASTEXITCODE)" }
} else {
    # -C - : yarim kalandan devam; --retry-all-errors : connection reset (56) gibi hatalarda tekrar dene.
    curl.exe -L -C - --retry 8 --retry-delay 5 --retry-all-errors --speed-limit 1024 --speed-time 30 -o "$zip" "$url"
    $code = $LASTEXITCODE
    # 33 = HTTP range error (416): dosya zaten tam inmis; hata degil, ace gec.
    if ($code -ne 0 -and $code -ne 33) { throw "binary indirilemedi (curl exit $code)" }
}
Expand-Archive -Path $zip -DestinationPath $dest -Force
if (-not (Test-Path $exe)) { throw "binary acilmadi/eksik: $exe" }
Write-Host "Binary hazir -> $exe" -ForegroundColor Green
