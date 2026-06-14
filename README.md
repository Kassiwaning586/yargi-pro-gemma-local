# Yargı Pro — Local Gemma Stack

opencode arayüzünden, **yerel** Gemma 4 26B QAT modeli (TheTom/llama-cpp-turboquant + turbo3 KV) ve **Yargı Pro remote MCP** ile Türk hukuku araştırması.

## Donanım hedefi
- GPU: NVIDIA RTX 4060 Ti 16 GB (CUDA, sm_89)
- RAM: 32 GB+ önerilir
- OS: Windows 11

## Bileşenler
| | |
|---|---|
| Arayüz | opencode |
| Inference | TheTom/llama-cpp-turboquant (kaynaktan CUDA derleme) |
| Model | unsloth `gemma-4-26B-A4B-it-qat-GGUF : UD-Q4_K_XL` (14.2 GB) |
| KV cache | `--cache-type-v turbo3` |
| MCP | `yargi-mcp-pro` → https://yargi.betaspacestudio.com/mcp (OAuth) |

## Ön-koşullar
- [git](https://git-scm.com/download/win), [CMake](https://cmake.org/download/), [CUDA Toolkit 12.x](https://developer.nvidia.com/cuda-downloads)
- [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) — "Desktop development with C++"
- [Python 3.x](https://www.python.org/downloads/), [Node.js](https://nodejs.org/), [opencode](https://opencode.ai)

## Kurulum (sırayla)

> PowerShell'i repo kökünde aç. Scriptler engellenirse: `Set-ExecutionPolicy -Scope Process Bypass`

```powershell
# 1) On-kosul kontrolu
.\scripts\check-prereqs.ps1

# 2) Inference engine'i derle (~20-40 dk)
.\scripts\build-turboquant.ps1

# 3) Modeli indir (~14.2 GB)
.\scripts\download-model.ps1

# 4) Yargi Pro MCP'yi opencode'a ekle
.\scripts\install-mcp.ps1

# 5) Yerel modeli baslat (bu pencere acik kalsin)
.\scripts\start-server.ps1
```

## Kullanım

1. Yeni bir terminalde repo kökünde `opencode` çalıştır (proje `opencode.json` otomatik okunur).
2. Model seçiminde **`llamacpp / Gemma 4 26B QAT (turbo3, local)`** modelini seç.
3. İlk Yargı Pro aracı çağrıldığında opencode **OAuth** akışını başlatır → tarayıcıdan Yargı Pro'ya giriş yap.
4. Hukuki soru sor; model `yargi-mcp-pro` araçlarıyla karar/mevzuat getirir.

## Ayarlar
- Daha uzun context: `.\scripts\start-server.ps1 -Context 131072` (VRAM sıkışırsa `-Ngl 90` ile birkaç layer'ı CPU'ya taşı).
- Sunucu sağlığı: tarayıcıda `http://127.0.0.1:8080` veya `curl http://127.0.0.1:8080/v1/models`.

## Sorun giderme
- **Derleme hatası:** `.\scripts\check-prereqs.ps1` çıktısındaki eksikleri kur. CUDA + MSVC C++ workload şart.
- **Model yüklenmiyor / VRAM dolu:** `-Ngl` değerini düşür (örn. 80), `-Context`'i küçült.
- **MCP OAuth takılırsa:** opencode'da tekrar dene; gerekirse `~/.local/share/opencode/mcp-auth.json` sil ve yeniden giriş yap.
- **Tool-calling zayıfsa:** `--jinja` aktif olduğundan emin ol (start-server.ps1'de var).
