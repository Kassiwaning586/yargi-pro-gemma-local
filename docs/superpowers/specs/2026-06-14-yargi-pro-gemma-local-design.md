# Yargı Pro Local Stack — Tasarım Dokümanı

**Tarih:** 2026-06-14
**Durum:** Onaylandı (brainstorming → spec)

## Amaç

Yargı Pro (remote MCP) hukuki araştırma araçlarını, **tamamen yerel çalışan bir LLM beyni** üzerinden
kullanmak. Arayüz `opencode`, model yerel `llama-server` üzerinde Gemma 4 26B-A4B QAT,
hukuki veri kaynağı ise Yargı Pro'nun remote MCP sunucusu olacak.

Model yereldir; hukuki içerik yine Yargı Pro'nun sunucusundan gelir (kullanıcı bu servisin sahibidir).

## Mimari

```
Kullanıcı
   │
   ▼
opencode (arayüz)
   │
   ├── provider (proje opencode.json) ──> TheTom/llama-cpp-turboquant
   │                                       llama-server  http://127.0.0.1:8080/v1
   │                                       Model: unsloth Gemma 4 26B-A4B QAT UD-Q4_K_XL
   │                                       KV cache: --cache-type-v turbo3
   │
   └── mcp (global config, resmî snippet) ─> yargi-mcp-pro  (type: remote, OAuth)
                                             https://yargi.betaspacestudio.com/mcp
```

**Veri akışı:** Kullanıcı opencode'a soru sorar → yerel Gemma modeli tool-calling ile
Yargı Pro MCP araçlarını çağırır → mahkeme kararları / mevzuat context'e gelir →
model Türkçe cevabı üretir.

## Donanım (doğrulandı)

| | |
|---|---|
| CPU | AMD Ryzen 5 7600 (6C/12T) |
| RAM | 64 GB |
| GPU | NVIDIA RTX 4060 Ti **16 GB** (sürücü 595.79) |
| OS | Windows 11 Pro |

## Bileşen Kararları

| Bileşen | Seçim | Gerekçe |
|---|---|---|
| Arayüz | **opencode** | İstenen agentic TUI/desktop arayüz |
| Inference engine | **TheTom/llama-cpp-turboquant** | TurboQuant+ KV cache (turbo3); Windows'ta hazır binary yok → kaynaktan CUDA derleme |
| Model | **unsloth `gemma-4-26B-A4B-it-qat-GGUF : UD-Q4_K_XL`** (14.2 GB) | QAT + Unsloth Dynamic 2.0; Q4_0'dan hem daha küçük hem daha doğru |
| KV cache | **`--cache-type-v turbo3`** | ~4.3× KV sıkıştırma → uzun mahkeme kararları için context |
| MCP | **`yargi-mcp-pro`** → `https://yargi.betaspacestudio.com/mcp` | Yargı Pro resmî remote endpoint; auth = OAuth (manuel token yok) |

### Neden bu model
- **MoE (26B toplam / ~4B aktif):** dense 27B'den çok daha hızlı; CPU offload cezası minimal.
- **QAT + UD-Q4_K_XL:** bf16'ya yakın kalite, 14.2 GB → 16 GB karta ~1.8 GB headroom ile sığar.
- **256K context + 140+ dil (Türkçe):** uzun hukuki belgeler için uygun.

### Neden TheTom fork (stock llama.cpp değil)
`turbo3` KV cache tipi stock llama.cpp'de yoktur; sadece TheTom/llama-cpp-turboquant fork'unda bulunur.
Windows için hazır binary yayınlanmadığından **kaynaktan CUDA derleme zorunludur**.

## Repo Yapısı

```
yargi-pro-gemma-local/
├─ opencode.json              # SADECE local model provider (baseURL http://127.0.0.1:8080/v1)
├─ scripts/
│   ├─ check-prereqs.ps1      # CUDA Toolkit / MSVC Build Tools / CMake / git kontrolü
│   ├─ build-turboquant.ps1   # TheTom fork'u klonla + CUDA ile derle
│   ├─ download-model.ps1     # UD-Q4_K_XL GGUF'u HF'ten indir
│   ├─ start-server.ps1       # llama-server'ı turbo3 + CUDA flag'leriyle başlat
│   └─ install-mcp.ps1        # resmî snippet: yargi-mcp-pro'yu global opencode config'e ekle
├─ models/                    # GGUF dosyaları (.gitignore)
├─ .gitignore
└─ README.md                  # kurulum + kullanım adımları
```

## Konfigürasyon Detayları

### Proje `opencode.json` (local model provider)
OpenAI-uyumlu yerel endpoint olarak `llama-server`'ı tanımlar:
- `baseURL: http://127.0.0.1:8080/v1`
- Model adı: `gemma-4-26b-qat`
- API key gerektirmez (yerel; dummy değer kullanılır).

### Global MCP config (`%USERPROFILE%\.config\opencode\opencode.json`)
`install-mcp.ps1` kullanıcının verdiği resmî snippet'i birebir çalıştırır:
```json
"mcp": {
  "yargi-mcp-pro": { "type": "remote", "url": "https://yargi.betaspacestudio.com/mcp" }
}
```
Auth manuel değil — opencode 401 alınca OAuth akışını yürütür; kullanıcı tarayıcı/masaüstü
üzerinden Yargı Pro'ya giriş yapar. Token `~/.local/share/opencode/mcp-auth.json` içinde saklanır.

opencode global + proje config'lerini birleştirir → MCP global'den, model provider projeden gelir.

### `start-server.ps1` (llama-server) hedef flag'ler
```
llama-server -m models\gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf `
  -ngl 99 -fa on --cache-type-k q8_0 --cache-type-v turbo3 `
  -c 65536 --host 127.0.0.1 --port 8080 --jinja
```
- `-ngl 99`: tüm layer'ları GPU'ya (VRAM sıkışırsa düşürülür).
- `-fa on`: Flash-Attention (turbo3 için önerilen).
- `--cache-type-v turbo3`: TurboQuant KV sıkıştırma.
- `--jinja`: tool-calling için chat template / tool parser.
- `-c 65536`: başlangıç 64K context; ihtiyaca göre artırılır.

## VRAM / Context Planı

- Weight ~14.2 GB + turbo3 KV → **32–64K context rahat**.
- 256K istenirse: context'i `-c` ile büyüt, gerekirse `-ngl`'i düşürerek 1-2 layer'ı CPU'ya taşı
  (MoE aktif ~4B olduğundan throughput cezası düşük; 64 GB RAM yeterli).

## Kurulum Akışı (README)

1. `check-prereqs.ps1` — CUDA Toolkit, MSVC Build Tools, CMake, git var mı? Eksikleri raporla.
2. `build-turboquant.ps1` — fork'u klonla, `cmake -B build -DGGML_CUDA=ON && cmake --build build -j`.
3. `download-model.ps1` — UD-Q4_K_XL GGUF'u `models/`'a indir.
4. `start-server.ps1` — llama-server'ı başlat (turbo3 + CUDA).
5. `install-mcp.ps1` — yargi-mcp-pro'yu global config'e ekle.
6. opencode aç → Yargı Pro OAuth login → yerel `gemma-4-26b-qat` modelini seç.
7. Hukuki soru sor; model MCP araçlarını çağırarak cevap üretir.

## Riskler ve Azaltımlar

| Risk | Azaltım |
|---|---|
| Gemma agentic/tool-calling akışında zayıf kalabilir | assistant-uyumlu QAT model + `--jinja` tool parser; gerekirse system prompt ile araç kullanımını teşvik |
| Windows CUDA derlemesi başarısız olabilir | `check-prereqs.ps1` önceden doğrular; README'de CPU/partial-offload fallback notu |
| 16 GB VRAM context'i sınırlayabilir | turbo3 KV + ayarlanabilir `-ngl`/`-c`; CPU overflow için 64 GB RAM |
| MCP OAuth akışı opencode'da takılabilir | resmî snippet birebir kullanılır; sorunda manuel `mcp-auth.json` / yeniden login |

## Kapsam Dışı (YAGNI)

- Yargı Pro MCP sunucusunu self-host etmek (remote kalır).
- TQ4_1S weight yeniden-quantize (UD-Q4_K_XL yeterli; gerekirse sonra eklenir).
- Speculative decoding / MTP draft model (ilk sürümde değil).
- Çoklu model / model yönetim arayüzü.
