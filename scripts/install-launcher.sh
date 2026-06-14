#!/usr/bin/env bash
# /Applications/Yargi Pro.app uretir (Launchpad'de cift tik). Lokal uretildigi icin karantinasiz.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="/Applications/Yargi Pro.app"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Yargi Pro</string>
  <key>CFBundleExecutable</key><string>launch</string>
  <key>CFBundleIdentifier</key><string>com.yargipro.launcher</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST

cat > "$APP/Contents/MacOS/launch" <<LAUNCH
#!/bin/bash
ROOT="$ROOT"
if ! curl -s http://127.0.0.1:8080/v1/models >/dev/null 2>&1; then
  nohup bash "\$ROOT/scripts/start-server.sh" >/tmp/yargi-server.log 2>&1 &
  for i in \$(seq 1 120); do curl -s http://127.0.0.1:8080/v1/models >/dev/null 2>&1 && break; sleep 2; done
fi
open -a OpenCode
LAUNCH
chmod +x "$APP/Contents/MacOS/launch"
echo "Launcher -> $APP"
