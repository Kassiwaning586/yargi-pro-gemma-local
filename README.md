# Yargı Pro — Local Gemma Stack

opencode arayüzünden, **yerel** Gemma 4 26B QAT modeli (TheTom/llama-cpp-turboquant + turbo3 KV) ve **Yargı Pro remote MCP** ile Türk hukuku araştırması.

> 👩‍⚖️ **Avukat / teknik olmayan kullanıcı mısın?** Bu sayfayı okuma — adım adım, jargonsuz kurulum için **➡️ [KURULUM-REHBERI.md](KURULUM-REHBERI.md)**'ye git.
>
> ⬇️ Aşağısı **geliştiriciler / teknik kullanıcılar** içindir (mimari, CI, derleme, performans).

## ⚡ Tek satır kurulum

**Windows (NVIDIA / CUDA)** — normal PowerShell, UAC'ye **Evet**:

```powershell
irm https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.ps1 | iex
```

**macOS (Apple Silicon / Metal)** — Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.sh)"
```

Gerisi otomatik: ön-kontrol → opencode CLI+desktop → **hazır binary indirme (derleme YOK)** → belleğe göre model → MCP config → tek-tık launcher. Bitince masaüstü (Win) / Launchpad (Mac) içindeki **"Yargı Pro"** kısayoluna çift tıkla — sunucuyu başlatır + opencode'u açar.

### Gereksinimler
- **Windows:** NVIDIA kartı (RTX 20xx–50xx) + **sürücü ≥ 570.65** (installer kontrol eder), ~20 GB boş disk.
- **macOS:** Apple Silicon (Metal), ~20 GB boş disk.
- Kurulum **derleme yapmaz** — binary'ler GitHub'dan hazır iner (~15 dk, çoğu model indirme).
- Kurulum sonrası: **"Yargı Pro"** kısayolu (Win masaüstü / Mac Launchpad) → sunucuyu başlatır + opencode'u açar.

### Desteklenen donanım + otomatik model seçimi
Kurulum belleğe göre **modeli otomatik seçer**:

| Donanım | Seçilen model |
|---|---|
| NVIDIA VRAM ≥ 16 GB **veya** Mac RAM ≥ 24 GB | **Gemma 4 26B-A4B** QAT UD-Q4_K_XL (~14.2 GB) |
| Altında | **Gemma 4 12B** QAT UD-Q4_K_XL (~6.7 GB) |

> ⚠️ **12B daha YAVAŞ üretir — bu normal, bozuk değil.** 12B *dense* (tüm parametreler aktif); 26B ise *MoE* (üretimde ~4B aktif) → 26B hem daha akıllı hem daha hızlı. Ölçüm: **26B ~72 tok/s, 12B ~32 tok/s.** Küçük donanımda 12B çalışıyorsa "yavaş = bozuk" sanma. Ayrıca **ilk istek** (soğuk prompt cache + büyük prefill) her zaman en yavaşıdır; sonraki sorular hızlanır.

- **Windows:** herhangi bir NVIDIA kartı — derleme GPU mimarisini (`compute_cap`) `nvidia-smi`'den **otomatik** algılar (RTX 30/40/50, vb.).
- **macOS:** Apple Silicon (M-serisi, Metal). `turbo3` KV Metal'de **çalışıyor** (M1 Pro'da doğrulandı). Sorun olursa fallback: `CACHE_K=f16 CACHE_V=f16 ./scripts/start-server.sh`.
- İlk kurulum uzun sürer (derleme + model indirme). `start-server` `models/`'daki gguf'u otomatik bulur.

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

## Geliştirici: kaynaktan derleme (opsiyonel)

Normal kullanıcı **bunu yapmaz** — binary'ler GitHub Actions'ta derlenip Release'ten iner. Yalnızca geliştirme / özel derleme için. Gerekir: git, CMake, CUDA Toolkit 12.x + Visual Studio C++ Build Tools (Win) ya da Xcode CLT (Mac), Node.js.

```powershell
.\scripts\build-turboquant.ps1   # Windows: kaynaktan CUDA derleme (GPU mimarisi auto-detect)
.\scripts\download-model.ps1
.\scripts\start-server.ps1
```

CI binary'lerini yeniden üretmek: GitHub'da **build-binaries** workflow'unu çalıştır (`.github/workflows/build.yml`) → `binaries-v1` release'ini günceller.

## Kullanım

1. **"Yargı Pro"** kısayoluna çift tıkla (sunucu başlar + opencode açılır). Manuel: `.\scripts\start-server.ps1` sonra `opencode`.
2. Model seçiminde **`llamacpp / Gemma 4 QAT (local)`** (`gemma-4-qat`) modelini seç.
3. İlk Yargı Pro aracı çağrıldığında opencode **OAuth** akışını başlatır → tarayıcıdan Yargı Pro'ya giriş yap.
4. Hukuki soru sor; model `yargi-mcp-pro` araçlarıyla karar/mevzuat getirir.

## Ayarlar
- **Varsayılan context = 131072 (128K)**, K+V ikisi de `turbo3`. 16 GB'ye sığar (~15.9 GB) ama **çok dar** — başka GPU uygulaması (LM Studio, Chrome vb.) açıkken OOM olur, önce onları kapat.
- Daha güvenli/küçük: `.\scripts\start-server.ps1 -Context 32768`. VRAM hâlâ sıkışırsa `-Ngl 90` ile birkaç layer'ı CPU'ya taşı.
- Sunucu sağlığı: tarayıcıda `http://127.0.0.1:8080` veya `curl http://127.0.0.1:8080/v1/models`.

## Sorun giderme
- **Derleme hatası:** `.\scripts\check-prereqs.ps1` çıktısındaki eksikleri kur. CUDA + MSVC C++ workload şart.
- **`CudaToolkitDir '' does not exist` (configure hatası):** CUDA env değişkenleri (`CUDA_PATH_V13_x`) o oturumda yok. Scriptler bunu otomatik tazeler; manuel derlerken yeni bir terminal aç.
- **Model yüklenmiyor / VRAM dolu:** 16 GB'de model ~14 GB yer kaplar; **LM Studio, Chrome, oyun launcher'ları gibi GPU kullanan uygulamaları kapat** (VRAM'i paylaşıyorlar). Hâlâ sığmazsa `-Ngl` değerini düşür (örn. 80) veya `-Context`'i küçült.
- **Cevap boş geliyor / sadece düşünüyor:** Gemma 4 "thinking" modu açık; önce akıl yürütür (reasoning), sonra cevap verir. Yeterli çıktı token'ı bırak (opencode.json `output: 8192`). Çok kısa `max_tokens` verirsen düşünme bitmeden limite takılır.
- **İndirme 0 byte'ta takılıyor:** HF dosyayı xethub CDN'ine yönlendiriyor; script zaten `curl.exe` ile indiriyor (resume destekli — tekrar çalıştırırsan kaldığı yerden devam eder).
- **MCP OAuth takılırsa:** opencode'da tekrar dene; gerekirse Windows'ta `%USERPROFILE%\.local\share\opencode\mcp-auth.json` dosyasını sil ve yeniden giriş yap. (Global config: `%USERPROFILE%\.config\opencode\opencode.json`.)
- **Tool-calling zayıfsa:** `--jinja` aktif olduğundan emin ol (start-server.ps1'de var).

## Performans (ölçülen — RTX 4060 Ti 16 GB, 128K context, K+V turbo3, -ngl 99)

| Model | Aktif param | Hız | VRAM | Disk (GGUF) |
|---|---|---|---|---|
| **26B-A4B** QAT UD-Q4_K_XL (MoE) | ~4B | **~72 tok/s** | **~15.9 GB** | 13.3 GiB |
| **12B** QAT UD-Q4_K_XL (dense) | 12B | **~32 tok/s** | **~8.7 GB** | 6.3 GiB |

> İlginç: **26B, 12B'den hızlı** — çünkü 26B-A4B bir **MoE** modeli, üretimde yalnızca ~4B parametre aktif; 12B ise dense (tamamı aktif). Yani 26B hem daha akıllı hem daha hızlı, sadece daha çok VRAM ister.

- 128K bağlam TurboQuant (turbo3 KV) sayesinde 16 GB'ye sığıyor; 26B'de VRAM çok dar (~15.9/16 GB) → **diğer GPU uygulamalarını kapat**. 12B'de bol headroom var (~8.7 GB), 12 GB'lik kartlara da uygun.
- Hem 26B hem 12B doğru Türkçe hukuki cevap üretti; Yargı Pro MCP araç çağrıları (tool-calling) opencode'da çalışıyor.
