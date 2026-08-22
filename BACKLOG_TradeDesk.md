# TradeDesk Master Plan

## Proje Tanımı

TradeDesk, FonTakip ekosisteminin masaüstü (Windows) uygulamasıdır.

Ana amaç:

- Portföy yönetimi
- Forex analizleri
- AI Uzman sistemi
- Eğitim kaynaklarından öğrenen uzmanlar
- Grafik analizleri

TradeDesk ve FonTakip aynı kullanıcı hesabını ve aynı Firestore verisini kullanır.

---

# Genel Mimari

## Mobil

FonTakip Mobile

Kullanım amacı:

- Günlük portföy takibi
- Fon ve hisse işlemleri
- Mail sistemi
- Bulut senkronizasyon
- AI sonuçlarını görüntüleme

## Masaüstü

TradeDesk Desktop

Kullanım amacı:

- AI Uzman eğitimi
- Video analizi
- PDF analizi
- Grafik analizi
- Forex çalışmaları
- Gelişmiş portföy yönetimi

---

# Teknoloji Kararları

## Desktop

- Flutter Desktop (Windows)

## AI

- Ollama
- Qwen

## Uzman Hafızası

- ChromaDB

## Kullanıcı Verileri

- Firestore

---

# TradeDesk Ana Menü

Üst Menü:

- Portföyüm
- Fonlar
- Hisseler
- Forex
- AI Uzman

Sağ Üst:

- Ayarlar
- Araçlar
- Senkronizasyon
- Hesap

---

# Açılış Ekranı

Varsayılan sekme:

Portföyüm

Gösterilecek bilgiler:

- Toplam Portföy Değeri
- Toplam K/Z
- Günlük K/Z
- Fon Dağılımı
- Hisse Dağılımı
- Son İşlemler
- Son Senkronizasyon
- Mail Durumu

---

# Sol Menü Yapısı

## Portföyüm

- Dashboard
- Portföy Dağılımı
- Performans
- İşlem Geçmişi
- Mail Raporları

## Fonlar

- Fon Listesi
- Fon Karşılaştırma
- Favoriler
- TEFAS Analizleri
- Fon Geçmişi

## Hisseler

- Hisse Listesi
- Portföy
- Temettüler
- Analizler
- Favoriler

## Forex

- Grafikler
- Pariteler
- Demo İşlemler
- Backtest
- Forex Günlüğü

## AI Uzman

- Uzman Yönetimi
- Kaynak Kütüphanesi
- Öğrenilen Kurallar
- Sohbet Geçmişi
- Video Analizleri

---

# Alt İşlem Paneli

Alt kısımda açılır panel olacak.

Fonlar:

- Fon Al
- Fon Sat

Hisseler:

- Hisse Al
- Hisse Sat

Forex:

- Long
- Short
- Demo İşlem

---

# AI Uzman Sistemi

Yeni uzman oluşturulabilir.

Örnek uzmanlar:

- ICT Uzmanı
- Price Action Uzmanı
- Fon Uzmanı

Her uzmanın:

- Kendi hafızası
- Kendi kaynakları
- Kendi öğrenme geçmişi

olur.

---

# Uzman Öğrenme Sistemi

Desteklenen kaynaklar:

- YouTube
- MP4
- PDF
- TXT

Akış:

Kaynak
↓
Analiz
↓
Öğrenilen Kurallar
↓
Kullanıcı Onayı
↓
Uzman Hafızası

Uzman kendi kendine öğrenmez.

Kullanıcı onayı zorunludur.

---

# Uzman Yönetimi

Uzman:

- Düzenlenebilir
- Silinebilir
- Bilgi unutabilir
- Dışa aktarılabilir
- İçe aktarılabilir

---

# Uzmanlar Arası İlişki

Uzmanlar birbirlerinin hafızalarını kullanamaz.

Uzmanlar birbirlerine bilgi öğretemez.

Uzmanlar birbirlerinin bilgi tabanlarını değiştiremez.

İleride aynı grafik için farklı görüş sunabilirler.

Örnek:

ICT Uzmanı:
Long

Price Action Uzmanı:
Bekle

Ancak uzmanlar birbirlerinden öğrenmez.

---

# Grafik Analizi

Grafik doğrudan uzman tarafından yorumlanmaz.

Önce ortak Grafik Okuyucu çalışır.

Akış:

Screenshot
↓
Grafik Okuyucu
↓
Standart Veri Modeli
↓
Uzman
↓
Analiz

---

# Uzman Yanıt Stili

Uzman hiçbir zaman sadece sonuç vermez.

Yanıt formatı:

Trend:
...

Yapı:
...

Sinyal:
...

Güven:
...

Sebep:
...

Kaynak:
...

Uzman kararlarının nedenini açıklamak zorundadır.

---

# Senkronizasyon

## Firestore ile Senkronlanacak

- Portföy
- Fonlar
- Hisseler
- Tercihler
- Mail ayarları
- Kullanıcı hesap bilgileri
- Uzman metadata bilgileri

## Senkronlanmayacak

- MP4 arşivleri
- PDF arşivleri
- ChromaDB verileri
- Uzman eğitim dosyaları

---

# Mobil - Masaüstü Ayrımı

Mobil:

- Sonuç görüntüleme
- AI görüşlerini okuma
- Portföy yönetimi

Masaüstü:

- Uzman eğitme
- Video yükleme
- PDF yükleme
- Grafik analizi
- AI işlemleri

AI operasyonlarının merkezi TradeDesk olacaktır.
`