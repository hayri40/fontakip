# FontTakip - Yatırım Takip Uygulaması

Mobil yatırım takip ve portföy yönetimi uygulaması.

## Özellikler

### 📊 Temel Özellikler
- Forex (Döviz) izleme
- Altın fiyatları
- Kripto para verilerine erişim
- Portföy yönetimi
- Yatırım araçları

### 🛠️ Yatırım Araçları
- **Yatırım Planlayıcısı** - Varlık tahsisi hesapla
- **Portföy Dengeleyi** - Target ağırlıklara göre ayarla
- **Bileşik Faiz Hesaplama** - Gelecek değer tahmini
- **Performans Takip** - Getirileri takip et

### 💾 Yedekleme Sistemi
- **Yerel Yedekleme** - JSON formatında veri dışa aktarma
- **Bulut Yedekleme Altyapısı** - Gelecekte Google/API desteği
- **Google Sign-In** - Bulut hesabı entegrasyonu

### 🔄 Otomatik Güncelleme Sistemi
- **Manuel Sürüm Kontrolü** - GitHub version.json üzerinden
- **APK İndirme** - USB olmadan direkt güncelleme
- **Android Uyumlu Kurulum** - FileProvider + MethodChannel
- **GitHub Actions** - Tamamen otomatik yayınlama

## Kullanıcı Rehberi

### Güncellemeleri Kontrol Etme

```
Ayarlar → Güncellemeler → Güncellemeleri Kontrol Et
```

1. **Yeni sürüm varsa**
   - `🎉 Yeni sürüm mevcut` mesajı görüntülenir
   - Sürüm bilgileri gösterilir

2. **APK İndirme**
   - `[ APK İndir ]` butonuna tıkla
   - İndirme ilerleme çubuğu gösterilir
   - İndirme tamamlandıktan sonra Android paket yükleyici açılır

3. **Kurulum**
   - Android "Güncellemeyi Yükle" ekranında `[ Yükle ]` basılır
   - Uygulama otomatik güncellenir

### Bulut Yedekleme

```
Ayarlar → ☁ Bulut Yedekleme
```

- Google hesabıyla oturum açın
- Verilerinizi buluta yedekleyin (yakında aktif)
- Buluttan geri yükleyin (yakında aktif)

## Geliştirici Rehberi

### Sistem Mimarisi

#### Güncelleme Sistemi
- **UpdateService** - GitHub version.json'dan versyon bilgisi çeker
- **UpdateDownloadService** - APK indir, Android paket yükleyiciyi aç
- **version.json** - GitHub master branch'te barındırılır

#### Bulut Yedekleme
- **CloudBackupService** - Sağlayıcı bağımsız abstract interface
- **GoogleCloudBackupService** - Google Sign-In implementasyonu
- **AuthState** - Oturum bilgisini yönetir

#### Yerel Yedekleme
- **BackupService** - JSON formatında veri yedekle/geri yükle

### Yeni Sürüm Yayınlama

**Tek Yapılacak İşlem:**

```bash
# 1. pubspec.yaml içinde sürümü güncelle
version: 1.0.2+3

# 2. release_notes.json içindeki notes listesini güncelle

# 3. Git'e commit ve push
git add pubspec.yaml release_notes.json
git commit -m "Bump version to 1.0.2"
git push origin master
```

**GitHub Actions otomatik olarak:**
1. ✅ APK derler
2. ✅ GitHub Release oluşturur
3. ✅ APK'yı release'e yükler
4. ✅ pubspec.yaml sürümünü release_notes.json içine otomatik yazar
5. ✅ release_notes.json içindeki notlarla release body oluşturur
6. ✅ version.json günceller
7. ✅ Kullanıcılar otomatik güncelleme görebilir

### Workflow Dosyası

`.github/workflows/release.yml`

- **Tetikleyici**: master branch'e `pubspec.yaml` değişikliği ile push veya manuel workflow çalıştırma
- **Adımlar**:
  1. Flutter kurulumu
  2. Bağımlılıkları yükle
  3. Sürümü pubspec.yaml'dan oku
  4. APK derle (release)
  5. release_notes.json içindeki notes alanını doğrula
  6. pubspec sürümünü release_notes.json ve version.json içine otomatik yaz
  7. GitHub Release oluştur (vX.X.X tag'ı)
  8. APK'yı release'e yükle
  9. Üretilen metadata dosyalarını master'a push et

### Önemli Dosyalar

```
fontakip/
├── .github/workflows/
│   └── release.yml              # GitHub Actions workflow
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml  # FileProvider yapılandırması
│   │   ├── res/xml/
│   │   │   └── provider_paths.xml  # Dosya erişim yolları
│   │   └── kotlin/com/fontakip/app/
│   │       └── MainActivity.kt   # APK kurulum MethodChannel
│   └── app/build.gradle.kts     # Android build config
├── lib/
│   ├── services/
│   │   ├── update_service.dart              # Sürüm kontrolü
│   │   ├── update_download_service.dart     # APK indirme
│   │   └── cloud_backup_service.dart        # Bulut yedekleme
│   └── screens/
│       ├── settings_screen.dart             # Ayarlar + Güncellemeler
│       └── update_notes_screen.dart         # Güncelleme notları
├── pubspec.yaml                 # Uygulama sürümü
├── release_notes.json           # Özel release notları (version alanı otomatik senkronlanır)
└── version.json                 # GitHub'daki sürüm bilgisi
```

### Sürüm Kontrolü Mantığı

**pubspec.yaml:**
```yaml
version: 1.0.1+2
# 1.0.1 = Semantic version
# 2 = Build number
```

**release_notes.json:**
```json
{
  "version": "1.0.1",
  "notes": ["Özel release notları"]
}
```

- `version` alanı workflow tarafından `pubspec.yaml` üzerinden otomatik güncellenir.
- Manuel olarak sadece `notes` listesini düzenlemen gerekir.

**version.json:**
```json
{
  "version": "1.0.1",
  "releaseDate": "2026-08-12",
  "notes": ["Özel release notları"],
  "apkUrl": "https://github.com/.../releases/download/v1.0.1/fontakip-1.0.1.apk"
}
```

### Testing

```bash
# Testler çalıştır
flutter test

# Release APK derle
flutter build apk --release

# APK boyutunu kontrol et
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

## Güvenlik

- ❌ Token içeren URL'ler kullanılmaz
- ✅ GitHub PAT yerine GITHUB_TOKEN kullanılır
- ✅ Dosya izinleri FileProvider ile yönetilir
- ✅ Content URI'ler file:// yerine tercih edilir

## Sorun Giderme

### GitHub Actions Workflow Başlamıyor
- `.github/workflows/release.yml` dosyasının var olduğunu kontrol et
- Workflow'ın master branch'e push üzerinde çalışacak şekilde ayarlandığını doğrula

### APK Kurulum Ekranı Açılmıyor
- Android 12+ kullanıyor musunuz? FileProvider yapılandırması gerekli
- `REQUEST_INSTALL_PACKAGES` izni AndroidManifest.xml'de tanımlandı mı?

### Version Güncellenmiyor
- pubspec.yaml sürümü güncelledin mi?
- APK'yı kaldırıp yeniden kurdu musunuz?

## İletişim

Hata raporları ve öneriler için GitHub Issues kullanın.

---

**Sürüm:** 1.0.1  
**Son Güncelleme:** 2026-08-12
