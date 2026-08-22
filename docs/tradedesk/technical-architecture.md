# TradeDesk Teknik Mimari ve Tasarım Dokümanı

## 1. Amaç ve sınırlar

Bu doküman, TradeDesk projesinin teknik çözüm mimarisini ve MVP geliştirme sırasını tanımlar. Her karar mevcut iş hedefleriyle uyumlu ve korunur:

- TradeDesk ayrı bir Windows masaüstü uygulamasıdır.
- Flutter Desktop kullanılır.
- FonTakip Mobile ile aynı kullanıcı hesabı ve aynı Firestore verisi paylaşılır.
- Firestore ortak veri kaynağıdır.
- AI katmanı Ollama + Qwen kullanır.
- Uzman hafızası ChromaDB ile tutulur.
- Her uzman kendi hafızasına, kaynaklarına ve öğrenme geçmişine sahiptir.
- Uzmanlar arasında hafıza paylaşımı, öğrenme ve veri değiştirme yoktur.
- Kullanıcı onayı zorunludur.

---

## 2. Sistem genel görünüm

TradeDesk, FonTakip ekosisteminin yatırım analizi ve uzman öğrenme odaklı masaüstü yüzüdür. Mobil uygulama sadece sonuç ve görüş görüntülerken, TradeDesk uzman eğitimi, kaynak analizi, grafik okuma ve gelişmiş AI iş akışlarını üstlenir.

Ana akışlar:

- Portföy/varlık yönetimi
- Fon, hisse, forex takibi
- AI uzman yönetimi
- Kaynak analizi ve öğrenme
- Grafik okuma ve yorumlama
- Firestore senkronizasyonu

Sistem üç ana katmanda çalışır:

1. Presentation Layer (Flutter Desktop UI)
2. Application Layer (state management, use cases, orchestration)
3. Data & AI Layer (Firestore, ChromaDB, Ollama, file storage, graph reader)

---

## 3. Katman mimarisi

### 3.1 Presentation Layer

- Flutter Desktop ekranları
- Sekme tabanlı üst menü
- Her sekme için kendi sol menüsü
- Alt işlem paneli (açılır)
- Paylaşılan arayüz bileşenleri

Sorumluluklar:

- Kullanıcı etkileşimi
- Portföy, fon, hisse, forex ve AI uzman ekranları
- Sonuç ve kaynak gösterimi
- Yalnızca kullanıcıya uygun sunum katmanı

### 3.2 Application Layer

- Feature controllers / use cases
- Domain services
- Session and auth orchestration
- Sync orchestration
- Expert workflow orchestration
- Learning approval workflow

Sorumluluklar:

- Firestore verisine erişim düzenleme
- ChromaDB ve Ollama çağrılarının koordinasyonu
- Grafik okuma pipeline’ının başlatılması
- Uzman karar akışlarının yönetimi

### 3.3 Data & AI Layer

- Firestore: paylaşılan kullanıcı verisi ve metadata
- Local file storage: öğrenme kaynakları / analiz çıktıları
- ChromaDB: uzman hafızası ve vektör araması
- Ollama: yerel Qwen modeli
- Graph Reader: ekran görüntüsünü standart veri modeline çeviren katman
- Document processing: PDF/TXT/MP4/YouTube kaynak işleme

Bu katmanlar arasında veri akışı aşağıdaki gibi tanımlanır:

```text
Flutter UI
  -> UseCases / Services
    -> Repository / Sync Service
      -> Firestore
      -> Local storage
      -> ChromaDB
      -> Ollama
      -> Graph Reader / Source Analyzer
``` 

### 3.4 Çapraz kesitler

- Authentication / user session
- Sync coordinator
- Audit log / event log
- Error handling / retry
- Permission and approval gates
- Source metadata tracking

---

## 4. Modül mimarisi

TradeDesk modül yapısı işlev bazlı ve uzman bazlı ayrılır.

### 4.1 Ana modüller

- app_shell
  - app_root
  - theme
  - navigation
  - route management
  - shell layout

- portfolio
  - portfolio_dashboard
  - portfolio_distribution
  - performance
  - transaction_history
  - mail_reports

- funds
  - fund_list
  - fund_compare
  - favorites
  - tefas_analysis
  - fund_history

- equities
  - stock_list
  - stock_portfolio
  - dividends
  - stock_analysis
  - favorites

- forex
  - charts
  - pairs
  - demo_trading
  - backtest
  - forex_log

- ai_experts
  - expert_manager
  - expert_profile
  - expert_memory
  - expert_learning_history
  - expert_source_library
  - approval_workflow

- learning_sources
  - youtube_ingestion
  - video_ingestion
  - pdf_ingestion
  - txt_ingestion
  - source_parser
  - rule_extractor

- graph_analysis
  - screenshot_capture
  - graph_reader
  - chart_standardizer
  - chart_feature_model
  - analyst_input_adapter

- ai_runtime
  - ollama_client
  - prompt_builder
  - qwen_adapter
  - response_parser
  - context_loader

- data_sync
  - firestore_sync_manager
  - user_data_sync
  - expert_metadata_sync
  - remote_cache_manager

- persistence
  - local_db
  - file_cache
  - vector_storage
  - config_store

### 4.2 Modül bağımlılık kuralı

- UI modülleri sadece application layer servislerine erişir.
- AI modülleri doğrudan UI ile iletişime girmez.
- Uzman modülleri yalnızca kendi hafızasına erişebilir.
- Uzmanlar arası ortak hafıza kullanılmaz.
- Firestore verisi ana paylaşım katmanı olarak kullanılır.

---

## 5. Flutter klasör yapısı

Aşağıdaki klasör yapısı, Flutter Desktop projesinin teknik organizasyonunu temsil eder.

```text
lib/
  app/
    app_root.dart
    router.dart
    theme.dart

  features/
    portfolio/
      presentation/
      domain/
      data/
    funds/
      presentation/
      domain/
      data/
    equities/
      presentation/
      domain/
      data/
    forex/
      presentation/
      domain/
      data/
    ai_experts/
      presentation/
      domain/
      data/
    learning_sources/
      presentation/
      domain/
      data/
    graph_analysis/
      presentation/
      domain/
      data/

  core/
    auth/
    config/
    constants/
    errors/
    network/
    utils/
    validators/
    logging/

  services/
    firestore/
    sync/
    ollama/
    chroma/
    file_storage/
    source_parsers/

  widgets/
    shell/
    navigation/
    panels/
    cards/
    tables/
    charts/

  models/
    user/
    portfolio/
    fund/
    stock/
    forex/
    expert/
    source/
    chart/
    ai/

  providers/
    app_provider.dart
    sync_provider.dart
    expert_provider.dart
    portfolio_provider.dart

  main.dart

windows/
  runner/
  CMakeLists.txt

assets/
  icons/
  images/
  charts/
  prompts/

scripts/
  sync_seed.dart
  export_expert.dart
  import_expert.dart
```

Notlar:

- `features/*/domain` ve `features/*/data` birimlerinin ayrı tutulması, uzman ve öğrenme modüllerinin izole kalmasını sağlar.
- `services` katmanı dış sistemlere (Firestore, Chroma, Ollama, dosya işleme) erişimi yönetir.
- `models` katmanı ortak veri şemaları barındırır.
- UI ekranları ve iş akışları ayrı olarak düzenlenir.

---

## 6. Firestore veri modeli

Firestore, ortak kullanıcı verisi ve uzman metadata için kullanılacak tek paylaşım katmanıdır.

### 6.1 Paylaşılan veriler (senkronlanacak)

- portföy
- fonlar
- hisseler
- mail tercihleri
- kullanıcı ayarları
- uzman metadata bilgileri

### 6.2 Senkronize edilmeyecek veriler

- MP4 dosyaları
- PDF dosyaları
- ChromaDB verileri
- Uzman eğitim arşivleri

### 6.3 Firestore collection yapısı

```text
users/{userId}/
  profile
  settings
  mailPreferences
  portfolio
  funds
  stocks
  forex
  experts/{expertId}/
    profile
    metadata
    learningHistory
    approvalQueue
    sourceReferences
  syncLog
```

### 6.4 Temel doküman modelleri

#### UserProfile

```json
{
  "userId": "string",
  "displayName": "string",
  "email": "string",
  "accountProvider": "mobile|desktop",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### UserSettings

```json
{
  "themeMode": "light|dark",
  "defaultView": "portfolio|funds|stocks|forex|ai",
  "syncEnabled": true,
  "notificationLevel": "minimal|standard|full",
  "lastSyncAt": "timestamp"
}
```

#### MailPreferences

```json
{
  "email": "string",
  "dailyDigestEnabled": true,
  "alertThreshold": "normal|high|critical",
  "portfolioUpdateChannel": "mail|none",
  "updatedAt": "timestamp"
}
```

#### PortfolioSnapshot

```json
{
  "portfolioId": "string",
  "totalValue": 1250000.0,
  "dailyPnL": 1800.0,
  "totalPnL": 45200.0,
  "assetBreakdown": {
    "funds": 0.45,
    "stocks": 0.4,
    "forex": 0.15
  },
  "updatedAt": "timestamp"
}
```

#### FundAsset

```json
{
  "fundId": "string",
  "name": "string",
  "symbol": "string",
  "allocation": 0.18,
  "currentValue": 230000.0,
  "currency": "TRY",
  "lastUpdatedAt": "timestamp"
}
```

#### StockAsset

```json
{
  "stockId": "string",
  "symbol": "string",
  "companyName": "string",
  "quantity": 300,
  "averageCost": 42.5,
  "marketValue": 15400.0,
  "updatedAt": "timestamp"
}
```

#### ExpertMetadata

```json
{
  "expertId": "string",
  "name": "ICT Uzmanı",
  "category": "market_structure|price_action|fundamental",
  "status": "active|paused|archived",
  "memoryCollection": "expert_ict_memory",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 6.5 Senkronizasyon kuralları

- Yalnızca kullanıcı alanı içindeki paylaşılan veriler Firestore’a yazılır.
- Büyük dosyalar doğrudan Firestore’a gitmez; kaynak dosyaları yerel depoda saklanır.
- Uzman metadata ve kaynak referansları Firestore’da tutulur.
- ChromaDB verileri Firestore tarafında tam kopya değildir; yerel vektör hafızasıdır.
- Firestore senkronizasyonu, kullanıcı hesabına göre filtrelenir.

---

## 7. Uzman veri modeli

Her uzman, kendi bilgilerini kendisiyle ilişkilendirir. Uzmanlar birbirlerinin hafızalarını veya bilgi tabanlarını kullanamaz.

### 7.1 Uzman temel yapısı

```json
{
  "expertId": "ict_expert_01",
  "name": "ICT Uzmanı",
  "role": "market_structure",
  "status": "active",
  "memoryCollection": "expert_ict_memory",
  "sourceLibraryRef": "users/{userId}/experts/ict_expert_01/sourceLibrary",
  "learningHistoryRef": "users/{userId}/experts/ict_expert_01/learningHistory",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 7.2 Uzman hafıza modeli

Her uzman için ayrı ChromaDB koleksiyonu vardır.

Örnek:

- `expert_ict_memory`
- `expert_price_action_memory`
- `expert_fund_memory`

Her hafıza kaydı aşağı gibi tutulur:

```json
{
  "id": "rule_001",
  "expertId": "ict_expert_01",
  "sourceType": "pdf|youtube|mp4|txt",
  "sourceRef": "local://sources/pdf/ict_001.pdf",
  "title": "ICT sweep structure",
  "content": "Sweep sonrası BOS ve FVG açılışına odaklanır.",
  "ruleType": "pattern|concept|strategy",
  "confidence": 0.91,
  "approvedByUser": true,
  "createdAt": "timestamp",
  "embedding": [0.12, -0.44, 0.77]
}
```

### 7.3 Uzman kaynağı ve öğrenme geçmişi

Uzman kaynakları:

- YouTube video referansları
- MP4 dosyaları
- PDF belgeleri
- TXT notları

Öğrenme akışı:

```text
Kaynak
  -> Analiz
  -> Öğrenilen Kurallar
  -> Kullanıcı Onayı
  -> Uzman Hafızası
```

Kural: Uzman kendi kendine öğrenmez. Kullanıcı onayı gereklidir.

### 7.4 Uzmanlar arası izolasyon

- Hafıza paylaşımı yoktur.
- Bilgi tabanı paylaşımı yoktur.
- Bir uzman başka bir uzmanın metadata veya hafıza koleksiyonuna erişemez.
- Aynı grafikte farklı uzmanlar bağımsız görüş sunabilir.

---

## 8. Grafik okuyucu mimarisi

Grafik analizi doğrudan uzman tarafından yapılmaz. Önce ortak Grafik Okuyucu çalışır.

### 8.1 Akış

```text
Screenshot
  -> Grafik Okuyucu
  -> Standart Veri Modeli
  -> Uzman
  -> Analiz
```

### 8.2 Grafik Okuyucu bileşenleri

- Screenshot Capture Service
- Image Preprocessor
- OCR / Object detection / chart detection
- Candlestick/structure detector
- Trend-line extractor
- Volume and liquidity detector
- Timeframe normalization
- Standard Chart Data Model

### 8.3 Standart Veri Modeli

```json
{
  "timeframe": "1H",
  "instrument": "EURUSD",
  "points": [
    { "timestamp": "2026-08-15T09:00:00Z", "open": 1.09, "high": 1.1, "low": 1.08, "close": 1.095 }
  ],
  "structure": {
    "trend": "uptrend",
    "swingHighs": ["..."],
    "swingLows": ["..."],
    "support": 1.085,
    "resistance": 1.112
  },
  "volume": "normalized",
  "annotations": ["sweep", "imbalance", "liquidity grab"]
}
```

### 8.4 Grafik okuma prensibi

- Uzman, ham ekran görüntüsünü yorumlamaz.
- İlk olarak ortak grafik okuma katmanı veriyi normalize eder.
- Uzman bu standart modeli üzerinden analiz yapar.
- Aynı grafik için farklı uzmanlar farklı sonuç üretebilir, ama ortak veri kaynağı aynıdır.

---

## 9. ChromaDB kullanım modeli

ChromaDB, uzman hafızası için kullanılır. Her uzmanın ayrı koleksiyonları vardır.

### 9.1 Amaç

- kaynak metinlerinden öğrenilen kuralların vektör olarak saklanması
- benzer kavramlara hızlı erişim
- uzman tarafından ilgili bağlamın geri getirilmesi

### 9.2 Koleksiyon tasarımı

```text
chroma/
  expert_ict_memory
  expert_price_action_memory
  expert_fund_memory
```

### 9.3 Metaveri

- `expertId`
- `sourceType`
- `sourceRef`
- `ruleType`
- `approvedByUser`
- `createdAt`
- `confidence`
- `language`

### 9.4 Arama davranışı

- Kullanıcıya ait uzman verisi çağrılır.
- Sadece ilgili uzman koleksiyonundaki vektörler aranır.
- Benzer kavramlar tanımlanır, ama uzmanlar yalnızca kendi hafızasına erişir.
- Uzman özelliği: kendi hafızasını kullanır; başkasının hafızasını kullanmaz.

### 9.5 Veri yaşam döngüsü

```text
source file
  -> parser
  -> extracted rules
  -> vector embedding
  -> user approval
  -> ChromaDB insert
```

---

## 10. Ollama entegrasyon modeli

AI katmanı yerel olarak çalışan Ollama üzerinden Qwen modeline bağlanır.

### 10.1 Mimari

```text
TradeDesk App
  -> Ollama Client
    -> local Ollama server
      -> Qwen model
```

### 10.2 Kullanım amaçları

- uzman sorgu üretimi
- kaynak içeriğini anlamlandırma
- öğrenilen kuralları özetleme
- grafik verisi için analiz hazırlığı
- genel analiz sunumları

### 10.3 Prompt tasarımı

Prompt katmanı, uzmanın hafızasını ve grafik verisini bağlar.

Örnek akış:

```text
System:
  Sen bir yatırım uzmanısın.
  Sadece kendi hafızanı kullan.
  Başka uzman hafızasını kullanma.
  Sonuç formatı mutlaka doğru olmalı.

User:
  Gösterilen grafik ve hafıza bağlamı hazır.
  Trend, Yapı, Sinyal, Güven, Sebep, Kaynak çıktısı isteniyor.
```

### 10.4 Yanıt formatı

Her uzman çıktısı şu alanları içerir:

- Trend
- Yapı
- Sinyal
- Güven
- Sebep
- Kaynak

Bu format zorunludur. Her karar açık ve gerekçelidir.

### 10.5 Güvenlik ve izolasyon kuralları

- Uzmanlar yalnızca kendi hafızasını taşıyan contexte erişebilir.
- Cross-expert prompt enjeksiyonu engellenir.
- Model, kullanıcı onayı alınmadan kendi kendine öğrenmez.
- AI çıktısı kaynak referansları ile desteklenir.

---

## 11. Senkronizasyon modeli

Firestore ile paylaşılan veriler senkronize edilir; yerel büyük veri ve vektör hafızaları ise ayrı tutulur.

### 11.1 Senkronize edilen veriler

- Portföy
- Fonlar
- Hisseler
- Mail tercihleri
- Kullanıcı ayarları
- Uzman metadata bilgileri

### 11.2 Senkronize edilmeyen veriler

- MP4 dosyaları
- PDF dosyaları
- ChromaDB verileri
- Uzman eğitim arşivleri

### 11.3 Senkronizasyon akışı

```text
Desktop App
  -> Local repository
  -> Sync orchestrator
  -> Firestore
  -> User-scoped data model
```

### 11.4 Senkronizasyon kuralı

- Firestore, ortak kullanıcı verisi için kullanılır.
- ChromaDB ve eğitim kaynakları yerelde kalır.
- Yalnızca hafıza metadata ve kaynak referansı senkronize edilir.
- Firestore üzerinde kaynak dosyalarının büyük binary verisi tutulmaz.

### 11.5 Senkronizasyon örneği

- Kullanıcı hesabı açılır.
- Portföy, fon ve hisse verileri Firestore üzerinden pull edilir.
- Mail tercihleri ve ayarlar güncellenir.
- Uzman metadata görünür hale gelir.
- Kullanıcı seçilen uzman için kaynak ve hafıza erişimini yönetir.

---

## 12. Mobil uygulama rolü ve sınırları

Mobil uygulama, TradeDesk ile aynı kullanıcı hesabını ve Firestore verisini kullanır; ancak yalnızca görüntüleme ve sonuç okuma işlevi üstlenir.

### 12.1 Mobilde yapılabilecekler

- Sonuç görüntüleme
- Uzman görüşlerini görüntüleme
- Paylaşılan portföy verilerini izleme
- AI sonuçlarını inceleme

### 12.2 Mobilde yapılanlar

- Uzman eğitilemez
- Video analiz edilemez
- Büyük AI iş yükü yapılamaz

### 12.3 Neden?

Mobil taraf, kullanıcıyı hızlı bilgiye ulaştıran hafif bir görüntüleme katmanıdır. Eğitim, görsel işleme ve yerel AI işlemleri masaüstü TradeDesk’e ayrılır.

---

## 13. Arayüz mimarisi

### 13.1 Üst menü

- Portföyüm
- Fonlar
- Hisseler
- Forex
- AI Uzman

### 13.2 Açılış ekranı

Açılış ekranı varsayılan olarak Portföyüm olur.

Gösterilecek alanlar:

- Toplam Portföy Değeri
- Toplam K/Z
- Günlük K/Z
- Fon Dağılımı
- Hisse Dağılımı
- Son İşlemler
- Son Senkronizasyon
- Mail Durumu

### 13.3 Sekme bazlı sol menü yapısı

Portföyüm:

- Dashboard
- Portföy Dağılımı
- Performans
- İşlem Geçmişi
- Mail Raporları

Fonlar:

- Fon Listesi
- Fon Karşılaştırma
- Favoriler
- TEFAS Analizleri
- Fon Geçmişi

Hisseler:

- Hisse Listesi
- Portföy
- Temettüler
- Analizler
- Favoriler

Forex:

- Grafikler
- Pariteler
- Demo İşlemler
- Backtest
- Forex Günlüğü

AI Uzman:

- Uzman Yönetimi
- Kaynak Kütüphanesi
- Öğrenilen Kurallar
- Sohbet Geçmişi
- Video Analizleri

### 13.4 Alt işlem paneli

Alt bölümde açılır işlem paneli bulunur.

- Fonlar: Fon Al, Fon Sat
- Hisseler: Hisse Al, Hisse Sat
- Forex: Long, Short, Demo İşlem

---

## 14. Güvenlik ve veri izolasyonu

- Kullanıcı hesabı tek kaynaktır.
- Uzmanların hafızaları izole kalır.
- Uzmanlar birbirlerinin bilgi tabanlarını değiştiremez.
- Uzmanlar birbirlerinden öğrenemez.
- Kullanıcı onayı olmadan kurallar hafızaya yazılmaz.
- Firestore ve ChromaDB ayrı veri katmanlarıdır.

---

## 15. MVP geliştirme sırası

Aşağıdaki sıralama, mümkün olan en düşük riskli ve en değerli işlevlerden başlar.

### Aşama 1 — Temel shell ve kullanıcı verisi

- Flutter Desktop shell kurulumu
- Üst menü, sol menü ve açılış ekranı
- Portföy ekranı
- Firestore kullanıcı profili ve ayarlar
- Kullanıcı kimliği ve senkronizasyon altyapısı

### Aşama 2 — Portföy ve varlık takibi

- Fon listesi
- Hisse listesi
- Portföy dağılımı
- Temel performans ekranı
- Firestore portföy senkronizasyonu

### Aşama 3 — AI uzman temel yapılandırması

- Uzman profili oluşturma
- Uzman metadata yönetimi
- Uzman listesi
- Kendi hafıza alanı ve ChromaDB koleksiyonu
- Örnek uzmanlar: ICT, Price Action, Fon Uzmanı

### Aşama 4 — Kaynak ve öğrenme iş akışı

- YouTube/MP4/PDF/TXT kaynak yükleme
- Kaynak ayrıştırma
- Öğrenilen kural üretimi
- Kullanıcı onay ekranı
- ChromaDB’e onaylı kural ekleme

### Aşama 5 — Grafik okuyucu ve standart veri modeli

- Görüntü yakalama
- Grafik analizi için common chart model
- Standart veri yapısı
- Uzmanların grafik analizi için aynı giriş modelini kullanması

### Aşama 6 — Uzman analizi ve yanıt formatı

- Ollama + Qwen entegrasyonu
- Prompt builder ve bağlam yükleme
- Sonuç formatı: Trend, Yapı, Sinyal, Güven, Sebep, Kaynak
- Uzman bazlı sonuçlar

### Aşama 7 — Senkronizasyon ve mobil uyumluluk

- Firestore paylaşılan veriler senkronizasyonu
- Mobil uygulama için sonuç görünümleri
- Büyük AI iş yükü ve video analizi için desktop ayrıcalığı

### Aşama 8 — Gelişmiş özellikler

- Demo forex işlemleri
- Backtest
- Uzman karşılaştırma ekranları
- Daha fazla öğrenme kaynağı ve kaynak yönetimi
- Analiz geçmişi ve kullanıcı kaydı

---

## 16. Teknik karar özeti

- Desktop: Flutter Desktop (Windows)
- Shared data: Firestore
- Local AI runtime: Ollama + Qwen
- Expert memory: ChromaDB
- Expert boundary: isolated memory per expert
- Source ingestion: YouTube, MP4, PDF, TXT
- Approval required: yes
- Graph input: screenshot -> graph reader -> standard model -> expert
- Mobile role: view-only
- Design principle: same user account, same data, isolated expert intelligence

Bu mimari, TradeDesk’in “gelişmiş yatırım analizi ve uzman öğrenme” hedefini, mobil görünümden ayrı ve güvenli bir masaüstü çalışma modeliyle destekler.
