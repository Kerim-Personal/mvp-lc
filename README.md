# lingua_chat

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release

### Android
- Paket adı: `com.codenzi.lingua_chat`
- İmza: `android/keystore.properties` oluşturun (örnek: `android/keystore.properties.example`).
- Sürüm: `pubspec.yaml` içindeki `version: x.y.z+code` değerini güncelleyin.
- Derleme:
  - AAB: `flutter build appbundle --release`
  - APK: `flutter build apk --release`
- Çıktılar:
  - AAB: `build/app/outputs/bundle/release/app-release.aab`
  - APK: `build/app/outputs/flutter-apk/app-release.apk`

Notlar:
- Android 13+ için medya izinleri güncel (READ_MEDIA_IMAGES). Eski `READ_EXTERNAL_STORAGE` yalnızca SDK<=32 için istenir.
- `INTERNET` izni eklidir.
- Keystore yoksa geçici olarak debug imzasına düşer (sadece test amaçlı). Store yayını için mutlaka kendi keystore’unuzu kullanın.

### iOS
- Bundle Id: Xcode > Runner target > Signing & Capabilities altında ayarlayın.
- Firebase: `ios/Runner/GoogleService-Info.plist` dosyasını ekleyin.
- İzin metinleri Info.plist’te tanımlı: Kamera, Fotoğraf, Mikrofon, Konuşma Tanıma.
- Derleme (Xcode): Product > Archive ve ardından Organizer’dan dağıtım.

Notlar:
- iOS’ta kod imzalama (Team, Provisioning Profile) gereklidir.
- Store Connect yüklemesi için App Privacy, Data Safety ve ekran görüntüleri gibi mağaza metadatasını hazırlayın.
