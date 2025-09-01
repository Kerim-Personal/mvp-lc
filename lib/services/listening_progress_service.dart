// lib/services/listening_progress_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ListeningProgressService {
  static final ListeningProgressService instance = ListeningProgressService._();
  ListeningProgressService._();

  static const _key = 'listening_progress_v1';
  Map<String, dynamic> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try { _cache = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
    }
    _loaded = true;
  }

  Future<Map<String, dynamic>> getExercise(String id) async {
    await _ensureLoaded();
    return (_cache[id] as Map<String, dynamic>? ) ?? {};
  }

  Future<void> recordAttempt({required String id, required int score, required int total}) async {
    await _ensureLoaded();
    final data = await getExercise(id);
    final attempts = (data['attempts'] as int? ?? 0) + 1;
    final best = (data['best'] as int? ?? 0);
    final bestScore = score > best ? score : best;
    _cache[id] = {
      'attempts': attempts,
      'best': bestScore,
      'total': total,
      'lastScore': score,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_cache));
  }
}

