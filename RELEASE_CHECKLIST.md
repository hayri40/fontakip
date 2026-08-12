# FontTakip Release Checklist

Yeni sürüm yayınlamak için bu adımları takip et.

## 🚀 Otomatik Release Süreci

### 1️⃣ Sürümü Güncelle

`pubspec.yaml` dosyasını aç ve sürümü güncelle:

```yaml
# Eski
version: 1.0.1+2

# Yeni
version: 1.0.2+3
```

**Format Kuralı:**
- `1.0.2` = Semantic Version (MAJOR.MINOR.PATCH)
- `3` = Build Number (her build'de +1)

### 2️⃣ Git'e Commit ve Push

```bash
git add pubspec.yaml
git commit -m "Bump version to 1.0.2"
git push origin master
```

### 3️⃣ GitHub Actions Başlasın

- GitHub repository'ye git
- **Actions** sekmesine tıkla
- **Build and Release** workflow'unu gözlemle

**Workflow Aşamaları:**
1. ✅ Checkout code
2. ✅ Install Flutter
3. ✅ Get dependencies
4. ✅ Extract version from pubspec.yaml
5. ✅ Build APK (flutter build apk --release)
6. ✅ Create GitHub Release with tag (v1.0.2)
7. ✅ Upload APK to release assets
8. ✅ Update version.json
9. ✅ Push version.json back to master

### 4️⃣ Başarılı Yayın Kontrol Et

**GitHub Releases:**
```
https://github.com/hayri40/fontakip/releases
```

Yeni release görünmeli:
- Tag: `v1.0.2`
- APK dosyası: `fontakip-1.0.2.apk`

**version.json Güncellemesi:**
```
https://raw.githubusercontent.com/hayri40/fontakip/master/version.json
```

Dosya güncellenmiş olmalı:
```json
{
  "version": "1.0.2",
  "releaseDate": "2026-08-12",
  "notes": ["Otomatik olarak GitHub Actions tarafından..."],
  "apkUrl": "https://github.com/.../releases/download/v1.0.2/fontakip-1.0.2.apk"
}
```

---

## ⚠️ Manuel Yayınlama Gerekirse

GitHub Actions başarısız olursa:

### Adım 1: APK Manuel Derle

```bash
flutter clean
flutter pub get
flutter build apk --release
```

APK dosyası: `build/app/outputs/flutter-apk/app-release.apk`

### Adım 2: GitHub Release Oluştur

1. GitHub repository'ye git
2. **Releases** → **Create a new release**
3. Tag: `v1.0.2`
4. Title: `FontTakip 1.0.2`
5. APK dosyasını upload et
6. **Publish release** basılır

### Adım 3: version.json Manuel Güncelle

```json
{
  "version": "1.0.2",
  "releaseDate": "2026-08-12",
  "notes": [
    "Yeni özellikler eklendi",
    "Hata düzeltmeleri yapıldı"
  ],
  "apkUrl": "https://github.com/hayri40/fontakip/releases/download/v1.0.2/app-release.apk"
}
```

```bash
git add version.json
git commit -m "Update version.json for v1.0.2 [skip ci]"
git push origin master
```

---

## 🔍 Sorun Giderme

### Workflow Çalışmıyor

```bash
# Workflow dosyasını kontrol et
cat .github/workflows/release.yml

# Syntax kontrol et
git diff HEAD~1 .github/workflows/release.yml
```

### APK Build Hatası

```bash
# Local'de test et
flutter clean
flutter pub get
flutter build apk --release -v

# Hata mesajını kopyala ve GitHub Actions'ta karşılaştır
```

### version.json Güncellenmiyor

- Workflow'un "Commit and push version.json" adımında başarılı olduğunu kontrol et
- GitHub token'ın doğru izinlere sahip olduğunu doğrula

---

## 📋 Kontrol Listesi

Yeni sürüm öncesi:

- [ ] Tüm testler geçiliyor mi? (`flutter test`)
- [ ] Release APK lokal'de derlenebiliyor mi?
- [ ] Version numarası artırıldı mı?
- [ ] GitHub Actions workflow'u güncellenmiş mi?
- [ ] README güncellenmiş mi? (opsiyonel)

---

## 🎯 Sürüm Numarası Rehberi

**Semantic Versioning (MAJOR.MINOR.PATCH):**

```
1.0.0 → 1.0.1 = Patch (hata düzeltme)
1.0.0 → 1.1.0 = Minor (yeni özellik)
1.0.0 → 2.0.0 = Major (büyük değişiklik)
```

**Build Number:**
- Her release'de +1 artar
- APK kurulumda version karşılaştırması için kullanılır

**Örnek Sürüm Tarihi:**
```
v0.1.0   → İlk MVP yayını
v1.0.0   → Stabil sürüm
v1.0.1   → Hata düzeltme
v1.1.0   → Yeni özellik
v2.0.0   → Büyük refactor
```

---

## 💡 İpuçları

- GitHub Actions logları **Actions** → **Build and Release** → ilgili run'da görülebilir
- `[skip ci]` tag'ı workflow'un yeniden çalışmasını engeller
- version.json'daki apkUrl GitHub release URL'si olmalı
- APK dosya adı `fontakip-{version}.apk` formatında olmalı

---

**Son Güncelleme:** 2026-08-12
