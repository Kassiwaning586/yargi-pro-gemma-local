# Yargı Pro — Kurulum Rehberi (Adım Adım)

Bu rehber **avukatlar ve teknik olmayan kullanıcılar** içindir. Bilgisayar bilgisi gerektirmez. Adımları sırayla takip etmen yeterli. Takılırsan en alttaki **"Takılırsan"** bölümüne bak.

---

## Bu nedir?

Bilgisayarına, **kendi bilgisayarında çalışan** bir yapay zekâ hukuk asistanı kuruyoruz. Bu asistan Yargı Pro'nun hukuk veritabanına bağlanır; Yargıtay, Danıştay, Anayasa Mahkemesi kararlarını ve mevzuatı bulur, özetler, sorularını yanıtlar.

Asistan **senin bilgisayarında** çalıştığı için hızlıdır ve bir kez kurulduktan sonra hep hazırdır.

---

## Önce: Bilgisayarın uygun mu?

**Windows bilgisayarı kullanıyorsan:**
- **"NVIDIA" marka ekran kartı** olmalı (çoğu oyun bilgisayarında vardır).
- Boş disk alanı: en az **20 GB**.

**Mac kullanıyorsan:**
- **Apple M1 / M2 / M3 / M4** işlemcili bir Mac olmalı.
- Boş disk alanı: en az **20 GB**.

> Emin değil misin? Sorun değil. Kurulum en başta otomatik kontrol eder; bilgisayarın uygun değilse **anlaşılır bir Türkçe mesajla durur**, sana ne gerektiğini söyler. Bir şeyi bozma ihtimalin yok.

---

## WINDOWS — Adım Adım

**1. Programı aç.**
Klavyede **Windows tuşuna** bas. Açılan arama kutusuna **PowerShell** yaz. Çıkan **"Windows PowerShell"**e tıkla. Mavi (veya siyah) bir pencere açılır.

**2. Şu yazıyı kopyala.**
Aşağıdaki kutunun **sağ üst köşesindeki kopyala simgesine** tıkla (yazının tamamı kopyalanır):

```
irm https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.ps1 | iex
```

**3. Yapıştır ve başlat.**
Az önce açtığın mavi pencerenin içine **sağ tıkla** (sağ tıklamak yapıştırır). Sonra klavyede **Enter**'a bas.

**4. İzin ver.**
"Bu uygulamanın cihazınızda değişiklik yapmasına izin veriyor musunuz?" diye bir pencere çıkarsa **Evet**'e tıkla.

**5. Bekle. (En önemli adım!)**
Şimdi ekranda **bir sürü yazı akmaya başlar.** Bu tamamen **normaldir** — bir şey bozmuyorsun, sadece kurulum çalışıyor. Kurulum internetten büyük dosyalar indirir; bilgisayarına ve internet hızına göre **15 dakika ile 1 saat** sürebilir.
👉 **Pencereyi kapatma, bilgisayarı uyutma.** Çayını al, bekle.

**6. Bittiğini anla.**
Ekranda **"HER SEY HAZIR"** yazısını görürsün ve **masaüstünde "Yargı Pro"** adında yeni bir simge belirir.

**7. Programı aç.**
Masaüstündeki **"Yargı Pro"** simgesine **çift tıkla.** Kısa bir hazırlığın ardından program açılır. (İlk açılış biraz uzun sürebilir, normaldir.)

**8. Giriş yap.**
İlk kullanımda tarayıcı açılıp **Yargı Pro hesabınla giriş** yapmanı isteyebilir. Her zamanki gibi giriş yap.

**9. Sor.**
Artık hukuki sorunu yazabilirsin. Örnek:
> *"Kira tespiti davasında güncel bir Yargıtay kararı bul ve özetle."*

**Sonraki günler:** Bir daha kurulum yok. Sadece masaüstündeki **"Yargı Pro"** simgesine çift tıkla, yeter.

---

## MAC — Adım Adım

**1. Terminal'i aç.**
Sağ üstteki **büyüteç** simgesine (veya **Cmd + Boşluk**) tıkla, **Terminal** yaz, Enter'a bas. Bir pencere açılır.

**2. Şu yazıyı kopyala:**

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/saidsurucu/yargi-pro-gemma-local/main/install.sh)"
```

**3. Yapıştır ve başlat.**
Terminal penceresine **Cmd + V** ile yapıştır, **Enter**'a bas.

**4. Şifre isterse.**
Mac açılış şifreni yaz (yazarken ekranda **görünmez**, bu normaldir), Enter'a bas.

**5. Bekle.**
Yazılar akar — normaldir. **15 dakika – 1 saat** sürebilir. Pencereyi kapatma.

**6. Programı aç.**
Bitince **Launchpad**'de (uygulamalar ekranı) **"Yargı Pro"** çıkar. Tıkla.

**7. Giriş yap, sor.**
Program açılır → Yargı Pro hesabınla giriş yap → hukuki sorunu yaz.

**Sonraki günler:** Launchpad'den **"Yargı Pro"**ya tıkla, yeter.

---

## Takılırsan

- **Ekranda kırmızı bir yazı / hata görürsen** ya da bir şey çalışmazsa: **ekran görüntüsü al** (Windows: `Win + Shift + S`, Mac: `Cmd + Shift + 4`) ve yetkiliye gönder. Kurulum, olanları bir kayıt dosyasına da yazar; o dosyayı istersek göndermeni rica ederiz, gerisini biz hallederiz.
- **Kurulumu yanlışlıkla kapattıysan:** Aynı komutu (2. adımdaki yazıyı) tekrar çalıştır — **kaldığı yerden devam eder**, baştan inmez.
- **"Sürücünü güncelle" derse (Windows):** Ekran kartı sürücün eski demektir. NVIDIA'nın güncelleme programını (GeForce Experience) açıp güncelle, sonra komutu tekrar çalıştır.

---

Hepsi bu kadar. Teknik bilgiye gerek yok — takılırsan **fotoğraf çek, gönder**, biz çözeriz. 🙂
