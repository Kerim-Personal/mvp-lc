// lib/models/vocabulary_model.dart

class VocabularyWord {
  final String word;
  final String phonetic; // Fonetik okunuş
  final String meaning; // Türkçe anlamı
  final String exampleSentence;

  const VocabularyWord({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.exampleSentence,
  });
}

// Binlerce kelimeye kolayca genişletilebilecek kelime veritabanı
const List<VocabularyWord> vocabularyList = [
  VocabularyWord(
    word: "Serendipity",
    phonetic: "/ˌser.ənˈdɪp.ə.t̬i/",
    meaning: "Şans eseri, beklenmedik ve değerli bir şey bulma durumu.",
    exampleSentence: "Finding that old book in the library was a moment of pure serendipity.",
  ),
  VocabularyWord(
    word: "Ephemeral",
    phonetic: "/əˈfem.ər.əl/",
    meaning: "Çok kısa bir süre var olan, geçici.",
    exampleSentence: "The beauty of the cherry blossoms is ephemeral, lasting only for a week.",
  ),
  VocabularyWord(
    word: "Ubiquitous",
    phonetic: "/juːˈbɪk.wə.t̬əs/",
    meaning: "Her yerde aynı anda mevcut olan, yaygın.",
    exampleSentence: "Smartphones have become ubiquitous in modern society.",
  ),
  VocabularyWord(
    word: "Mellifluous",
    phonetic: "/məˈlɪf.lu.əs/",
    meaning: "Tatlı ve akıcı bir sese sahip olan (genellikle ses veya müzik için).",
    exampleSentence: "Her mellifluous voice calmed the crying child.",
  ),
  VocabularyWord(
    word: "Petrichor",
    phonetic: "/ˈpet.rə.kɔːr/",
    meaning: "Uzun bir kuraklıktan sonra yağan yağmurun topraktan yaydığı o hoş koku.",
    exampleSentence: "I love the smell of petrichor after a summer rain.",
  ),
  VocabularyWord(
    word: "Ineffable",
    phonetic: "/ɪnˈef.ə.bəl/",
    meaning: "Kelimelerle ifade edilemeyecek kadar büyük veya aşırı.",
    exampleSentence: "The beauty of the sunset over the ocean was ineffable.",
  ),
  VocabularyWord(
    word: "Resilience",
    phonetic: "/rɪˈzɪl.jəns/",
    meaning: "Zorluklardan veya başarısızlıklardan sonra çabucak toparlanma yeteneği.",
    exampleSentence: "The community showed great resilience after the earthquake.",
  ),
  VocabularyWord(
    word: "Luminous",
    phonetic: "/ˈluː.mə.nəs/",
    meaning: "Işık yayan, parlayan; aydınlık ve parlak.",
    exampleSentence: "The full moon was luminous in the clear night sky.",
  ),
  VocabularyWord(
    word: "Cacophony",
    phonetic: "/kəˈkɒf.ə.ni/",
    meaning: "Sert ve uyumsuz seslerin karışımı, ses kargaşası.",
    exampleSentence: "The city street was a cacophony of car horns and sirens.",
  ),
  VocabularyWord(
    word: "Sonder",
    phonetic: "/ˈsɒn.dər/",
    meaning: "Her bir yabancının sizinki kadar canlı ve karmaşık bir hayat sürdüğünün farkına varma anı.",
    exampleSentence: "As he looked at the crowd, he was struck by a sudden feeling of sonder.",
  ),
  // ... Bu listeye binlerce kelime eklenebilir.
];