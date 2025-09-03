// lib/services/grammar_progress_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GrammarProgressService {
  GrammarProgressService._();
  static final GrammarProgressService instance = GrammarProgressService._();

  static const _key = 'grammar_progress_v1';
  Set<String> _completed = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        _completed = list.toSet();
      } catch (_) {}
    }
    _loaded = true;
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
}
