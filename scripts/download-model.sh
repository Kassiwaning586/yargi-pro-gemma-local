#!/usr/bin/env bash
# Gemma 4 26B-A4B QAT UD-Q4_K_XL GGUF'u models/ klasorune indirir (curl, resume).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS="$ROOT/models"; mkdir -p "$MODELS"
FILE="gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf"
URL="https://huggingface.co/unsloth/gemma-4-26B-A4B-it-qat-GGUF/resolve/main/$FILE"
EXPECTED=14249045120

echo "Indiriliyor: $FILE (~14.2 GB)"
curl -L -C - --retry 8 --retry-delay 5 --retry-all-errors -o "$MODELS/$FILE" "$URL"

SZ=$(stat -f%z "$MODELS/$FILE" 2>/dev/null || stat -c%s "$MODELS/$FILE")
if [ "$SZ" -ge "$EXPECTED" ]; then
  echo "INDIRME TAMAM -> $MODELS/$FILE ($((SZ/1024/1024/1024)) GB)"
else
  echo "UYARI: Dosya eksik olabilir ($SZ byte). Scripti tekrar calistir (resume eder)."
fi
