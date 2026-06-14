#!/usr/bin/env bash
# opencode CLI + desktop kurar ve global config'e provider + Yargi Pro MCP ekler (macOS).
set -euo pipefail

# --- 1) opencode CLI ---
if command -v opencode >/dev/null 2>&1; then
  echo "[VAR] opencode CLI"
else
  echo "[KUR] opencode CLI (npm)..."
  npm install -g opencode-ai
fi

# --- 2) opencode desktop (DMG) ---
OCVER="v1.17.6"
case "$(uname -m)" in arm64) A=arm64;; *) A=x64;; esac
if [ -d "/Applications/OpenCode.app" ]; then
  echo "[VAR] opencode desktop"
else
  echo "[KUR] opencode desktop ($A)..."
  TMP="$(mktemp -d)"; DMG="$TMP/opencode-desktop.dmg"; MP="$TMP/mnt"
  curl -L --retry 5 -o "$DMG" "https://github.com/anomalyco/opencode/releases/download/$OCVER/opencode-desktop-mac-$A.dmg"
  mkdir -p "$MP"
  hdiutil attach "$DMG" -nobrowse -mountpoint "$MP" >/dev/null
  cp -R "$MP"/*.app /Applications/ 2>/dev/null || true
  hdiutil detach "$MP" >/dev/null 2>&1 || true
fi

# --- 3) global config (provider + MCP, guvenli merge) ---
echo "[CFG] global opencode config..."
node - <<'NODE'
const fs=require("fs"),os=require("os"),path=require("path");
const dir=path.join(os.homedir(),".config","opencode"),file=path.join(dir,"opencode.json");
fs.mkdirSync(dir,{recursive:true});
let cfg={};try{cfg=JSON.parse(fs.readFileSync(file,"utf8"))}catch{}
if(typeof cfg!=="object"||cfg===null||Array.isArray(cfg))cfg={};
if(!cfg["$schema"])cfg["$schema"]="https://opencode.ai/config.json";
if(typeof cfg.provider!=="object"||cfg.provider===null)cfg.provider={};
cfg.provider["llamacpp"]={npm:"@ai-sdk/openai-compatible",name:"llama-server (local)",options:{baseURL:"http://127.0.0.1:8080/v1"},models:{"gemma-4-qat":{name:"Gemma 4 QAT (local)",limit:{context:131072,output:8192}}}};
if(typeof cfg.mcp!=="object"||cfg.mcp===null)cfg.mcp={};
cfg.mcp["yargi-mcp-pro"]={type:"remote",url:"https://yargi.betaspacestudio.com/mcp"};
fs.writeFileSync(file,JSON.stringify(cfg,null,2)+"\n");
console.log("opencode global config yazildi -> "+file);
NODE

echo "opencode CLI + desktop kuruldu ve yapilandirildi."
