// lib/services/grammar_progress_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/data/lesson_data.dart';

class GrammarProgressService {
  GrammarProgressService._();
  static final GrammarProgressService instance = GrammarProgressService._();

  static const _key = 'grammar_progress_v1';
  Set<String> _completed = {};
  bool _loaded = false; // SharedPreferences + ilk deneme yapıldı mı
  bool _firebaseLevelLoaded = false; // Firebase'den başarılı şekilde bir seviye okundu mu
  String? _loadedUserId; // Hangi kullanıcı için yüklendiğini takip et
  String _highestLevel = 'A1'; // Varsayılan seviye (tamamlanmış ilk seviye yoksa Beginner olarak raporlanacak)
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

      if (_loadedUserId != null && _loadedUserId != user.uid) {
        _firebaseLevelLoaded = false; // Yeni kullanıcı için tekrar dene
      }

      if (_firebaseLevelLoaded) return; // Zaten aldık

      final usersDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? remoteLevel;
      if (usersDoc.exists && usersDoc.data() != null) {
        final data = usersDoc.data()!;
        final raw = data['grammarHighestLevel'];
        if (raw is String && raw.trim().isNotEmpty) {
          remoteLevel = raw.trim();
        }
      }

      if (remoteLevel == null) {
        final publicDoc = await FirebaseFirestore.instance
            .collection('publicUsers')
            .doc(user.uid)
            .get();
        if (publicDoc.exists && publicDoc.data() != null) {
          final data = publicDoc.data()!;
          final raw = data['grammarHighestLevel'];
          if (raw is String && raw.trim().isNotEmpty) {
            remoteLevel = raw.trim();
          }
        }
      }

      const allowed = ['Beginner', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      final localCalculated = _recalculateHighestLevelFromCompleted();

      if (remoteLevel != null && allowed.contains(remoteLevel)) {
        // Index karşılaştırması
        final order = ['Beginner', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
        final remoteIdx = order.indexOf(remoteLevel);
        final localIdx = order.indexOf(localCalculated);

        // UI başlangıçta lokal zinciri gösterir
        var displayLevel = localCalculated == 'Beginner' ? 'A1' : localCalculated;
        if (_highestLevel != displayLevel) {
          _highestLevel = displayLevel;
          highestLevelNotifier.value = _highestLevel;
        }

        if (localIdx > remoteIdx) {
          // Lokal daha yüksek -> remote yükselt
          await _saveHighestLevelToFirebase(localCalculated);
        } else if (remoteIdx > localIdx) {
          // Remote daha yüksek -> tüm alt seviyeleri ve belirtilen seviyeyi tamamla
          if (remoteLevel != 'Beginner') {
            await _completeLevelsUpTo(remoteLevel);
            final recalculated = _recalculateHighestLevelFromCompleted();
            // Beklenen: recalculated remoteLevel ile aynı
            final finalDisplay = recalculated == 'Beginner' ? 'A1' : recalculated;
            if (_highestLevel != finalDisplay) {
              _highestLevel = finalDisplay;
              highestLevelNotifier.value = _highestLevel;
            }
            // Firebase senkron (remote zaten doğruysa yine de yazmak idempotent)
            await _saveHighestLevelToFirebase(remoteLevel);
          }
        }
      } else {
        // Remote yok veya geçersiz -> lokal kullan + remote'a yaz
        final displayLevel = localCalculated == 'Beginner' ? 'A1' : localCalculated;
        if (_highestLevel != displayLevel) {
          _highestLevel = displayLevel;
          highestLevelNotifier.value = _highestLevel;
        }
        await _saveHighestLevelToFirebase(localCalculated);
      }

      _firebaseLevelLoaded = true;
      _loadedUserId = user.uid;
    } catch (e) {
      // Sessiz geç
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_completed.toList()));
  }

  // Yeni: Belirtilen seviyeye kadar (dahil) tüm dersleri tamamlanmış işaretler
  Future<bool> _completeLevelsUpTo(String level) async {
    const order = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final targetIdx = order.indexOf(level);
    if (targetIdx < 0) return false; // Geçersiz seviye
    bool changed = false;
    for (final lesson in grammarLessons) {
      final idx = order.indexOf(lesson.level);
      if (idx >= 0 && idx <= targetIdx) {
        if (_completed.add(lesson.contentPath)) changed = true;
      }
    }
    if (changed) {
      await _persist();
    }
    return changed;
  }

  // --- Yeni yardımcılar: tamamlanan derslerden seviye hesaplama ---
  String _recalculateHighestLevelFromCompleted() {
    const orderedLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    String? lastFull;
    for (final level in orderedLevels) {
      final levelLessons = grammarLessons.where((l) => l.level == level).toList();
      if (levelLessons.isEmpty) continue; // Seviye dersi yoksa atla
      final allDone = levelLessons.every((l) => _completed.contains(l.contentPath));
      if (allDone) {
        lastFull = level;
      } else {
        break; // İlk eksik bulunan seviye zinciri sonlandırır
      }
    }
    return lastFull ?? 'Beginner';
  }

  bool _isLevelFullyCompleted(String level) {
    final levelLessons = grammarLessons.where((l) => l.level == level).toList();
    if (levelLessons.isEmpty) return false;
    return levelLessons.every((l) => _completed.contains(l.contentPath));
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
      // Ders tamamlandıktan sonra seviye yeniden hesaplanır
      final newCalculated = _recalculateHighestLevelFromCompleted();
      // Notifier'da Beginner durumunda A1 başlangıç seviyesi göstermek için mantığı koruyoruz
      final displayLevel = newCalculated == 'Beginner' ? 'A1' : newCalculated;
      if ((_highestLevel != displayLevel) || !_firebaseLevelLoaded) {
        _highestLevel = displayLevel;
        highestLevelNotifier.value = _highestLevel;
      }
      // Firebase senkronizasyonu: Beginner dahil gerçek hesaplanan değer
      await _saveHighestLevelToFirebase(newCalculated);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (!_firebaseLevelLoaded || _loadedUserId != user.uid)) {
      await _maybeLoadHighestLevelFromFirebase();
    }
    highestLevelNotifier.value = _highestLevel; // Her çağrıda senkronize et
    return _highestLevel;
  }

  // Kullanıcının tamamen bitirdiği seviye için güncelleme; bitmemişse yok sayılır
  Future<void> updateHighestLevel(String newLevel) async {
    await _ensureLoaded();
    await _maybeLoadHighestLevelFromFirebase();
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final normalized = newLevel.toUpperCase();
    if (!levels.contains(normalized)) return; // geçersiz
    if (!_isLevelFullyCompleted(normalized)) return; // seviye tam bitmeden yükseltme yok
    final currentIndex = levels.indexOf(_highestLevel);
    final newIndex = levels.indexOf(normalized);
    if (newIndex > currentIndex) {
      _highestLevel = normalized;
      highestLevelNotifier.value = _highestLevel;
      _firebaseLevelLoaded = true;
      await _saveHighestLevelToFirebase(normalized);
    }
  }

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
      // Sessiz geç
    }
  }
}
