# Derleme ve calistirma on-kosullarini kontrol eder.
$ErrorActionPreference = 'Continue'
$ok = $true

function Test-Tool($name, $cmd, $hint) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c) { Write-Host "[OK]   $name -> $($c.Source)" -ForegroundColor Green }
    else { Write-Host "[EKSIK] $name -> $hint" -ForegroundColor Red; $script:ok = $false }
}

Write-Host "=== Yargi Pro Local — On-kosul kontrolu ===`n"
Test-Tool 'git'    'git'    'https://git-scm.com/download/win'
Test-Tool 'CMake'  'cmake'  'winget install Kitware.CMake veya https://cmake.org/download'
Test-Tool 'CUDA (nvcc)' 'nvcc' 'CUDA Toolkit 12.x: https://developer.nvidia.com/cuda-downloads'
Test-Tool 'Python' 'python' 'https://www.python.org/downloads/'
Test-Tool 'nvidia-smi' 'nvidia-smi' 'NVIDIA surucusu kurulu olmali'

# MSVC C++ derleyici (cl.exe) — vswhere ile ara
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vs) { Write-Host "[OK]   MSVC C++ Build Tools -> $vs" -ForegroundColor Green }
    else { Write-Host "[EKSIK] MSVC C++ Build Tools -> 'Desktop development with C++' is yukunu kur" -ForegroundColor Red; $ok = $false }
} else {
    Write-Host "[EKSIK] Visual Studio Build Tools bulunamadi -> https://visualstudio.microsoft.com/downloads/ (Build Tools for VS, C++ workload)" -ForegroundColor Red
    $ok = $false
}

Write-Host ""
if ($ok) { Write-Host "Tum on-kosullar hazir. build-turboquant.ps1 calistirilabilir." -ForegroundColor Green; exit 0 }
else { Write-Host "Eksik on-kosullar var. Yukaridaki linklerden kurup tekrar calistirin." -ForegroundColor Yellow; exit 1 }
