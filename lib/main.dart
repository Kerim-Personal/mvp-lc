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
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Uygulama yaşam döngüsünü dinleyip müziği yönetir
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
        AudioService.instance.pauseMusic();
        break;
      case AppLifecycleState.resumed:
        if (AudioService.instance.isMusicEnabled && AudioService.instance.musicVolume > 0) {
          AudioService.instance.resumeMusic();
        }
        break;
      case AppLifecycleState.hidden:
        AudioService.instance.pauseMusic();
        break;
    }
  }
}

// RootScreen'in state'ine erişmek için global bir anahtar
final GlobalKey<RootScreenState> rootScreenKey = GlobalKey<RootScreenState>();

// Tekil yaşam döngüsü gözlemcisi
final _AppLifecycleAudioObserver _lifecycleObserver = _AppLifecycleAudioObserver();

void main() async {
  // WidgetsBinding'i erken başlat ve splash'ı koru
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Yaşam döngüsü gözlemcisini kaydet
  _lifecycleObserver.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM background handler uygulama başlamadan önce atanmalı
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await ThemeService.instance.init();
  runApp(const MyApp());
  // runApp sonrası ağır olmayan init görevlerini başlat
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _SystemUiSynchronizer.update(isDark);
        });

        return MaterialApp(
          title: 'VocaChat',
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
    if (_lastIsDark == isDark) return;
    _lastIsDark = isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: (isDark
          ? ThemeService.instance.darkTheme.scaffoldBackgroundColor
          : ThemeService.instance.lightTheme.scaffoldBackgroundColor)
          .withAlpha(255),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Splash ekranını güvenli bir şekilde kaldırmak için yardımcı bir fonksiyon
  void _removeSplashSafely() {
    // Build işlemi bittikten sonra çalıştırarak `setState` hatasını önle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Başlangıçta ve veri beklenirken splash ekranı görünmeye devam eder.
          // Bu sırada hiçbir şey çizmiyoruz, çünkü native splash zaten ekranda.
          return const SizedBox.shrink();
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final uid = user.uid;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                // Kullanıcı verisi beklenirken de splash görünmeye devam eder.
                return const SizedBox.shrink();
              }

              // Kullanıcı verisi yoksa veya doküman mevcut değilse Login'e yönlendir.
              if (!userSnap.hasData || !userSnap.data!.exists) {
                _removeSplashSafely(); // Splash'ı kaldır ve Login'i göster
                return const LoginScreen();
              }

              final data = userSnap.data!.data();
              Widget screen;

              if (data != null) {
                if ((data['status'] as String?) == 'banned') {
                  screen = const BannedScreen();
                } else if (!user.emailVerified) {
                  screen = VerificationScreen(email: user.email ?? '');
                } else {
                  final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
                  if (isGoogle && data['profileCompleted'] != true) {
                    screen = ProfileCompletionScreen(userData: data);
                  } else {
                    screen = RootScreen(key: rootScreenKey);
                  }
                }
              } else {
                // data null ise (beklenmedik bir durum) yine de Login'e yönlendir.
                screen = const LoginScreen();
              }

              // Gösterilecek ekran belirlendi, şimdi splash'ı kaldırabiliriz.
              _removeSplashSafely();
              return screen;
            },
          );
        }

        // Oturum açmış kullanıcı yoksa Login'e yönlendir.
        _removeSplashSafely();
        return const LoginScreen();
      },
    );
  }
}


// Projenizin derlenmesi için gerekli olan ancak bu dosyada tanımlanmamış
// bazı değişken ve fonksiyonları buraya ekliyorum.
// Kendi projenizdeki tanımlamalarla aynı olmalıdırlar.

final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Bu fonksiyonun içini projenize göre doldurmalısınız.
  debugPrint("Handling a background message: ${message.messageId}");
}

// Color sınıfına 'withAlpha' metodu zaten dahil olduğu için
// 'withValues' extension'ına gerek yoktur.
// Eğer özel bir kullanımınız yoksa kaldırabilirsiniz.
extension ColorValues on Color {
  Color withValues({int? alpha, int? red, int? green, int? blue}) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}