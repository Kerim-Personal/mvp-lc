// lib/main.dart
// Rabbi yessir velâ tuassir Rabbi temmim bi'l-hayr.


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lingua_chat/screens/root_screen.dart';
import 'firebase_options.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/screens/banned_screen.dart';
import 'package:lingua_chat/screens/help_and_support_screen.dart';
import 'package:lingua_chat/screens/support_request_screen.dart';
import 'package:lingua_chat/screens/profile_completion_screen.dart';
import 'dart:async';
import 'package:lingua_chat/screens/verification_screen.dart';
import 'package:lingua_chat/services/theme_service.dart';
import 'package:lingua_chat/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lingua_chat/screens/store_screen.dart';
import 'package:lingua_chat/screens/practice_listening_screen.dart';
import 'package:lingua_chat/screens/practice_reading_screen.dart';
import 'package:lingua_chat/screens/practice_speaking_screen.dart';
import 'package:lingua_chat/screens/practice_writing_screen.dart';
import 'package:lingua_chat/screens/profile_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

// YENİ: Uygulama yaşam döngüsünü dinleyip müziği yönetir
class _AppLifecycleAudioObserver with WidgetsBindingObserver {
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Arka plana/inaktif duruma geçince müziği duraklat
        AudioService.instance.pauseMusic();
        break;
      case AppLifecycleState.resumed:
        // Öne gelince kullanıcı tercihi açıksa ve ses > 0 ise kaldığı yerden devam et
        if (AudioService.instance.isMusicEnabled && AudioService.instance.musicVolume > 0) {
          AudioService.instance.resumeMusic();
        }
        break;
      case AppLifecycleState.hidden: // Web için
        AudioService.instance.pauseMusic();
        break;
    }
  }
}

// YENİ: RootScreen'in state'ine erişmek için global bir anahtar oluşturuldu.
final GlobalKey<RootScreenState> rootScreenKey = GlobalKey<RootScreenState>();

// YENİ: Tekil yaşam döngüsü gözlemcisi
final _AppLifecycleAudioObserver _lifecycleObserver = _AppLifecycleAudioObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Yaşam döngüsü gözlemcisini erkenden kaydet
  _lifecycleObserver.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ÖNEMLİ: FCM background handler uygulama başlamadan önce atanmalı
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await ThemeService.instance.init(); // Tema tercihlerini yükle
  runApp(const MyApp());
  // runApp sonrası ağır olmayan init görevlerini asenkron başlat
  _postAppInit();
}

Future<void> _postAppInit() async {
  try {
    await Future.wait([
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
      initializeDateFormatting('en_US', null)
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
      AudioService.instance.init()
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
      NotificationService.instance.init()
          .timeout(const Duration(seconds: 8), onTimeout: () => null),
      _initAppCheckSafely()
          .timeout(const Duration(seconds: 8), onTimeout: () => null),
      _configureFirestoreSafely()
          .timeout(const Duration(seconds: 3), onTimeout: () => null),
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  } catch (e) {
    // Sessiz log; splash kilidi artık olmayacağı için kritik değil
    debugPrint('Post init hata: $e');
  }
}

Future<void> _initAppCheckSafely() async {
  try {
    if (kIsWeb) {
      const siteKey = String.fromEnvironment('APP_CHECK_RECAPTCHA_V3_SITE_KEY', defaultValue: '');
      if (siteKey.isNotEmpty) {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(siteKey),
        );
      }
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
      );
    }
  } catch (e) {
    // Bazı cihazlarda Google Play Services eksik olduğunda App Check GMS çağrıları uyarı verebilir
    debugPrint('AppCheck init atlandı/başarısız: $e');
  }
}

Future<void> _configureFirestoreSafely() async {
  try {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  } catch (e) {
    debugPrint('Firestore settings uygulanamadı: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final mode = ThemeService.instance.themeMode;
        final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final brightness = switch (mode) {
          ThemeMode.dark => Brightness.dark,
          ThemeMode.light => Brightness.light,
          ThemeMode.system => platformBrightness,
        };
        final isDark = brightness == Brightness.dark;
        // Parlaklık değişmediği sürece system UI güncellemeyelim
        // static değişken ile önceki durum cache'lenir
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // system ui sync yalnızca değişimde _SystemUiSynchronizer tarafından yapılır
        });
        _SystemUiSynchronizer.update(isDark);
        return MaterialApp(
          title: 'LinguaChat',
          debugShowCheckedModeBanner: false,
          navigatorKey: notificationNavigatorKey,
          theme: ThemeService.instance.lightTheme,
          darkTheme: ThemeService.instance.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          routes: {
            '/help': (_) => HelpAndSupportScreen(),
            '/support': (_) => const SupportRequestScreen(),
            '/store': (_) => const StoreScreen(),
            '/practice-listening': (_) => const PracticeListeningScreen(),
            '/practice-reading': (_) => const PracticeReadingScreen(),
            '/practice-speaking': (_) => const PracticeSpeakingScreen(),
            '/practice-writing': (_) => const PracticeWritingScreen(),
            '/profile': (_) {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return const LoginScreen();
              return ProfileScreen(userId: uid);
            },
          },
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class _SystemUiSynchronizer {
  static bool? _lastIsDark;
  static void update(bool isDark) {
    if (_lastIsDark == isDark) return; // sadece değişince uygula
    _lastIsDark = isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: (isDark
              ? ThemeService.instance.darkTheme.scaffoldBackgroundColor
              : ThemeService.instance.lightTheme.scaffoldBackgroundColor)
          .withValues(alpha: 1),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?> (
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Önceden spinner vardı: artık nötr boş şeffaf placeholder.
          return const Scaffold(body: SizedBox());
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final uid = user.uid;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>> (
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: SizedBox());
              }
              if (!userSnap.hasData || !userSnap.data!.exists) {
                return const Scaffold(body: SizedBox());
              }
              final data = userSnap.data!.data();
              if (data != null) {
                if ((data['status'] as String?) == 'banned') {
                  return const BannedScreen();
                }
                if (!(user.emailVerified)) {
                  return VerificationScreen(email: user.email ?? '');
                }
                final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
                if (isGoogle && data['profileCompleted'] != true) {
                  return ProfileCompletionScreen(userData: data);
                }
              }
              return RootScreen(key: rootScreenKey);
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
