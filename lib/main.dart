// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lingua_chat/screens/root_screen.dart';
import 'firebase_options.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/audio_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lingua_chat/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/screens/banned_screen.dart';
import 'package:lingua_chat/screens/help_and_support_screen.dart';
import 'package:lingua_chat/screens/support_request_screen.dart';
import 'package:lingua_chat/screens/profile_completion_screen.dart';
import 'dart:async';

// YENİ: RootScreen'in state'ine erişmek için global bir anahtar oluşturuldu.
final GlobalKey<RootScreenState> rootScreenKey = GlobalKey<RootScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Firestore offline cache aç
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const MyApp());
  // runApp sonrası ağır olmayan init görevlerini asenkron başlat
  _postAppInit();
}

Future<void> _postAppInit() async {
  try {
    // 5 sn timeout ile toplu init
    await Future.wait([
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
      initializeDateFormatting('tr_TR', null)
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
      AudioService.instance.init()
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('tr', ''),
      ],
      routes: {
        '/help': (_) => HelpAndSupportScreen(),
        '/support': (_) => const SupportRequestScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}

Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDocWithTimeout(String uid) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 6));
    return snap;
  } catch (_) {
    return null; // timeout veya diğer hata durumunda null dön
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final uid = user.uid;
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _getUserDocWithTimeout(uid),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final data = userSnap.data?.data();
              if (data != null) {
                if ((data['status'] as String?) == 'banned') {
                  return const BannedScreen();
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
