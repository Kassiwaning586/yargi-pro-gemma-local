#!/usr/bin/env bash
# llama-server'i Gemma 4 26B QAT + turbo3 KV ile baslatir (macOS/Metal).
# Kullanim: ./start-server.sh [context] [ngl] [port]
# Metal turbo3 KV desteklemiyorsa: CACHE_K=f16 CACHE_V=f16 ./start-server.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CTX="${1:-131072}"
NGL="${2:-99}"
PORT="${3:-8080}"
CK="${CACHE_K:-turbo3}"
CV="${CACHE_V:-turbo3}"

EXE="$ROOT/vendor/llama-cpp-turboquant/build/bin/llama-server"
# models/ icindeki gguf'u otomatik bul (12B veya 26B). Birden fazlaysa en buyugu.
MODEL=$(ls -S "$ROOT"/models/*.gguf 2>/dev/null | head -1)

[ -n "$MODEL" ] || { echo "models/ icinde .gguf yok - once download-model.sh"; exit 1; }
[ -f "$EXE" ]   || { echo "llama-server yok: $EXE - once build-llamacpp.sh"; exit 1; }

echo "Baslatiliyor: ctx=$CTX ngl=$NGL port=$PORT kv=$CK/$CV"
"$EXE" -m "$MODEL" -ngl "$NGL" -fa on \
  --cache-type-k "$CK" --cache-type-v "$CV" \
  -c "$CTX" --host 127.0.0.1 --port "$PORT" --jinja
