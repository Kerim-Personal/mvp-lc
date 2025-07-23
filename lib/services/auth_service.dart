// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcı adının veritabanında daha önce alınıp alınmadığını kontrol eder.
  /// Sorguyu küçük harfe çevirerek büyük/küçük harf duyarsız bir kontrol sağlar.
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username_lowercase', isEqualTo: username.toLowerCase())
        .limit(1) // Performans için sadece 1 doküman getirmesi yeterli
        .get();
    return result.docs.isEmpty; // Eğer doküman yoksa, kullanıcı adı müsaittir (true).
  }

  /// Yeni kullanıcı kaydı oluşturur ve ek bilgileri Firestore'a kaydeder.
  Future<UserCredential?> signUp(String email, String password, String username, DateTime birthDate, String gender) async {
    try {
      // 1. Firebase Authentication ile kullanıcıyı oluştur.
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // 2. Kullanıcının ek bilgilerini Firestore veritabanına kaydet.
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'displayName': username, // Kullanıcının girdiği orijinal, büyük/küçük harfli ad.
          'username_lowercase': username.toLowerCase(), // Sistemin kullanacağı benzersiz, küçük harfli ad.
          'birthDate': Timestamp.fromDate(birthDate),
          'gender': gender,
          'email': email,
          'uid': userCredential.user!.uid,
          'createdAt': Timestamp.now(),
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi
      print('Firebase Auth Hatası: ${e.message}');
      return null;
    } catch (e) {
      print('Beklenmedik bir hata oluştu: ${e.toString()}');
      return null;
    }
  }

  /// Mevcut kullanıcının giriş yapmasını sağlar.
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  /// Mevcut kullanıcının oturumunu kapatır.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}