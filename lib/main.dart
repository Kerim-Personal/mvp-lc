// lib/main.dart
// Rabbi yessir velâ tuassir Rabbi temmim bi'l-hayr.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vocachat/screens/root_screen.dart';
import 'firebase_options.dart';
import 'package:vocachat/screens/login_screen.dart';
import 'package:vocachat/services/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/screens/banned_screen.dart';
import 'package:vocachat/screens/help_and_support_screen.dart';
import 'package:vocachat/screens/support_request_screen.dart';
import 'package:vocachat/screens/profile_completion_screen.dart';
import 'dart:async';
import 'package:vocachat/screens/verification_screen.dart';
import 'package:vocachat/services/theme_service.dart';
import 'package:vocachat/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vocachat/screens/store_screen.dart';
import 'package:vocachat/screens/practice_listening_screen.dart';
import 'package:vocachat/screens/practice_reading_screen.dart';
import 'package:vocachat/screens/practice_speaking_screen.dart';
import 'package:vocachat/screens/practice_writing_screen.dart';
import 'package:vocachat/screens/profile_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:vocachat/utils/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocachat/screens/onboarding_screen.dart';
import 'package:vocachat/services/revenuecat_service.dart';

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

  // AppCheck *Firestore isteklerinden önce* aktive edilir
  await _initAppCheckSafely();

  // FCM background handler uygulama başlamadan önce atanmalı
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await ThemeService.instance.init();
  runApp(RestartWidget(child: const MyApp()));
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
      _configureFirestoreSafely()
          .timeout(const Duration(seconds: 3), onTimeout: () => null),
    ]);
    // PremiumService'i kullanıcı oturumu açtığında başlatacağız
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
          home: const StartupGate(),
        );
      },
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool? _showOnboarding; // null=loading

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen_v1') ?? false;
    setState(() => _showOnboarding = !seen);
    // Onboarding göstereceksek splash'ı hemen kaldıralım
    if (!mounted) return;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen_v1', true);
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    // Yüklenirken native splash ekranda kalmaya devam eder
    if (_showOnboarding == null) return const SizedBox.shrink();

    if (_showOnboarding == true) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }

    // Normal akışa geç
    return const AuthWrapper();
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

// === DEĞİŞİKLİK BAŞLANGICI ===
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Flag to track if initial navigation decision has been made for the current user session
  bool _initialNavigationComplete = false;
  String? _lastProcessedUserId; // Track the user ID we made the decision for

  // Splash screen removal helper
  void _removeSplashSafely(String reason) {
    // Debug print to see when splash is removed
    // print("Removing splash: $reason");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure the first frame is rendered before removing splash
      // This might help prevent flicker on some devices.
      Future.delayed(const Duration(milliseconds: 50), () {
        FlutterNativeSplash.remove();
      });
    });
  }

  // Premium service initialization helper
  void _initPremiumService(String uid) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await RevenueCatService.instance.init();
        await RevenueCatService.instance.onLogin(uid);
      } catch (e) {
        print('RevenueCat init error in AuthWrapper: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        // --- 1. Handle Auth State Loading ---
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          // Keep splash screen visible while checking auth state
          return const SizedBox.shrink();
        }

        // --- 2. Handle No Logged-In User ---
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          // Reset navigation flag if user logs out
          _initialNavigationComplete = false;
          _lastProcessedUserId = null;
          _removeSplashSafely("User logged out");
          // Optionally stop premium service listeners here if needed
          // RevenueCatService.instance.onLogout(); // Example if you have it
          return const LoginScreen();
        }

        // --- 3. Handle Logged-In User ---
        final user = authSnapshot.data!;
        final uid = user.uid;

        // If this is a new user session (different user ID or first time after login)
        // reset the navigation flag.
        if (_lastProcessedUserId != uid) {
          _initialNavigationComplete = false;
          _lastProcessedUserId = uid;
          // Initialize premium service for the new user session
          _initPremiumService(uid);
        }

        // --- 4. Listen to Firestore User Document ---
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {

            // --- Determine Screen Logic (moved outside of removeSplash call) ---
            Widget determinedScreen;
            bool shouldRemoveSplash = false; // Flag to control splash removal

            // --- 5. Handle Firestore Loading / Initial State ---
            if (userSnap.connectionState == ConnectionState.waiting && !_initialNavigationComplete) {
              // Still waiting for the *first* Firestore data, keep splash
              determinedScreen = const SizedBox.shrink();
            } else if (userSnap.hasError && !_initialNavigationComplete) {
              print("Firestore error before initial nav: ${userSnap.error}");
              determinedScreen = const LoginScreen(); // Fallback to login
              shouldRemoveSplash = true; // Remove splash even on error to show login
            } else if (!userSnap.hasData && !_initialNavigationComplete) {
              // Stream active, but no data yet (could happen if doc doesn't exist yet)
              print("Firestore stream active, but no data/doc found yet for UID: $uid. Waiting...");
              determinedScreen = const SizedBox.shrink(); // Keep splash
            }
            // --- 6. Make Navigation Decision (only affects screen determination) ---
            else {
              // Data is available or we have already navigated once

              // Check document existence ONLY if we have data
              if (userSnap.hasData && !userSnap.data!.exists) {
                print("User document does not exist for UID: $uid");
                // Doküman henüz oluşmamış olabilir; splash'ı açık tutup bekleyelim.
                determinedScreen = const SizedBox.shrink();
                // Splash kaldırılmamalı, ilk karar verilmedi olarak kalsın
                shouldRemoveSplash = false;
              } else if (userSnap.hasData) {
                // Document exists, proceed with logic
                final data = userSnap.data!.data();
                if (data != null) {
                  if ((data['status'] as String?) == 'banned') {
                    determinedScreen = const BannedScreen();
                  } else if (!user.emailVerified) {
                    determinedScreen = VerificationScreen(email: user.email ?? '');
                  } else {
                    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
                    if (data['profileCompleted'] == true) {
                      determinedScreen = RootScreen(key: rootScreenKey); // Go to main app
                    } else {
                      // Profile not completed - always show completion screen if needed
                      determinedScreen = ProfileCompletionScreen(userData: data);
                    }
                  }
                } else {
                  // Data is null, unexpected state
                  print("User document data is null for UID: $uid");
                  determinedScreen = const LoginScreen(); // Fallback
                }
              }
              // Handle Firestore stream error AFTER initial load
              else if (userSnap.hasError) {
                print("Firestore stream error after initial load: ${userSnap.error}");
                determinedScreen = const LoginScreen(); // Safer fallback
              }
              // Fallback for unexpected states (like waiting after initial nav)
              else {
                print("Unexpected state in Firestore StreamBuilder.");
                determinedScreen = const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Mark that we should remove the splash on the *first* valid screen determination
              if (!_initialNavigationComplete) {
                shouldRemoveSplash = true;
              }
            }

            // --- 7. Perform Splash Removal and Update Navigation State ---
            // Only remove splash once, when we first determine a valid screen
            if (shouldRemoveSplash && !_initialNavigationComplete) {
              _initialNavigationComplete = true; // Mark that we've made the first decision
              _removeSplashSafely("Initial screen determined: ${determinedScreen.runtimeType}");
            }

            // If we are still in the initial loading phase (splash not removed yet),
            // keep returning SizedBox.shrink() to allow the native splash to persist.
            if (!_initialNavigationComplete) {
              return const SizedBox.shrink();
            }

            // Return the determined screen
            return determinedScreen;
          },
        );
      },
    );
  }
}
// === DEĞİŞİKLİK BİTİŞİ ===


// Projenizin derlenmesi için gerekli olan ancak bu dosyada tanımlanmamış
// bazı değişken ve fonksiyonları buraya ekliyorum.
// Kendi projenizdeki tanımlamalarla aynı olmalıdırlar.

final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Bu fonksiyonun içini projenize göre doldurmalısınız.
  // Önemli: Bu fonksiyonun içinde UI ile ilgili işlem yapmayın.
  await Firebase.initializeApp( // Background handler için tekrar initialize gerekebilir
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
  // Burada gelen mesaja göre bildirim gösterme veya veri işleme yapabilirsiniz.
}

// Color sınıfına 'withAlpha' metodu zaten dahil olduğu için
// 'withValues' extension'ına gerek yoktur.
// Eğer özel bir kullanımınız yoksa kaldırabilirsiniz.
// extension ColorValues on Color {
//   Color withValues({int? alpha, int? red, int? green, int? blue}) {
//     return Color.fromARGB(
//       alpha ?? this.alpha,
//       red ?? this.red,
//       green ?? this.green,
//       blue ?? this.blue,
//     );
//   }
// }

// BannedScreen tanımı (Eğer dosyanızda yoksa ekleyin)
class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Banned")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Your account has been banned.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Please contact support for more information.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  // Support'a yönlendirme veya çıkış yapma
                  await FirebaseAuth.instance.signOut();
                  // RestartWidget.restartApp(context); // Gerekirse uygulamayı yeniden başlat
                },
                child: const Text("Sign Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

