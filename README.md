# LinguaChat

A Flutter project for mobile app development.

## Getting Started

This project is a starting point for a Flutter application.

Helpful resources:
- [Flutter Codelab](https://docs.flutter.dev/get-started/codelab) – Write your first app.
- [Flutter Cookbook](https://docs.flutter.dev/cookbook) – Useful samples.
- [Flutter Documentation](https://docs.flutter.dev/) – Tutorials, guidance, full API reference.

## Release

### Android
- Package name: `com.codenzi.vocachat`
- Keystore: Create `android/keystore.properties` (see example: `android/keystore.properties.example`)
- Version: Update `version: x.y.z+code` in `pubspec.yaml`
- Build:
  - App Bundle (AAB): `flutter build appbundle --release`
  - APK: `flutter build apk --release`
- Output paths:
  - AAB: `build/app/outputs/bundle/release/app-release.aab`
  - APK: `build/app/outputs/flutter-apk/app-release.apk`

Notes:
- Android 13+ uses `READ_MEDIA_IMAGES` instead of `READ_EXTERNAL_STORAGE` (SDK <=32).
- `INTERNET` permission is included.
- Without a keystore, debug signature is used temporarily (test only).

### iOS
- Bundle ID: Set in Xcode > Runner target > Signing & Capabilities
- Firebase: Add `ios/Runner/GoogleService-Info.plist`
- Permissions in Info.plist: Camera, Photos, Microphone, Speech Recognition
- Build (Xcode): Product > Archive, then distribute via Organizer

Notes:
- Code signing (Team, Provisioning Profile) required.
- Prepare App Store metadata: App Privacy, Data Safety, screenshots, etc.

## Webhook (RevenueCat)

Sunucu tarafı abonelik güncellemeleri için Firebase Cloud Functions içine bir RevenueCat webhook endpoint’i eklendi.

- Endpoint adı: `revenuecatWebhook`
- Bölge: `us-central1`
- URL biçimi: `https://us-central1-<FIREBASE_PROJE_ID>.cloudfunctions.net/revenuecatWebhook`

Kimlik Doğrulama
- Önerilen: gizli anahtar. Aşağıdaki mekanizmalardan biri kabul edilir:
  - `Authorization: Bearer <SECRET>`
  - `X-Webhook-Secret: <SECRET>`
  - Sorgu parametresi: `?secret=<SECRET>` veya `?token=<SECRET>`
- Gizli anahtar kaynakları:
  - Firebase Functions config: `revenuecat.webhook_secret`
  - Ortam değişkeni: `RC_WEBHOOK_SECRET`

RevenueCat Panel Ayarı
- RevenueCat Dashboard > Webhooks bölümünden endpoint URL’sini ve gizli anahtarı girin.
- Olaylar geldiğinde kullanıcı belgesi `users/{app_user_id}` altında şu alanlar güncellenir:
  - `isPremium`
  - `premiumEntitlementId`
  - `premiumWillRenew`
  - `premiumStore`
  - `premiumPeriodType`
  - `premiumOriginalPurchaseDateIso`
  - `premiumLatestPurchaseDateIso`
  - `premiumExpirationDateIso`
  - `premiumProductIdentifier`
  - `premiumUpdatedAt` (serverTimestamp)

Notlar
- `app_user_id` eksik gönderilirse yazım atlanır ve 200 yanıt döner (RevenueCat yeniden denemesini engellememek için).
- Süre/expiration bilgisi yoksa, event tipinden (INITIAL_PURCHASE, RENEWAL, EXPIRATION vb.) premium durumu çıkarılır.
- İstemci premium alanını yazmaz; premium güncellemeleri sadece webhook ile yapılır. Eski `setPremiumStatus` callable’ı devre dışıdır.

Lokal Doğrulama
- `functions/test_local_webhook.js` dosyası basit bir doğrulama betiğidir. Gerçek Firestore’a yazmadan, bellek içi diziye yazım yapar.
- Üç senaryo içerir: yetkisiz istek (401), hatalı payload (400), başarılı yazma (200) ve yapılan yazımların dökümü.

Dağıtım
- Cloud Functions dağıtımından sonra URL aktif olur. Gizli anahtar config’i ayarlamayı ve RevenueCat’te aynı değeri kullanmayı unutmayın.
