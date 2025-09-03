import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VocabularyProgressRepository {
  VocabularyProgressRepository._();
  static final VocabularyProgressRepository instance = VocabularyProgressRepository._();

  // Yerel cache: kategori -> kelime seti
  final Map<String, Set<String>> _local = {};
  // Progress ValueNotifier (UI dinleyecek)
  final ValueNotifier<Map<String, Set<String>>> progressNotifier = ValueNotifier({});

  SharedPreferences? _prefs;
  bool _initDone = false;
  static const _prefsPrefix = 'vocab_prog_';

  Future<void> _ensureInit() async {
    if (_initDone) return;
    _prefs = await SharedPreferences.getInstance();
    for (final key in _prefs!.getKeys()) {
      if (key.startsWith(_prefsPrefix)) {
        final catEnc = key.substring(_prefsPrefix.length);
        final category = Uri.decodeComponent(catEnc);
        final list = _prefs!.getStringList(key) ?? [];
        _local[category] = list.toSet();
      }
    }
    progressNotifier.value = _snapshot();
    _initDone = true;
  }

  Map<String, Set<String>> _snapshot() => Map.fromEntries(_local.entries.map((e) => MapEntry(e.key, {...e.value})));

  Future<Map<String, Set<String>>> fetchAllProgress() async { await _ensureInit(); return _snapshot(); }
  Future<Set<String>> fetchLearnedWords(String category) async { await _ensureInit(); return _local[category] ?? <String>{}; }

  Future<bool> markLearned(String category, String word) async {
    await _ensureInit();
    final set = _local.putIfAbsent(category, () => <String>{});
    final added = set.add(word);
    if (!added) return false;
    await _persist(category, set);
    progressNotifier.value = _snapshot();
    return true;
  }

  Future<bool> unmarkLearned(String category, String word) async {
    await _ensureInit();
    final set = _local[category];
    if (set == null) return false;
    final removed = set.remove(word);
    if (!removed) return false;
    await _persist(category, set);
    progressNotifier.value = _snapshot();
    return true;
  }

  Future<bool> toggleLearned(String category, String word) async {
    await _ensureInit();
    final set = _local.putIfAbsent(category, () => <String>{});
    if (set.contains(word)) {
      set.remove(word);
      await _persist(category, set);
      progressNotifier.value = _snapshot();
      return false; // artık öğrenilmemiş
    } else {
      set.add(word);
      await _persist(category, set);
      progressNotifier.value = _snapshot();
      return true; // şimdi öğrenildi
    }
  }

  Future<void> _persist(String category, Set<String> words) async {
    final key = _prefsPrefix + Uri.encodeComponent(category);
    await _prefs!.setStringList(key, words.toList());
  }

  Stream<Map<String, Set<String>>> streamAllProgress() async* { // Geriye dönük uyumluluk için
    await _ensureInit();
    yield _snapshot();
  }
}
