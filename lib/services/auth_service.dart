// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // DiceBear avatar URL'i oluşturma fonksiyonu
  String _generateAvatarUrl(String seed) {
    // Farklı stiller için 'micah', 'bottts', 'jdenticon' gibi isimler deneyebilirsiniz.
    return 'https://api.dicebear.com/8.x/micah/svg?seed=$seed';
  }

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
  Future<UserCredential?> signUp(String email, String password,
      String username, DateTime birthDate, String gender) async {
    try {
      // 1. Firebase Authentication ile kullanıcıyı oluştur.
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // E-posta doğrulama linki gönder
      await userCredential.user?.sendEmailVerification();

      // Avatar URL'i oluşturuluyor
      final avatarUrl = _generateAvatarUrl(username);

      // 2. Kullanıcının ek bilgilerini Firestore veritabanına kaydet.
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'displayName':
          username, // Kullanıcının girdiği orijinal, büyük/küçük harfli ad.
          'username_lowercase': username
              .toLowerCase(), // Sistemin kullanacağı benzersiz, küçük harfli ad.
          'birthDate': Timestamp.fromDate(birthDate),
          'gender': gender,
          'email': email,
          'uid': userCredential.user!.uid,
          'createdAt': Timestamp.now(),
          'emailVerified':
          false, // Başlangıçta e-posta doğrulanmamış olarak ayarlanır.
          'avatarUrl': avatarUrl,
          'partnerCount': 0,
          // İstatistik alanları başlatılıyor
          'streak': 0,
          'totalPracticeTime': 0, // Dakika cinsinden
          'lastActivityDate': Timestamp.now(),
          'isPremium': false, // Varsayılan olarak premium değil
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Hata yönetimi için hatayı yeniden fırlat
      throw e;
    }
  }

  /// Mevcut kullanıcının giriş yapmasını sağlar.
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // E-posta doğrulaması kontrolü
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Kullanıcı var ama e-postası doğrulanmamışsa özel bir hata fırlat
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Lütfen giriş yapmadan önce e-postanızı doğrulayın.',
        );
      }
      // Giriş başarılıysa, Firestore'daki `emailVerified` alanını da güncelleyelim.
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'emailVerified': true});
      }
      return userCredential;
    } on FirebaseAuthException {
      // Hatanın kendisini yeniden fırlatarak UI katmanının yakalamasına izin ver
      rethrow;
    }
  }

  /// Mevcut kullanıcının oturumunu kapatır.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Kullanıcının mevcut şifresini doğruladıktan sonra şifresini günceller.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      // 1. Adım: Kullanıcının kimliğini mevcut şifresiyle yeniden doğrula.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Adım: Kimlik doğrulama başarılıysa, yeni şifreyi ayarla.
      await user.updatePassword(newPassword);
    } on FirebaseAuthException {
      // Hatanın kendisini UI katmanının işlemesi için yeniden fırlat.
      rethrow;
    }
  }

  /// Belirtilen e-posta adresine bir şifre sıfırlama linki gönderir.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Hatanın kendisini UI katmanının işlemesi için yeniden fırlat.
      rethrow;
    }
  }
}