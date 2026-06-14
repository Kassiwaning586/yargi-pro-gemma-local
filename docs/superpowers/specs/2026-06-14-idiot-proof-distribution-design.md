# Idiot-Proof Dağıtım — Tasarım Dokümanı

**Tarih:** 2026-06-14
**Durum:** Onaylandı (brainstorming → spec)
**Önceki tasarım:** [2026-06-14-yargi-pro-gemma-local-design.md] (temel stack)

## Amaç

Yargı Pro Local stack'ini **teknik olmayan son kullanıcının** tek komutla, derleme yapmadan,
hatadan kurtulabilir şekilde kurabileceği hale getirmek. Hedef: kurulum ~15 dk, terminal/derleme yok,
kurulum sonrası tek-tık başlatma.

## Mevcut durumun kusurları (çözülecek)

1. **MSVC eksik:** `setup-all.ps1` CMake+CUDA+Node kuruyor ama Visual Studio C++ Build Tools'u
   kurmuyor. Bu makinede MSVC vardı; **temiz son-kullanıcı makinesinde derleme patlar.**
2. **Derleme kırılgan:** CUDA+MSVC sürüm uyumu (CudaToolkitDir bug'ı yaşandı), ~40 dk, ~5GB dev araç.
3. **Tek-tık başlatma yok:** kullanıcı `start-server.ps1`'i terminalde çalıştırmak zorunda.
4. **Hata kurtarma yok:** bir adım patlarsa kullanıcı kriptik çıktıyla baş başa kalır.

## Çözüm mimarisi

```
GitHub Actions (CI)                 Son kullanıcı makinesi
─────────────────────               ──────────────────────
build.yml (workflow_dispatch)       install.ps1 / install.sh (tek satir)
  job: win-cuda  ─┐                   1. on-kontroller (GPU/surucu, disk)
  job: mac-arm64 ─┼─> GitHub Release  2. opencode CLI + desktop
  job: mac-x64   ─┘   (prebuilt zip)  3. prebuilt binary INDIR + ac (derleme YOK)
                                      4. bellege gore model (26B/12B)
                                      5. global config (provider + MCP)
                                      6. tek-tik launcher kur
                                      7. (mac) xattr ile karantina temizle
```

**Anahtar fikir:** Derleme **CI'da bir kez** olur, çıktı release'e konur; installer sadece **indirir**.
Son kullanıcı makinesinde CUDA Toolkit, MSVC, CMake, derleme **yok**.

## Bileşenler

### 1. CI Build — `.github/workflows/build.yml`
`workflow_dispatch` ile elle tetiklenir. 3 job:

- **win-cuda** (`windows-latest`): MSVC önyüklü. `Jimver/cuda-toolkit` action ile **CUDA 12.8**
  kurar (sm_120/Blackwell için 12.8 şart; aynı zamanda 75/86/89'u da kapsar). `TheTom/llama-cpp-turboquant`
  klonla → `cmake -B build -DGGML_CUDA=ON
  -DCMAKE_CUDA_ARCHITECTURES="75-real;86-real;89-real;120-real;120-virtual" -DLLAMA_CURL=OFF`
  → `cmake --build build --config Release -j`. (Arch listesi: RTX 20xx=75, 30xx=86, 40xx=89,
  50xx=120; `120-virtual` PTX = ileri kartlar için JIT fallback.) Sonra `build/bin/Release/`'tan
  `llama-server.exe` + tüm `*.dll` (ggml*) + CUDA redist DLL'leri (`cudart64_12.dll`,
  `cublas64_12.dll`, `cublasLt64_12.dll`) tek klasöre toplanıp **zip**'lenir.
- **mac-arm64** (`macos-14`): Metal yerleşik. Klonla → `cmake -B build -DGGML_METAL=ON -DLLAMA_CURL=OFF`
  → build → `build/bin/` zip.
- **mac-x64** (`macos-13`): aynı, Intel.

Tümü `softprops/action-gh-release` ile **sabit tag**'li release'e yüklenir:
`llama-turboquant-win-cuda.zip`, `llama-turboquant-mac-arm64.zip`, `llama-turboquant-mac-x64.zip`.

**Yan fayda:** CI temiz makinede derlediği için MSVC/DLL eksiklerini ortaya çıkarır; Mac binary'si
fiziksel Mac olmadan üretilir.

### 2. Release sürümleme
Binary'ler kod'dan ayrı, sabit bir tag'de tutulur: **`binaries-v1`**. Installer scriptlerinde
`$BIN_RELEASE = 'binaries-v1'` sabiti. Fork güncellenince workflow yeniden çalışır, aynı tag'e
(veya v2'ye) yükler; installer sabiti güncellenir.

### 3. İndiren installer (derleme yok)
`install.ps1` (Win) / `install.sh` (Mac) akışı:
1. **Ön-kontroller** (aşağıda).
2. Paket yöneticisi (choco/brew) — sadece `git` ve indirme için gereken minimum (CUDA/MSVC YOK).
3. Repo'yu klonla/güncelle (scriptler + config + launcher şablonları için).
4. **opencode CLI** (npm) + **desktop** (DMG/exe).
5. **Prebuilt binary'yi indir:** release'ten platforma uygun zip → `vendor/llama-cpp-turboquant/build/bin/`
   altına aç. (`build-turboquant.ps1`/`build-llamacpp.sh` artık son-kullanıcı yolundan çağrılmaz;
   yalnızca CI/geliştirici için repo'da kalır.)
6. **(Yalnız Mac, ÖNEMLİ) iki adım:**
   (a) `xattr -dr com.apple.quarantine "<vendor binary klasoru>"` + `/Applications/Yargı Pro.app` —
   karantinayı temizle. (b) `codesign --force --deep --sign - "<llama-server binary>"` (+ gerekli `.dylib`'ler) —
   **ad-hoc imza.** Apple Silicon (arm64) imzasız binary'yi karantina temizlense bile çalıştırmaz;
   ad-hoc imza şart. (Alternatif: CI'da mac job'ı zip'lemeden önce ad-hoc imzalar; installer yine de
   xattr çalıştırır.)
7. **Model:** `download-model` (VRAM/RAM'e göre 26B veya 12B — mevcut mantık).
8. **Config:** global provider + `yargi-mcp-pro` (mevcut `install-opencode`).
9. **Launcher kur** (aşağıda).

### 4. Tek-tık launcher
Ortak mantık: *`:8080` kapalıysa sunucuyu başlat (gizli) → hazır olunca opencode desktop'ı aç.*

- **Windows:** `scripts/launch.ps1` (sunucu kontrol/başlat + OpenCode aç). Masaüstü + Start Menu'ye
  `.lnk` oluşturulur (`WScript.Shell CreateShortcut`); hedef gizli pencere:
  `powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File launch.ps1`. Kullanıcı terminal görmez.
- **macOS:** `/Applications/Yargı Pro.app` bundle (klasör + `Info.plist` + `Contents/MacOS/launch`
  shell script). install.sh üretir. Çift tıkla açılır, terminal görünmez. `launch`:
  `:8080` kapalıysa `nohup start-server.sh &` → bekle → `open -a OpenCode`.

### 5. Ön-kontroller (idiot-proof çekirdeği)
- **Windows:** `nvidia-smi` var mı? Yoksa **dur** + anlaşılır mesaj: "Bu uygulama NVIDIA ekran kartı
  gerektirir. Kartınız/sürücünüz görünmüyor." **Sürücü sürümü:** CUDA 12.8 ile build edildiği için
  minimum NVIDIA sürücüsü **570.65** (Windows; CUDA 12.8 floor — doğrulandı). `nvidia-smi
  --query-gpu=driver_version` < 570.65 ise **dur** + "NVIDIA sürücünüzü güncelleyin (en az 570.65):
  https://www.nvidia.com/Download/index.aspx".
- **macOS:** Apple Silicon mı (`uname -m` = arm64) / en az ne kadar RAM? Düşükse uyar ama devam et
  (12B'ye düşer).
- **Disk:** hedef diskte ~20 GB boş yoksa **dur** + mesaj.

### 6. Hata yönetimi + log
- Installer'ın tamamı try/catch (PS: `trap`/`try`; bash: `trap ERR`).
- Her şey `install.log`'a yazılır (tee).
- Hata olursa: pencere **kapanmaz**, kırmızı net mesaj: "[ADIM] sırasında sorun oldu. Şu dosyayı
  gönderin: `<yol>\install.log`". Bilinen hatalar için (GPU yok, disk yok, indirme koptu) özel mesaj.
- Win'de `.lnk` hedefi/elevated pencere sonunda `Read-Host` ile bekler (vanish etmesin).

### 7. Devam edebilirlik
- Model indirme `curl -C -` (resume) — mevcut.
- Klonlama: varsa `git pull`. Prebuilt: zaten varsa ve doğruysa tekrar indirmez (boyut/varlık kontrolü).
- choco/brew/npm adımları idempotent ([VAR] geç).

## Donanım kapsamı
- **Windows:** RTX **20xx/30xx/40xx/50xx** (sm_75/86/89/120) → **tek binary** hepsini kapsar
  (CUDA 12.8, sürücü ≥570.65). AMD/Intel GPU kapsam dışı.
- **macOS:** Apple Silicon (arm64) birincil, Intel (x64) best-effort.

## Kapsam dışı (YAGNI)
- Windows servis/otomatik-başlatma (launcher tek-tık yeterli; B seçeneği reddedildi).
- macOS Apple **notarization** / ücretli Developer imzası (gerekmez — lokal **ad-hoc** `codesign --sign -` + xattr yeterli).
- AMD/Intel GPU, Linux.
- Model'i installer'a gömme (14 GB; indirme doğru granülarite).
- Otomatik fork-güncelleme tetikleme (elle workflow_dispatch yeterli).

## Riskler ve azaltımlar
| Risk | Azaltım |
|---|---|
| Sürücü built-against CUDA'yı desteklemiyor | CUDA **12.8** (20xx-50xx kapsar) + sürücü ≥570.65 ön-kontrolü, eskiyse "güncelle" mesajı |
| CI'da CUDA build kırılır | Temiz runner zaten bunu erken yakalar; workflow loglari |
| macOS Gatekeeper/arm64 imzasız binary'yi engeller | `xattr -dr com.apple.quarantine` **+ ad-hoc** `codesign --force --deep --sign -` (Apple Silicon'da imza şart; script otomatik) |
| Prebuilt DLL eksik → exe açılmaz | win-cuda job tüm ggml + cudart/cublas/cublasLt DLL'lerini paketler; CI'da smoke-load testi |
| SmartScreen opencode/desktop exe'yi uyarır | README'de not; imzasız beklenir |

## Değişen/yeni dosyalar (özet)
- **Yeni:** `.github/workflows/build.yml`, `scripts/launch.ps1`, `scripts/get-binary.ps1` +
  `scripts/get-binary.sh` (prebuilt indir/aç), Mac `.app` üreten mantık (install.sh içinde).
- **Değişen:** `install.ps1`/`install.sh` (prechecks + prebuilt indirme + launcher + log),
  `setup-all.ps1`/`setup-all.sh` (build adımı yerine get-binary; MSVC/CUDA kurulumu kaldırılır),
  `install-opencode.*` (launcher kurulumu eklenebilir), README (yeni akış, gereksinimler).
- **Korunur (CI/dev):** `build-turboquant.ps1`, `build-llamacpp.sh` (workflow bunları/aynı cmake'i kullanır).
