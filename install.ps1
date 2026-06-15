# Yargi Pro Local - tek satir uzaktan kurulum bootstrap.
# Kullanim (normal PowerShell):
#   irm https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
# Bu surec icin script calistirmayi ac (Restricted politikada & ile .ps1 cagrilari engelleniyor).
Set-ExecutionPolicy -Scope Process Bypass -Force -ErrorAction SilentlyContinue

# === Dagitim ayarlari (kendi repo'na gore degistir) ===
$RepoUrl    = 'https://github.com/saidsurucu/yargi-pro-gemma-local.git'
$InstallUrl = 'https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.ps1'
$Dest       = Join-Path $env:USERPROFILE 'GemmaYargiPro'

Write-Host "=== Yargi Pro Local - Kurulum ===" -ForegroundColor Cyan

# --- Yonetici izni (UAC ile elevated shell'de kendini yeniden cek) ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $admin) {
    Write-Host "Yonetici izni gerekiyor - UAC ile yeniden baslatiliyor..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm $InstallUrl | iex`""
    return
}

# --- Chocolatey (git icin gerekli) ---
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "[KUR] Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
}

# --- git ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[KUR] git..." -ForegroundColor Cyan
    choco install -y git
    if ($LASTEXITCODE -ne 0) { throw "git kurulamadi" }
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
}

# Calisan sunucu + tray, klasor dosyalarini/CWD'sini kilitler; tasima/silme oncesi kapat.
function Stop-YargiProcs {
    Get-Process llama-server -ErrorAction SilentlyContinue | Stop-Process -Force
    foreach ($pn in 'wscript', 'powershell') {
        Get-CimInstance Win32_Process -Filter "Name='$pn.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like '*yargi-tray*' -and $_.ProcessId -ne $PID } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    }
}

# --- Eski konumdan ('yargi-pro-gemma-local') yeni konuma gecis: agir dosyalar (14 GB model)
#     tekrar inmesin diye klasor oldugu gibi tasinir; eski konum birakilmaz. ---
$OldDest = Join-Path $env:USERPROFILE 'yargi-pro-gemma-local'
if ((Test-Path $OldDest) -and ($OldDest -ne $Dest)) {
    Stop-YargiProcs
    if (-not (Test-Path $Dest)) {
        Write-Host "[GIT] Eski konum yeni ada tasiniyor (model korunur): $OldDest -> $Dest" -ForegroundColor Cyan
        try { Rename-Item -LiteralPath $OldDest -NewName (Split-Path -Leaf $Dest) -ErrorAction Stop }
        catch { Write-Host "[UYARI] Eski klasor tasinamadi ($($_.Exception.Message)); temiz kurulum yapilacak." -ForegroundColor Yellow }
    } else {
        Write-Host "[GIT] Eski konum siliniyor (yeni konum zaten var): $OldDest" -ForegroundColor Yellow
        Remove-Item -LiteralPath $OldDest -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- Repo'yu HER ZAMAN temiz klonla. Var olan kopya silinir; ancak indirilen
#     agir dosyalar (model + vendor binary, ikisi de .gitignore'da) korunup
#     klon sonrasi geri tasinir; boylece kod hep taze gelir, 14 GB tekrar inmez. ---
$keep = Join-Path (Split-Path -Parent $Dest) '.yargi-keep'
$keepSubs = @('models', 'vendor')

if (Test-Path $Dest) {
    Stop-YargiProcs
    New-Item -ItemType Directory -Force -Path $keep | Out-Null
    foreach ($sub in $keepSubs) {
        $src = Join-Path $Dest $sub
        $bak = Join-Path $keep $sub
        # Sadece $Dest'te varsa VE daha once yedeklenmemisse kenara al (yarim kalmis run'da modeli ezme).
        if ((Test-Path $src) -and -not (Test-Path $bak)) {
            Write-Host "[GIT] Korunuyor (gecici kenara aliniyor): $sub" -ForegroundColor Cyan
            Move-Item -Path $src -Destination $bak -Force
        }
    }
    Write-Host "[GIT] Var olan klasor siliniyor: $Dest" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $Dest
}

Write-Host "[GIT] Temiz klonlaniyor: $RepoUrl -> $Dest" -ForegroundColor Cyan
git clone $RepoUrl $Dest
if ($LASTEXITCODE -ne 0) { throw "git clone basarisiz" }

# Korunan agir dosyalari geri tasi.
if (Test-Path $keep) {
    foreach ($sub in $keepSubs) {
        $bak = Join-Path $keep $sub
        if (Test-Path $bak) {
            Write-Host "[GIT] Geri tasiniyor: $sub" -ForegroundColor Cyan
            $dst = Join-Path $Dest $sub
            if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
            Move-Item -Path $bak -Destination $dst -Force
        }
    }
    Remove-Item -Recurse -Force $keep
}

# --- Tam kurulumu calistir (choco/cmake/cuda/build/model/opencode/mcp) ---
Write-Host "[RUN] setup-all.ps1 calistiriliyor..." -ForegroundColor Cyan
& (Join-Path $Dest 'scripts\setup-all.ps1')
if ($LASTEXITCODE -ne 0) {
    Write-Host "[HATA] Kurulum tamamlanamadi. Log: $Dest\install.log" -ForegroundColor Red
}
