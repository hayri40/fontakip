# FontTakip Mail Worker MVP

Bu servis, Cloud Run uzerinde calisan minimum gunluk portfoy ozet worker'idir.

## MVP kapsamı

- Firestore'dan kullanici tercihlerini ve snapshot verisini okur
- 09:30 fon ozeti ve 18:30 hisse ozeti icin ayri endpoint sunar
- Gmail API ile `FontTakip Bildirimleri <noreply@fonttakip.com>` adina mail gonderir
- Basarili gonderimde `lastFundSentAt` veya `lastStockSentAt` alanini gunceller
- Worker calismadan once Turk piyasasi takvimini kontrol eder; hafta sonu veya resmi tatilde `reason=holiday_skip` ile atlar

Bu ilk surumde yok:

- retry
- delivery_logs
- email-status endpointi
- mobil uygulama ile otomatik backend senkronu

## Minimum Firestore koleksiyonlari

### `users/{userId}`

```json
{
  "googleSubjectId": "1234567890",
  "googleEmail": "kullanici@gmail.com",
  "displayName": "Kullanici",
  "isGoogleLinked": true,
  "updatedAt": "2026-08-13T21:00:00.000Z"
}
```

### `email_preferences/{userId}`

```json
{
  "recipientEmail": "kullanici@gmail.com",
  "fundSummaryEnabled": true,
  "fundSummaryTime": "09:30",
  "stockSummaryEnabled": true,
  "stockSummaryTime": "18:30",
  "lastFundSentAt": null,
  "lastStockSentAt": null,
  "updatedAt": "2026-08-13T21:00:00.000Z"
}
```

### `portfolio_snapshots/{userId}`

```json
{
  "fundSnapshot": {
    "generatedAt": "2026-08-13T09:15:00.000Z",
    "totalProfitLoss": 4520.0,
    "totalPortfolioValue": 150000.0,
    "items": [
      {
        "code": "ABC",
        "name": "ABC Fon",
        "dailyChangePercent": 1.25
      }
    ]
  },
  "stockSnapshot": {
    "generatedAt": "2026-08-13T18:15:00.000Z",
    "totalProfitLoss": 12350.0,
    "totalPortfolioValue": 286000.0,
    "items": [
      {
        "symbol": "THYAO",
        "dailyChangePercent": 2.14
      }
    ]
  },
  "updatedAt": "2026-08-13T21:00:00.000Z"
}
```

## Gerekli environment variable'lar

- `GMAIL_CLIENT_ID`
- `GMAIL_CLIENT_SECRET`
- `GMAIL_REFRESH_TOKEN`
- `GMAIL_SENDER_EMAIL`
- `GMAIL_SENDER_NAME` (opsiyonel, varsayilan: `FontTakip Bildirimleri`)
- `FIRESTORE_USERS_COLLECTION` (opsiyonel, varsayilan: `users`)
- `FIRESTORE_PREFERENCES_COLLECTION` (opsiyonel, varsayilan: `email_preferences`)
- `FIRESTORE_SNAPSHOTS_COLLECTION` (opsiyonel, varsayilan: `portfolio_snapshots`)

## Gmail API hazirligi

1. Google Cloud project icinde **Gmail API**'yi etkinlestir.
2. `noreply@fonttakip.com` icin Gmail veya Google Workspace mailbox hazirla.
3. OAuth consent screen hazirla.
4. OAuth Client olustur.
5. `https://www.googleapis.com/auth/gmail.send` izni ile `noreply@fonttakip.com` hesabina authorize ol.
6. `refresh_token` degerini al.
7. Secret Manager'a su secret'lari koy:
   - `fontakip-gmail-client-id`
   - `fontakip-gmail-client-secret`
   - `fontakip-gmail-refresh-token`
   - `fontakip-gmail-sender-email`

## Gerekli Google Cloud servisleri

```bash
gcloud services enable run.googleapis.com \
  cloudscheduler.googleapis.com \
  secretmanager.googleapis.com \
  firestore.googleapis.com \
  gmail.googleapis.com
```

## Firestore veritabani olusturma

```bash
gcloud firestore databases create --location=eur3 --type=firestore-native
```

## Service account olusturma

### Worker runtime service account

```bash
gcloud iam service-accounts create fontakip-mail-worker \
  --display-name "FontTakip Mail Worker"
```

### Scheduler service account

```bash
gcloud iam service-accounts create fontakip-scheduler \
  --display-name "FontTakip Scheduler"
```

## Secret Manager secret'larini olusturma

```bash
printf "%s" "YOUR_GMAIL_CLIENT_ID" | gcloud secrets create fontakip-gmail-client-id --data-file=-
printf "%s" "YOUR_GMAIL_CLIENT_SECRET" | gcloud secrets create fontakip-gmail-client-secret --data-file=-
printf "%s" "YOUR_GMAIL_REFRESH_TOKEN" | gcloud secrets create fontakip-gmail-refresh-token --data-file=-
printf "%s" "noreply@fonttakip.com" | gcloud secrets create fontakip-gmail-sender-email --data-file=-
```

## Cloud Run deploy

`PROJECT_ID` ve `REGION` degiskenlerini kendi projenize gore uyarlayin.

```bash
gcloud run deploy fontakip-mail-worker \
  --source cloud/mail-worker \
  --region europe-west1 \
  --service-account fontakip-mail-worker@PROJECT_ID.iam.gserviceaccount.com \
  --no-allow-unauthenticated \
  --set-secrets GMAIL_CLIENT_ID=fontakip-gmail-client-id:latest \
  --set-secrets GMAIL_CLIENT_SECRET=fontakip-gmail-client-secret:latest \
  --set-secrets GMAIL_REFRESH_TOKEN=fontakip-gmail-refresh-token:latest \
  --set-secrets GMAIL_SENDER_EMAIL=fontakip-gmail-sender-email:latest \
  --set-env-vars GMAIL_SENDER_NAME="FontTakip Bildirimleri"
```

## IAM

Worker runtime service account'a su rolleri ver:

- `roles/datastore.user`
- `roles/secretmanager.secretAccessor`
- `roles/logging.logWriter`

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member serviceAccount:fontakip-mail-worker@PROJECT_ID.iam.gserviceaccount.com \
  --role roles/datastore.user

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member serviceAccount:fontakip-mail-worker@PROJECT_ID.iam.gserviceaccount.com \
  --role roles/secretmanager.secretAccessor

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member serviceAccount:fontakip-mail-worker@PROJECT_ID.iam.gserviceaccount.com \
  --role roles/logging.logWriter
```

Cloud Run invoke yetkisi ver:

```bash
gcloud run services add-iam-policy-binding fontakip-mail-worker \
  --region europe-west1 \
  --member serviceAccount:fontakip-scheduler@PROJECT_ID.iam.gserviceaccount.com \
  --role roles/run.invoker
```

## Cloud Scheduler job komutlari

### 09:30 fon ozeti

```bash
gcloud scheduler jobs create http fontakip-fund-summary \
  --location europe-west1 \
  --schedule "30 9 * * *" \
  --time-zone "Europe/Istanbul" \
  --uri "https://fontakip-mail-worker-<hash>-ew.a.run.app/jobs/fund-summary" \
  --http-method POST \
  --oidc-service-account-email fontakip-scheduler@PROJECT_ID.iam.gserviceaccount.com
```

### 18:30 hisse ozeti

```bash
gcloud scheduler jobs create http fontakip-stock-summary \
  --location europe-west1 \
  --schedule "30 18 * * *" \
  --time-zone "Europe/Istanbul" \
  --uri "https://fontakip-mail-worker-<hash>-ew.a.run.app/jobs/stock-summary" \
  --http-method POST \
  --oidc-service-account-email fontakip-scheduler@PROJECT_ID.iam.gserviceaccount.com
```

## Ilk canliya alma adimlari

1. Gmail API ve Firestore'u etkinlestir.
2. `noreply@fonttakip.com` icin OAuth refresh token al.
3. Secret Manager secret'larini ekle.
4. Cloud Run service account olustur ve IAM rollerini ver.
5. Worker'i deploy et.
6. Firestore'a ilk kullanici belgelerini ekle.
7. Scheduler service account olustur.
8. Iki scheduler job'unu kur.
9. Test icin job'u manuel calistir:

```bash
gcloud scheduler jobs run fontakip-fund-summary --location europe-west1
gcloud scheduler jobs run fontakip-stock-summary --location europe-west1
```

## Not

Bu MVP, Firestore'da veri oldugu varsayimi ile calisir. Mobil uygulamanin bu belgelere otomatik senkron yazmasi bir sonraki adimdir.

### Firestore'a ilk kullanici belgelerini ekleme

En hizli yol Firestore Console uzerinden uc belge olusturmaktir:

1. `users/{userId}`
2. `email_preferences/{userId}`
3. `portfolio_snapshots/{userId}`

`{userId}` tum koleksiyonlarda ayni olmalidir.
