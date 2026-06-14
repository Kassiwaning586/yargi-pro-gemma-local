# Tek-tik launcher: sunucu kapaliysa baslat (gizli), hazir olunca opencode desktop ac.
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot

function Test-Server { try { Invoke-RestMethod http://127.0.0.1:8080/v1/models -TimeoutSec 3 | Out-Null; return $true } catch { return $false } }

if (-not (Test-Server)) {
    Start-Process powershell -WindowStyle Hidden -ArgumentList `
      "-NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\start-server.ps1`""
    for ($i=0; $i -lt 120; $i++) { if (Test-Server) { break }; Start-Sleep -Seconds 2 }
}

$oc = "$env:LOCALAPPDATA\Programs\@opencode-aidesktop\OpenCode.exe"
if (Test-Path $oc) { Start-Process $oc } else { Start-Process opencode }
