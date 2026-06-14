#!/usr/bin/env bash
# macOS/Metal tam kurulum: prereqler -> build -> model -> opencode + MCP.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "=== Yargi Pro Local - Tam Kurulum (macOS/Metal) ==="

# brew'i PATH'e al
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi

# --- prereqler ---
for pkg in cmake git node; do
  if ! command -v "$pkg" >/dev/null 2>&1; then echo "[KUR] $pkg"; brew install "$pkg"; else echo "[VAR] $pkg"; fi
done

echo "--- Inference engine derleniyor (Metal) ---"
bash "$ROOT/scripts/build-llamacpp.sh"

echo "--- Model indiriliyor (~14.2 GB) ---"
bash "$ROOT/scripts/download-model.sh"

echo "--- opencode (CLI + desktop) + Yargi Pro MCP ---"
bash "$ROOT/scripts/install-opencode.sh"

echo "=== HER SEY HAZIR ==="
echo "Sunucu baslat: $ROOT/scripts/start-server.sh"
echo "Sonra: opencode  (model: gemma-4-26b-qat)"
