// lib/models/word_model.dart

class Word {
  final String word;
  final String definition; // 'translation' alanı 'definition' olarak değiştirildi.
  final String example;

  Word({
    required this.word,
    required this.definition, // Yapıcı (constructor) güncellendi.
    required this.example,
  });
}
