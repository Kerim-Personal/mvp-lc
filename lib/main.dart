import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure ile oluşturulan dosya
import 'package:lingua_chat/screens/login_screen.dart'; // Dosya yolunu kendine göre düzelt

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase başlatmadan önce gerekli
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // otomatik yapılandırma
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaChat',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
