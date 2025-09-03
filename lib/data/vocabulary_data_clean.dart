// Otomatik tekrar temizlenmiş sözlük verisi.
// Orijinal büyük veri dosyasına dokunmadan güvenli şekilde filtreler.
// Kurallar:
// 1) Her kategori kendi içinde aynı kelime (case-insensitive) tekrarını tutmaz.
// 2) Aynı kelime farklı kategorilerde kalabilir (kullanım bağlamı farklı olabilir).
// İstenirse GLOBAL tekilleştirme için belowGlobalDedupe = true yapılabilir.

import 'vocabulary_data.dart';
import '../models/word_model.dart';

// Ayar: true yapılırsa tüm kategoriler arası da ilk görülen korunur.
const bool belowGlobalDedupe = true;

// Temizlik sonrası erişilebilen yardımcı rapor yapıları
// Kategori içi atılan (tekrar olduğu için eklenmeyen) kelimeler (normalize edilmiş -> orijinal formlar listesi)
final Map<String, List<String>> removedLocalDuplicatesByCategory = {};
// Global tekilleştirme açıksa (belowGlobalDedupe = true) atlanan kelimeler (kelime -> kategoriler)
final Map<String, List<String>> removedGlobalDuplicates = {};
// Kategoriler arası (orijinal veri setinde) birden fazla kategoride geçen kelimeler (kelime -> kategoriler)
late final Map<String, List<String>> crossCategoryDuplicateIndex;

final Map<String, List<Word>> vocabularyDataClean = _buildClean();

Map<String, List<Word>> _buildClean() {
  final Map<String, List<Word>> cleaned = {};
  final globalSeen = <String>{};
  // Kategoriler arası indeks hazırlığı için geçici harita (kelime -> kategori seti)
  final Map<String, Set<String>> crossTmp = {};

  vocabularyData.forEach((key, list) {
    final seenLocal = <String>{};
    final localRemoved = <String>[]; // normalize edilmiş kelimeler (orijinal display için ilk hali saklanacak)
    final filtered = <Word>[];
    for (final w in list) {
      final norm = _normalize(w.word);
      // cross-category index populate
      crossTmp.putIfAbsent(norm, () => <String>{}).add(key);

      if (seenLocal.contains(norm)) {
        localRemoved.add(w.word);
        continue; // kategori içi tekrar
      }
      if (belowGlobalDedupe && globalSeen.contains(norm)) {
        removedGlobalDuplicates.putIfAbsent(norm, () => <String>[]).add(key);
        continue; // global tekrar (opsiyonel)
      }
      seenLocal.add(norm);
      globalSeen.add(norm);
      filtered.add(w);
    }
    if (localRemoved.isNotEmpty) {
      removedLocalDuplicatesByCategory[key] = localRemoved;
    }
    cleaned[key] = filtered;
  });

  // Kategoriler arası duplike indeks: yalnızca birden fazla kategoride geçenler
  crossCategoryDuplicateIndex = {
    for (final e in crossTmp.entries.where((e) => e.value.length > 1)) e.key: e.value.toList()..sort()
  };
  return cleaned;
}

// Normalize etme stratejisi: harf dışı (a-z0-9) blokları tek boşluğa indir, trim & lower
String _normalize(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9]+"), " ")
    .replaceAll(RegExp(r"\s+"), " ")
    .trim();

/// Özet rapor (debug / geliştirme amaçlı). Release yapısında çağırılmazsa hiçbir yan etkisi yok.
String buildDuplicateSummary({int maxExamplesPerCategory = 5}) {
  final buf = StringBuffer();
  buf.writeln('=== Sözlük Tekrar Raporu ===');
  buf.writeln('Global tekilleştirme: ${belowGlobalDedupe ? 'AÇIK' : 'KAPALI'}');
  // Kategori içi tekrarlar
  buf.writeln('\n-- Kategori içi atılan tekrarlar --');
  if (removedLocalDuplicatesByCategory.isEmpty) {
    buf.writeln('YOK');
  } else {
    removedLocalDuplicatesByCategory.forEach((cat, words) {
      final sample = words.take(maxExamplesPerCategory).join(', ');
      buf.writeln('- $cat: ${words.length} tekrar (ör: $sample${words.length > maxExamplesPerCategory ? '...' : ''})');
    });
  }
  // Global tekilleştirme bilgisi
  if (belowGlobalDedupe) {
    buf.writeln('\n-- Global (kategori dışı) atlanan tekrarlar --');
    if (removedGlobalDuplicates.isEmpty) {
      buf.writeln('YOK');
    } else {
      removedGlobalDuplicates.forEach((word, cats) {
        buf.writeln('- $word -> ${cats.join(', ')}');
      });
    }
  }
  // Kategoriler arası tekrar indeksi (orijinal veride)
  buf.writeln('\n-- Kategoriler arası (orijinal veri) tekrarlar --');
  if (crossCategoryDuplicateIndex.isEmpty) {
    buf.writeln('YOK');
  } else {
    final sorted = crossCategoryDuplicateIndex.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    for (final e in sorted.take(50)) { // ilk 50 satır sınırı
      buf.writeln('- ${e.key} (${e.value.length} kategori): ${e.value.join(' | ')}');
    }
    if (sorted.length > 50) {
      buf.writeln('... toplam ${sorted.length} kelime birden fazla kategoride.');
    }
  }
  return buf.toString();
}
