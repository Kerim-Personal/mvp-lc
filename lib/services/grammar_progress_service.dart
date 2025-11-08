// lib/services/grammar_progress_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GrammarProgressService {
  GrammarProgressService._();
  static final GrammarProgressService instance = GrammarProgressService._();

  static const _key = 'grammar_progress_v1';
  Set<String> _completed = {};
  bool _loaded = false; // SharedPreferences + ilk deneme yapıldı mı
  bool _firebaseLevelLoaded = false; // Firebase'den başarılı şekilde bir seviye okundu mu
  String? _loadedUserId; // Hangi kullanıcı için yüklendiğini takip et
  String _highestLevel = 'A1'; // Varsayılan seviye
  final ValueNotifier<String> highestLevelNotifier = ValueNotifier<String>('A1');
  bool _authListenerAttached = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return; // İlk yükleme yapıldıysa direkt çık
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanan dersleri yükle
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        _completed = list.toSet();
      } catch (_) {}
    }

    // Firebase'den en yüksek seviyeyi dene (auth hazır olmayabilir)
    await _maybeLoadHighestLevelFromFirebase();
    _attachAuthListenerOnce();
    _loaded = true; // SharedPreferences ve ilk deneme tamam
  }

  void _attachAuthListenerOnce() {
    if (_authListenerAttached) return;
    _authListenerAttached = true;
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return; // sign-out durumunda müdahale yok; uygulama yeniden yükleyecek
      // Yeni kullanıcı veya yeniden giriş: firebase seviyesi tekrar çekilsin
      _firebaseLevelLoaded = false;
      _loadedUserId = null;
      await _maybeLoadHighestLevelFromFirebase();
    });
  }

  /// Kullanıcı değiştiyse veya henüz firebase seviyesi alınmadıysa yüklemeyi dener
  Future<void> _maybeLoadHighestLevelFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Auth henüz hazır değil, sonra yeniden denenecek

      // Kullanıcı değiştiyse yeniden sıfırla
      if (_loadedUserId != null && _loadedUserId != user.uid) {
        _firebaseLevelLoaded = false; // Yeni kullanıcı için tekrar dene
      }

      if (_firebaseLevelLoaded) return; // Zaten aldık

      // Önce users koleksiyonu
      final usersDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? level;
      if (usersDoc.exists && usersDoc.data() != null) {
        final data = usersDoc.data()!;
        final raw = data['grammarHighestLevel'];
        if (raw is String && raw.trim().isNotEmpty) {
          level = raw.trim();
        }
      }

      // Fallback: publicUsers koleksiyonu (profil burada okuyor)
      if (level == null) {
        final publicDoc = await FirebaseFirestore.instance
            .collection('publicUsers')
            .doc(user.uid)
            .get();
        if (publicDoc.exists && publicDoc.data() != null) {
          final data = publicDoc.data()!;
          final raw = data['grammarHighestLevel'];
          if (raw is String && raw.trim().isNotEmpty) {
            level = raw.trim();
          }
        }
      }

      // Seviye doğrulaması
      const allowed = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      if (level != null && allowed.contains(level)) {
        if (_highestLevel != level) {
          _highestLevel = level;
          highestLevelNotifier.value = _highestLevel; // UI haberdar et
        }
      }

      _firebaseLevelLoaded = true; // Bir kez denendi (başarılı ya da değil)
      _loadedUserId = user.uid;
    } catch (e) {
      // Sessiz geç
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_completed.toList()));
  }

  Future<Set<String>> getCompleted() async {
    await _ensureLoaded();
    return _completed.toSet();
  }

  Future<bool> isCompleted(String id) async {
    await _ensureLoaded();
    return _completed.contains(id);
  }

  Future<void> markCompleted(String id) async {
    await _ensureLoaded();
    if (_completed.add(id)) {
      await _persist();
    }
  }

  Future<void> unmarkCompleted(String id) async {
    await _ensureLoaded();
    if (_completed.remove(id)) {
      await _persist();
    }
  }

  Future<double> levelProgress(String level, Iterable<String> levelContentIds) async {
    await _ensureLoaded();
    int total = levelContentIds.length;
    if (total == 0) return 0;
    int done = levelContentIds.where(_completed.contains).length;
    return done / total;
  }

  /// Kullanıcının ulaştığı en yüksek grammar seviyesini döner (gerekirse yeniden Firebase'den çeker)
  Future<String> getHighestLevel() async {
    await _ensureLoaded();
    // Auth hazır olduysa ama firebase seviyesi hiç okunmamışsa veya kullanıcı değiştiyse tekrar dene
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (!_firebaseLevelLoaded || _loadedUserId != user.uid)) {
      await _maybeLoadHighestLevelFromFirebase();
    }
    highestLevelNotifier.value = _highestLevel; // Her çağrıda senkronize et
    return _highestLevel;
  }

  /// Kullanıcının grammar seviyesini günceller ve Firebase'e kaydeder
  /// Seviyeler: A1, A2, B1, B2, C1, C2
  Future<void> updateHighestLevel(String newLevel) async {
    await _ensureLoaded();
    // Kullanıcı henüz yüklenmemişse tekrar dene
    await _maybeLoadHighestLevelFromFirebase();

    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(_highestLevel);
    final newIndex = levels.indexOf(newLevel);

    // Geçersiz giriş kontrolü
    if (newIndex == -1) return;

    // Sadece daha yüksek bir seviyeyse güncelle
    if (newIndex > currentIndex) {
      _highestLevel = newLevel;
      highestLevelNotifier.value = _highestLevel; // UI'ya bildir
      _firebaseLevelLoaded = true; // Artık biliyoruz
      await _saveHighestLevelToFirebase(newLevel);
    }
  }

  /// En yüksek seviyeyi Firebase'e kaydeder (hem users hem publicUsers)
  Future<void> _saveHighestLevelToFirebase(String level) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = {
        'grammarHighestLevel': level,
      };

      final batch = FirebaseFirestore.instance.batch();
      final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final publicRef = FirebaseFirestore.instance.collection('publicUsers').doc(user.uid);
      batch.set(usersRef, data, SetOptions(merge: true));
      batch.set(publicRef, data, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
}
