// lib/services/writing_progress_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WritingProgressService {
  WritingProgressService._();
  static final WritingProgressService instance = WritingProgressService._();

  static const _key = 'writing_progress_v1';
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

  Future<Map<String, dynamic>> getPrompt(String id) async {
    await _ensureLoaded();
    return (_cache[id] as Map<String, dynamic>? ) ?? {};
  }

  Future<void> saveDraft(String id, String text) async {
    await _ensureLoaded();
    final entry = await getPrompt(id);
    entry['draft'] = text;
    entry['draftTs'] = DateTime.now().millisecondsSinceEpoch;
    _cache[id] = entry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_cache));
  }

  Future<void> recordSubmission({
    required String id,
    required String text,
    required double score,
    required int wordCount,
  }) async {
    await _ensureLoaded();
    final entry = await getPrompt(id);
    final attempts = (entry['attempts'] as int? ?? 0) + 1;
    final best = (entry['bestScore'] as double? ?? 0);
    final newBest = score > best ? score : best;
    entry['attempts'] = attempts;
    entry['bestScore'] = newBest;
    entry['lastScore'] = score;
    entry['lastWordCount'] = wordCount;
    entry['lastSubmission'] = text;
    entry['lastTs'] = DateTime.now().millisecondsSinceEpoch;
    _cache[id] = entry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_cache));
  }
}

