// lib/services/grammar_progress_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GrammarProgressService {
  GrammarProgressService._();
  static final GrammarProgressService instance = GrammarProgressService._();

  static const _key = 'grammar_progress_v1';
  Set<String> _completed = {};
  bool _loaded = false;
  String _highestLevel = 'A1'; // Varsayılan seviye

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanan dersleri yükle
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        _completed = list.toSet();
      } catch (_) {}
    }

    // En yüksek seviyeyi Firebase'den yükle
    await _loadHighestLevelFromFirebase();

    _loaded = true;
  }

  /// Firebase'den kullanıcının ulaştığı en yüksek grammar seviyesini yükler
  Future<void> _loadHighestLevelFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('grammarHighestLevel')) {
          _highestLevel = data['grammarHighestLevel'] as String;
        }
      }
    } catch (e) {
      // Hata durumunda varsayılan A1 kalır
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

  /// Kullanıcının ulaştığı en yüksek grammar seviyesini döner
  Future<String> getHighestLevel() async {
    await _ensureLoaded();
    return _highestLevel;
  }

  /// Kullanıcının grammar seviyesini günceller ve Firebase'e kaydeder
  /// Seviyeler: A1, A2, B1, B2, C1, C2
  Future<void> updateHighestLevel(String newLevel) async {
    await _ensureLoaded();

    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(_highestLevel);
    final newIndex = levels.indexOf(newLevel);

    // Sadece daha yüksek bir seviyeyse güncelle
    if (newIndex > currentIndex) {
      _highestLevel = newLevel;
      await _saveHighestLevelToFirebase(newLevel);
    }
  }

  /// En yüksek seviyeyi Firebase'e kaydeder
  Future<void> _saveHighestLevelToFirebase(String level) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'grammarHighestLevel': level,
      }, SetOptions(merge: true));
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
}
