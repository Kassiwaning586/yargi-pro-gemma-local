#!/usr/bin/env bash
# Unified RAM'e gore model secip models/ klasorune indirir (curl, resume).
#   RAM >= 24 GB -> Gemma 4 26B-A4B QAT UD-Q4_K_XL (~14.2 GB)
#   RAM <  24 GB -> Gemma 4 12B QAT UD-Q4_K_XL (~6.7 GB)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS="$ROOT/models"; mkdir -p "$MODELS"

MEM=$(sysctl -n hw.memsize 2>/dev/null || echo 0)   # byte
GB=$((MEM/1024/1024/1024))
echo "Unified RAM: ${GB} GB"

if [ "$MEM" -ge 25769803776 ]; then   # >= 24 GiB
  REPO="unsloth/gemma-4-26B-A4B-it-qat-GGUF"
  FILE="gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf"
  EXPECTED=14249045120
  echo "Secilen model: 26B-A4B (UD-Q4_K_XL, ~14.2 GB)"
else
  REPO="unsloth/gemma-4-12B-it-qat-GGUF"
  FILE="gemma-4-12B-it-qat-UD-Q4_K_XL.gguf"
  EXPECTED=6716355328
  echo "Secilen model: 12B (UD-Q4_K_XL, ~6.7 GB) - RAM 24 GB altinda"
fi

URL="https://huggingface.co/$REPO/resolve/main/$FILE"
echo "Indiriliyor: $FILE (~$((EXPECTED/1024/1024/1024)) GB)"
curl -L -C - --retry 8 --retry-delay 5 --retry-all-errors -o "$MODELS/$FILE" "$URL"

SZ=$(stat -f%z "$MODELS/$FILE" 2>/dev/null || stat -c%s "$MODELS/$FILE")
if [ "$SZ" -ge "$EXPECTED" ]; then
  echo "INDIRME TAMAM -> $MODELS/$FILE ($((SZ/1024/1024/1024)) GB)"
else
  echo "UYARI: Dosya eksik olabilir ($SZ byte). Scripti tekrar calistir (resume eder)."
fi
