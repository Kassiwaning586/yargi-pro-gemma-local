#!/usr/bin/env bash
# TheTom/llama-cpp-turboquant fork'unu Metal ile derler (macOS).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor/llama-cpp-turboquant"
REPO="https://github.com/TheTom/llama-cpp-turboquant"

if [ -d "$VENDOR/.git" ]; then
  echo "Repo guncelleniyor: $VENDOR"
  git -C "$VENDOR" pull --ff-only
else
  echo "Klonlaniyor: $REPO"
  git clone --depth 1 "$REPO" "$VENDOR"
fi

cd "$VENDOR"
echo "CMake konfigurasyon (Metal)..."
cmake -B build -DGGML_METAL=ON -DLLAMA_CURL=OFF
echo "Derleniyor..."
cmake --build build --config Release -j

EXE="$VENDOR/build/bin/llama-server"
if [ -f "$EXE" ]; then echo "DERLEME TAMAM -> $EXE"; else echo "UYARI: llama-server bulunamadi"; fi
