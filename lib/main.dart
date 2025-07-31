// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lingua_chat/screens/root_screen.dart';
import 'firebase_options.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/audio_service.dart'; // Müzik servisini import ediyoruz

void main() async {
  // Flutter binding'lerinin hazır olduğundan emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatıyoruz
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Gerekliyse varsayılan sohbet odalarını oluşturuyoruz
  await _createDefaultChatRooms();

  // Müzik servisini başlatıyoruz ve kayıtlı ayarları yüklüyoruz
  await AudioService.instance.init();

  // Sistem UI stilini ayarlıyoruz
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Tarih formatlama için yerelleştirmeyi başlatıyoruz
  await initializeDateFormatting('tr_TR', null);

  // Uygulamayı çalıştırıyoruz
  runApp(const MyApp());
}

// Varsayılan sohbet odalarını oluşturan fonksiyon
Future<void> _createDefaultChatRooms() async {
  final chatRoomsCollection = FirebaseFirestore.instance.collection('group_chats');
  final snapshot = await chatRoomsCollection.limit(1).get();

  // Eğer koleksiyonda hiç oda yoksa, varsayılanları oluştur
  if (snapshot.docs.isEmpty) {
    final batch = FirebaseFirestore.instance.batch();
    final defaultRooms = [
      {
        "name": "Müzik Kutusu",
        "description": "Farklı türlerden müzikler keşfedin ve favori sanatçılarınızı paylaşın.",
        "iconName": "music_note_outlined",
        "color1": "0xFFF06292", // Colors.pink.shade300
        "color2": "0xFFE57373", // Colors.red.shade400
        "isFeatured": true
      },
      {
        "name": "Film & Dizi Kulübü",
        "description": "Haftanın popüler yapımlarını ve kült klasiklerini tartışın.",
        "iconName": "movie_filter_outlined",
        "color1": "0xFF9575CD", // Colors.purple.shade400
        "color2": "0xFF5C6BC0", // Colors.indigo.shade500
        "isFeatured": false
      },
      {
        "name": "Gezginler Durağı",
        "description": "Seyahat anılarınızı ve bir sonraki macera için ipuçlarınızı paylaşın.",
        "iconName": "airplanemode_active_outlined",
        "color1": "0xFFFFB74D", // Colors.orange.shade400
        "color2": "0xFFFF7043", // Colors.deepOrange.shade500
        "isFeatured": false
      },
      {
        "name": "Teknoloji Tayfası",
        "description": "En yeni gadget'ları, yazılımları ve gelecek teknolojilerini konuşun.",
        "iconName": "computer_outlined",
        "color1": "0xFF42A5F5", // Colors.blue.shade500
        "color2": "0xFF26C6DA", // Colors.cyan.shade600
        "isFeatured": false
      },
      {
        "name": "Kitap Kurtları",
        "description": "Okuduğunuz kitaplar hakkında derinlemesine sohbet edin.",
        "iconName": "menu_book_outlined",
        "color1": "0xFF8D6E63", // Colors.brown.shade400
        "color2": "0xFF795548", // Colors.brown.shade600
        "isFeatured": false
      },
    ];

    for (var roomData in defaultRooms) {
      final docRef = chatRoomsCollection.doc(); // Firestore'dan yeni bir ID al
      batch.set(docRef, roomData);
    }

    await batch.commit();
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
      home: const AuthWrapper(),
    );
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          return const RootScreen();
        }
        return const LoginScreen();
      },
    );
  }
}