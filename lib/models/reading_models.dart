/// Okuma seviyeleri
enum ReadingLevel { beginner, intermediate, advanced }

extension ReadingLevelX on ReadingLevel {
  String get label => switch (this) {
        ReadingLevel.beginner => 'Beginner',
        ReadingLevel.intermediate => 'Intermediate',
        ReadingLevel.advanced => 'Advanced',
      };
}

/// Bir okuma hikayesi / pasajı
class ReadingStory {
  final String id;
  final String title;
  final String category;
  final ReadingLevel level;
  final String content; // Tüm metin (paragraflar \n ile ayrılabilir)
  final String? description;

  const ReadingStory({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.content,
    this.description,
  });

  /// Paragraflar (çift / tek satır boşluklarına göre ayır)
  List<String> get paragraphs => content
      .split(RegExp(r'\n{2,}'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  /// Cümlelere böl (nokta / soru / ünlem + boşluk)
  List<String> get sentences {
    final text = content.replaceAll('\n', ' ');
    final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }
}
