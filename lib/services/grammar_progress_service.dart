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

  // Eskiden tek bir global anahtar vardı: 'grammar_progress_v1'. Bu tüm hesaplar arasında sızıntıya sebep oluyordu.
  // Yeni yaklaşım: kullanıcıya özgü anahtar üretimi. İlk girişte eski global anahtar varsa migrasyon yapılır.
  static const _legacyGlobalKey = 'grammar_progress_v1';
  String _storageKeyFor(String uid) => 'grammar_progress_v1_$uid';

  Set<String> _completed = {};
  bool _loaded = false; // Mevcut kullanıcı için SharedPreferences yüklemesi yapıldı mı
  bool _firebaseLevelLoaded = false; // Firebase'den başarılı şekilde bir seviye okundu mu
  String? _loadedUserId; // Hangi kullanıcı için yüklendiğini takip et
  String _highestLevel = 'A1'; // Varsayılan (Beginner görüntüsü için A1)
  final ValueNotifier<String> highestLevelNotifier = ValueNotifier<String>('A1');
  bool _authListenerAttached = false;

  // Kullanıcı yokken gelen yazma taleplerini kaçırmamak için bekleyen seviye
  String? _pendingLevelToSave;

  Future<void> _ensureLoaded() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Kullanıcı değişmişse veya hiç yüklenmemişse yeniden yükle
    if (!_loaded || (currentUser != null && currentUser.uid != _loadedUserId)) {
      await _loadFromPrefsForCurrentUser();
    } else if (currentUser == null && !_loaded) {
      // Oturum yok; temiz başlangıç
      _completed = {};
      _highestLevel = 'A1';
      highestLevelNotifier.value = _highestLevel;
      _loaded = true; // Boş durum olarak işaretle
    }
    // Firebase seviyesi ilk defa veya kullanıcı değişiminde çekilecek
    await _maybeLoadHighestLevelFromFirebase();
    _attachAuthListenerOnce();
  }

  Future<void> _loadFromPrefsForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Oturum kapalıysa her şeyi sıfırla
      _completed = {};
      _highestLevel = 'A1';
      highestLevelNotifier.value = _highestLevel;
      _loadedUserId = null;
      _loaded = true;
      _firebaseLevelLoaded = false;
      return;
    }

    final key = _storageKeyFor(user.uid);
    String? raw = prefs.getString(key);

    // Legacy: Eski global anahtar varsa sadece temizle (veriyi taşımıyoruz)
    final legacyRaw = prefs.getString(_legacyGlobalKey);
    if (legacyRaw != null) {
      await prefs.remove(_legacyGlobalKey);
    }

    Set<String> loadedCompleted = {};
    if (raw != null) {
      try {
        loadedCompleted = (jsonDecode(raw) as List).cast<String>().toSet();
      } catch (_) {
        loadedCompleted = {};
      }
    }

    _completed = loadedCompleted;
    _loadedUserId = user.uid;
    _loaded = true;
    _firebaseLevelLoaded = false; // yeni kullanıcı için firebase seviyesi tekrar çekilecek

    // Local hesaplamaya göre başlangıç gösterimi
    final localCalculated = _recalculateHighestLevelFromCompleted();
    final displayLevel = localCalculated == 'Beginner' ? 'A1' : localCalculated;
    _highestLevel = displayLevel;
    highestLevelNotifier.value = _highestLevel;
  }

  void _attachAuthListenerOnce() {
    if (_authListenerAttached) return;
    _authListenerAttached = true;
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // Sign-out -> local ilerlemeyi temizle (bir sonraki hesapta sızıntı olmasın)
        _completed = {};
        _highestLevel = 'A1';
        highestLevelNotifier.value = _highestLevel;
        _loadedUserId = null;
        _firebaseLevelLoaded = false;
        _loaded = false; // Yeni kullanıcı geldiğinde yeniden yükleyeceğiz
        return;
      }
      // Yeni giriş -> yeniden yükleme ve firebase seviyesi denemesi
      _loaded = false; // _ensureLoaded çağrısında yeniden okunacak
      await _ensureLoaded();
      // Bekleyen yazma varsa şimdi yap
      if (_pendingLevelToSave != null) {
        final pending = _pendingLevelToSave!;
        _pendingLevelToSave = null;
        await _saveHighestLevelToFirebase(pending);
      }
    });
  }

  /// Kullanıcı değiştiyse veya henüz firebase seviyesi alınmadıysa yüklemeyi dener
  Future<void> _maybeLoadHighestLevelFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Auth yok

      if (_loadedUserId != null && _loadedUserId != user.uid) {
        _firebaseLevelLoaded = false; // güvenlik; zaten _loadFromPrefsForCurrentUser tetikler ama ekstra
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
        final order = ['Beginner', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
        final remoteIdx = order.indexOf(remoteLevel);
        final localIdx = order.indexOf(localCalculated);

        var displayLevel = localCalculated == 'Beginner' ? 'A1' : localCalculated;
        if (_highestLevel != displayLevel) {
          _highestLevel = displayLevel;
          highestLevelNotifier.value = _highestLevel;
        }

        if (localIdx > remoteIdx) {
          // Lokal (bu kullanıcıya ait) daha yüksek -> remote yükselt
          await _saveHighestLevelToFirebase(localCalculated);
        } else if (remoteIdx > localIdx) {
          // Remote daha yüksek -> tüm alt seviyeleri ve belirtilen seviyeyi tamamla
          if (remoteLevel != 'Beginner') {
            await _completeLevelsUpTo(remoteLevel);
            final recalculated = _recalculateHighestLevelFromCompleted();
            final finalDisplay = recalculated == 'Beginner' ? 'A1' : recalculated;
            if (_highestLevel != finalDisplay) {
              _highestLevel = finalDisplay;
              highestLevelNotifier.value = _highestLevel;
            }
            await _saveHighestLevelToFirebase(remoteLevel); // idempotent
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Oturum yoksa kaydetme
    await prefs.setString(_storageKeyFor(user.uid), jsonEncode(_completed.toList()));
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
      final newCalculated = _recalculateHighestLevelFromCompleted();
      final displayLevel = newCalculated == 'Beginner' ? 'A1' : newCalculated;
      if ((_highestLevel != displayLevel) || !_firebaseLevelLoaded) {
        _highestLevel = displayLevel;
        highestLevelNotifier.value = _highestLevel;
      }
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
      if (user == null) {
        if (kDebugMode) {
          debugPrint('[GrammarProgress] queue save level="$level" (no user)');
        }
        _pendingLevelToSave = level;
        return;
      }
      if (kDebugMode) {
        debugPrint('[GrammarProgress] save level="$level" for uid=${user.uid}');
      }
      final data = {
        'grammarHighestLevel': level,
      };
      final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await usersRef.set(data, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[GrammarProgress] saved level="$level" to users');
      }
      // publicUsers dokümanı Cloud Function tarafından senkronize edilir
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GrammarProgress] failed to save level to users: $e');
      }
    }
  }
}
