# CHANGELOG

## [0.8.0-beta] - 2026-08-25

### Yeni Özellikler (TradeDesk AI)
- **FX Baş Stratejisti:** Gemini AI tabanlı gelişmiş analiz ve strateji sohbet ekranı eklendi.
- **Uzman Hafızası:** Sohbetlerden kural öğrenme ve Firestore üzerinde kalıcı metodoloji oluşturma sistemi kuruldu.
- **TradingView Entegrasyonu:** Canlı grafikler `flutter_inappwebview` ile hem Android hem Windows platformlarında aktif edildi.
- **Watchlist & Senkronizasyon:** Parite favorileme, sembol hafızası ve platformlar arası state senkronizasyonu sağlandı.
- **Hafıza Yönetimi:** Kural silme, aktif/pasif yapma ve kategori bazlı filtreleme özellikleri eklendi.

### Teknik İyileştirmeler ve Düzeltmeler
- **Windows Build Fix:** Modern CMake (3.27+) sürümleriyle oluşan Firebase C++ SDK uyuşmazlığı kalıcı makro yöntemiyle çözüldü.
- **Firebase Auth Köprüsü:** Google Sign-In ile Firebase Auth oturumları birleştirildi, Firestore erişim yetkileri düzeltildi.
- **İkon Modernizasyonu:** Flutter 3.44+ uyumluluğu için `lucide_icons` paketi kaldırılarak standart Material Icons'a geçildi.
- **UI/UX:** Grafik alanı büyütüldü (%65), sayfa scrollable yapıldı ve "Bottom Overflow" hataları giderildi.
- **Initialization:** Uygulama başlangıcındaki Firebase yapılandırması platforma duyarlı hale getirildi.

### Altyapı
- Firebase Core, Auth ve Firestore entegrasyonu tamamlandı.
- `lib/firebase_options.dart` gerçek verilerle yapılandırıldı.
