# VocaChat

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


