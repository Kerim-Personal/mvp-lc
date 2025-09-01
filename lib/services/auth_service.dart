// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login tarafında ek bekleyen credential tutmuyoruz; linking sadece profilden yapılır.

  // DiceBear avatar URL'i oluşturma fonksiyonu
  String _generateAvatarUrl(String seed) {
    return 'https://api.dicebear.com/8.x/micah/svg?seed=$seed';
  }

  /// Kullanıcı adının veritabanında daha önce alınıp alınmadığını kontrol eder.
  /// Artık Callable Cloud Function kullanır; kimlik doğrulaması gerektirmez.
  Future<bool> isUsernameAvailable(String username) async {
    final callable = FirebaseFunctions.instance.httpsCallable('checkUsernameAvailable');
    final res = await callable.call({'username': username});
    final data = res.data;
    if (data is Map && data['available'] is bool) return data['available'] as bool;
    return false;
  }

  /// Yeni kullanıcı kaydı oluşturur ve ek bilgileri Firestore'a kaydeder.
  Future<UserCredential?> signUp(String email, String password,
      String username, DateTime birthDate, String gender, String nativeLanguage) async {
    try {
      // 1. Firebase Authentication ile kullanıcıyı oluştur.
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 1.5: Kullanıcı adı rezervasyonu – yarış koşullarını engelle
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('reserveUsername');
        await callable.call({'username': username});
      } catch (e) {
        // Rezervasyon başarısız: oluşturulan auth kullanıcısını geri al
        try { await userCredential.user?.delete(); } catch (_) {}
        try { await _auth.signOut(); } catch (_) {}
        throw FirebaseAuthException(
          code: 'username-taken',
          message: 'Kullanıcı adı zaten alınmış. Lütfen başka bir ad deneyin.',
        );
      }

      // E-posta doğrulama linki gönder
      await userCredential.user?.sendEmailVerification();

      // Avatar URL'i oluşturuluyor
      final avatarUrl = _generateAvatarUrl(username);

      // 2. Kullanıcının ek bilgilerini Firestore veritabanına kaydet.
      if (userCredential.user != null) {
        final docRef = _firestore.collection('users').doc(userCredential.user!.uid);
        await docRef.set({
          'displayName':
          username,
          'username_lowercase': username.toLowerCase(),
          'birthDate': Timestamp.fromDate(birthDate),
          'gender': gender,
          'email': email,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified':
          false,
          'avatarUrl': avatarUrl,
          'partnerCount': 0,
          'streak': 0,
          'totalPracticeTime': 0,
          'lastActivityDate': FieldValue.serverTimestamp(),
          'isPremium': false,
          'role': 'user',
          'status': 'active',
          'nativeLanguage': nativeLanguage,
          'profileCompleted': false, // rules gereği başlangıçta false
        });
        // Email-password kullanıcıları profil tamamlamayı atlayacak -> hemen true yap
        try { await docRef.update({'profileCompleted': true}); } catch (_) {}
      }
      return userCredential;
    } on FirebaseAuthException catch (_) {
      // Hata yönetimi için hatayı yeniden fırlat
      rethrow;
    }
  }

  /// Mevcut kullanıcının giriş yapmasını sağlar.
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // E-posta doğrulama durumunun güncel olduğundan emin olmak için reload
      await userCredential.user?.reload();
      final user = _auth.currentUser; // reload sonrası güncel referans

      // E-posta doğrulaması kontrolü
      if (user != null && !user.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Lütfen giriş yapmadan önce e-postanızı doğrulayın.',
        );
      }

      // Firestore kullanıcı profili kontrolü
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final snap = await docRef.get();
        if (!snap.exists) {
          // Profil eksik -> otomatik yeniden oluştur (minimum alanlar)
          await docRef.set({
            'displayName': user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı',
            'username_lowercase': (user.displayName ?? user.email ?? '').toLowerCase(),
            'email': user.email,
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'emailVerified': user.emailVerified,
            'avatarUrl': 'https://api.dicebear.com/8.x/micah/svg?seed=${user.uid.substring(0,6)}',
            'partnerCount': 0,
            'streak': 0,
            'totalPracticeTime': 0,
            'lastActivityDate': FieldValue.serverTimestamp(),
            'isPremium': false,
            'role': 'user',
            'status': 'active',
            'nativeLanguage': 'en',
            'profileCompleted': false, // create
          });
          // Email/password (providerId == password) ise hemen tamamlandı kabul et
          final isPasswordProvider = user.providerData.any((p)=>p.providerId=='password');
          if (isPasswordProvider) { try { await docRef.update({'profileCompleted': true}); } catch(_){} }
        } else {
          final data = snap.data() as Map<String, dynamic>;

          // Eski 'blockedUsers' array -> alt koleksiyona migrasyon (best-effort)
          final List<dynamic>? legacyBlocked = data['blockedUsers'] as List<dynamic>?;
          if (legacyBlocked != null && legacyBlocked.isNotEmpty) {
            final batch = _firestore.batch();
            for (final id in legacyBlocked) {
              final uid = id?.toString();
              if (uid == null || uid.isEmpty) continue;
              final ref = docRef.collection('blockedUsers').doc(uid);
              batch.set(ref, {
                'blockedAt': FieldValue.serverTimestamp(),
                'targetUserId': uid,
              }, SetOptions(merge: true));
            }
            try { await batch.commit(); } catch (_) {}
          }

          final status = data['status'] as String?;
          if (status == 'deleted') {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'user-deleted',
              message: 'Bu hesap silinmiş durumda.'
            );
          }
          // Eksik emailVerified alanı güncelle
          if (data['emailVerified'] != true && user.emailVerified) {
            await docRef.update({'emailVerified': true});
          }
        }
      }

      return userCredential;
    } on FirebaseAuthException {
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

  /// Google ile giriş yapmayı sağlar.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      // Hesap seçiciyi zorlamak için önceki oturumu temizle
      try { await googleSignIn.disconnect(); } catch (_) {}
      try { await googleSignIn.signOut(); } catch (_) {}

      final GoogleSignInAccount? gAccount = await googleSignIn.signIn();
      if (gAccount == null) return null; // kullanıcı iptal
      final auth = await gAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      // Basit akış: doğrudan credential ile giriş yap. Çakışmalar UI'da yönlendirilecek.
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final snap = await docRef.get();
        if (!snap.exists) {
          // Firestore security rules isValidNewUser gereksinimlerini sağlamak için zorunlu alanları dolduruyoruz.
          final rawName = (user.displayName ?? user.email?.split('@').first ?? 'User').trim();
          String baseName = rawName;
          if (baseName.length < 3) baseName = (baseName + '___').substring(0, 3); // min 3
          if (baseName.length > 29) baseName = baseName.substring(0,29);

          // Kullanıcı adı rezervasyonu: çakışırsa küçük varyasyonlar dene
          String reservedName = baseName;
          final reserveFn = FirebaseFunctions.instance.httpsCallable('reserveUsername');
          bool reserved = false;
          for (int i = 0; i < 3 && !reserved; i++) {
            final tryName = (i == 0) ? reservedName : '${baseName}_${user.uid.substring(0, 2 + i)}';
            try {
              await reserveFn.call({'username': tryName});
              reservedName = tryName;
              reserved = true;
            } catch (_) {
              // devam et
            }
          }

          final dicebear = 'https://api.dicebear.com/8.x/micah/svg?seed=${user.uid.substring(0,6)}';
          await docRef.set({
            'displayName': reserved ? reservedName : baseName,
            'username_lowercase': (reserved ? reservedName : baseName).toLowerCase(),
            'email': user.email,
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'emailVerified': user.emailVerified, // Google genelde doğrulanmış gelir
            'avatarUrl': dicebear,
            'partnerCount': 0,
            'streak': 0,
            'totalPracticeTime': 0,
            'lastActivityDate': FieldValue.serverTimestamp(),
            'isPremium': false,
            'role': 'user',
            'status': 'active',
            'nativeLanguage': 'en',
            'birthDate': Timestamp.fromDate(DateTime(2000,1,1)),
            'gender': 'Male',
            'profileCompleted': false, // Google kullanıcıları tamamlamaya yönlendirilecek
          });
        } else {
          await docRef.update({
            'lastActivityDate': FieldValue.serverTimestamp(),
            if (user.emailVerified) 'emailVerified': true,
          });
          // Eski 'blockedUsers' array -> alt koleksiyona migrasyon (best-effort)
          final data = snap.data();
          if (data != null) {
            final List<dynamic>? legacyBlocked = data['blockedUsers'] as List<dynamic>?;
            if (legacyBlocked != null && legacyBlocked.isNotEmpty) {
              final batch = _firestore.batch();
              for (final id in legacyBlocked) {
                final uid = id?.toString();
                if (uid == null || uid.isEmpty) continue;
                final ref = docRef.collection('blockedUsers').doc(uid);
                batch.set(ref, {
                  'blockedAt': FieldValue.serverTimestamp(),
                  'targetUserId': uid,
                }, SetOptions(merge: true));
              }
              try { await batch.commit(); } catch (_) {}
            }
          }
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Basit uyarı için çakışma kodunu aynen ilet
      if (e.code == 'account-exists-with-different-credential' || e.code == 'credential-already-in-use') {
        rethrow;
      }
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'google-signin-failed', message: e.toString());
    }
  }

  /// Oturum açıkken mevcut kullanıcıya Google sağlayıcısını bağlar (manuel linking).
  /// true: başarı, false: kullanıcı Google hesabı seçiminde iptal etti.
  Future<bool> linkCurrentUserWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'Oturum bulunamadı.');
    }
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      // Zaten bağlı; hata yerine başarı gibi davranabiliriz
      return true;
    }

    final googleSignIn = GoogleSignIn();
    try { await googleSignIn.disconnect(); } catch (_) {}
    try { await googleSignIn.signOut(); } catch (_) {}

    final GoogleSignInAccount? gAccount = await googleSignIn.signIn();
    if (gAccount == null) {
      return false; // kullanıcı iptal
    }
    final auth = await gAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        return true;
      }
      // Başka bir kullanıcı bu Google kimliğini kullanıyorsa
      if (e.code == 'credential-already-in-use' || e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'Bu Google hesabı başka bir kullanıcıyla ilişkili.',
        );
      }
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Güvenlik için lütfen tekrar giriş yaptıktan sonra bağlamayı deneyin.',
        );
      }
      rethrow;
    }

    // Firestore dokümanını hafifçe güncelle
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActivityDate': FieldValue.serverTimestamp(),
        if (user.emailVerified) 'emailVerified': true,
      });
    } catch (_) {}

    return true;
  }
}