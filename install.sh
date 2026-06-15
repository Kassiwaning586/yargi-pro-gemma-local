#!/usr/bin/env bash
# Yargi Pro Local - tek satir uzaktan kurulum bootstrap (macOS).
# Kullanim:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.sh)"
set -euo pipefail

REPO_URL="https://github.com/saidsurucu/yargi-pro-gemma-local.git"
DEST="$HOME/GemmaYargiPro"

echo "=== Yargi Pro Local - Kurulum (macOS) ==="

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  echo "[KUR] Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# brew'i PATH'e al (Apple Silicon /opt/homebrew, Intel /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi

# --- git ---
command -v git >/dev/null 2>&1 || brew install git

# --- Repo'yu klonla / guncelle ---
if [ -d "$DEST/.git" ]; then
  echo "[GIT] Guncelleniyor: $DEST"
  git -C "$DEST" pull --ff-only
else
  echo "[GIT] Klonlaniyor: $REPO_URL -> $DEST"
  git clone "$REPO_URL" "$DEST"
fi

# --- Tam kurulum ---
if ! bash "$DEST/scripts/setup-all.sh"; then
  echo "[HATA] Kurulum basarisiz. Log: $DEST/install.log"
  read -r -p "Kapatmak icin Enter" _
fi
