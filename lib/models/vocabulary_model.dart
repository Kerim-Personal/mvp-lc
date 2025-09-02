// lib/models/vocabulary_model.dart

class VocabularyWord {
  final String word;
  final String phonetic; // Phonetic spelling
  final String exampleSentence;

  const VocabularyWord({
    required this.word,
    required this.phonetic,
    required this.exampleSentence,
  });
}

// A vocabulary database that can be easily expanded to thousands of words
const List<VocabularyWord> vocabularyList = [
  // Existing Words
  VocabularyWord(
    word: "Serendipity",
    phonetic: "/ˌser.ənˈdɪp.ə.t̬i/",
    exampleSentence: "Finding that old book in the library was a moment of pure serendipity.",
  ),
  VocabularyWord(
    word: "Ephemeral",
    phonetic: "/əˈfem.ər.əl/",
    exampleSentence: "The beauty of the cherry blossoms is ephemeral, lasting only for a week.",
  ),
  VocabularyWord(
    word: "Ubiquitous",
    phonetic: "/juːˈbɪk.wə.t̬əs/",
    exampleSentence: "Smartphones have become ubiquitous in modern society.",
  ),
  VocabularyWord(
    word: "Mellifluous",
    phonetic: "/məˈlɪf.lu.əs/",
    exampleSentence: "Her mellifluous voice calmed the crying child.",
  ),
  VocabularyWord(
    word: "Petrichor",
    phonetic: "/ˈpet.rə.kɔːr/",
    exampleSentence: "I love the smell of petrichor after a summer rain.",
  ),
  VocabularyWord(
    word: "Ineffable",
    phonetic: "/ɪnˈef.ə.bəl/",
    exampleSentence: "The beauty of the sunset over the ocean was ineffable.",
  ),
  VocabularyWord(
    word: "Resilience",
    phonetic: "/rɪˈzɪl.jəns/",
    exampleSentence: "The community showed great resilience after the earthquake.",
  ),
  VocabularyWord(
    word: "Luminous",
    phonetic: "/ˈluː.mə.nəs/",
    exampleSentence: "The full moon was luminous in the clear night sky.",
  ),
  VocabularyWord(
    word: "Cacophony",
    phonetic: "/kəˈkɒf.ə.ni/",
    exampleSentence: "The city street was a cacophony of car horns and sirens.",
  ),
  VocabularyWord(
    word: "Sonder",
    phonetic: "/ˈsɒn.dər/",
    exampleSentence: "As he looked at the crowd, he was struck by a sudden feeling of sonder.",
  ),

  // Newly Added Words
  VocabularyWord(
    word: "Ethereal",
    phonetic: "/ɪˈθɪr.i.əl/",
    exampleSentence: "The singer's ethereal voice captivated the entire audience.",
  ),
  VocabularyWord(
    word: "Eloquent",
    phonetic: "/ˈel.ə.kwənt/",
    exampleSentence: "He delivered an eloquent speech that moved everyone to tears.",
  ),
  VocabularyWord(
    word: "Quintessential",
    phonetic: "/ˌkwɪn.təˈsen.ʃəl/",
    exampleSentence: "A cup of tea is the quintessential British beverage.",
  ),
  VocabularyWord(
    word: "Pernicious",
    phonetic: "/pərˈnɪʃ.əs/",
    exampleSentence: "The pernicious influence of misinformation is a serious threat.",
  ),
  VocabularyWord(
    word: "Nefarious",
    phonetic: "/nəˈfer.i.əs/",
    exampleSentence: "The villain's nefarious plan was to steal the city's power supply.",
  ),
  VocabularyWord(
    word: "Alacrity",
    phonetic: "/əˈlæk.rə.t̬i/",
    exampleSentence: "She accepted the job offer with alacrity and started the next day.",
  ),
  VocabularyWord(
    word: "Prosaic",
    phonetic: "/proʊˈzeɪ.ɪk/",
    exampleSentence: "The prosaic reality of daily life can sometimes be dull.",
  ),
  VocabularyWord(
    word: "Veracity",
    phonetic: "/vəˈræs.ə.t̬i/",
    exampleSentence: "The journalist checked her sources to ensure the veracity of her report.",
  ),
  VocabularyWord(
    word: "Paucity",
    phonetic: "/ˈpɔː.sə.t̬i/",
    exampleSentence: "There was a paucity of volunteers, so the event had to be rescheduled.",
  ),
  VocabularyWord(
    word: "Contrite",
    phonetic: "/kənˈtraɪt/",
    exampleSentence: "The child had a contrite expression after admitting he broke the window.",
  ),
  VocabularyWord(
    word: "Erudite",
    phonetic: "/ˈer.jə.daɪt/",
    exampleSentence: "We listened to an erudite lecture on Renaissance art.",
  ),
  VocabularyWord(
    word: "Anachronism",
    phonetic: "/əˈnæk.rə.nɪ.zəm/",
    exampleSentence: "In today's digital world, sending a handwritten letter feels like an anachronism.",
  ),
  VocabularyWord(
    word: "Laconic",
    phonetic: "/ləˈkɑː.nɪk/",
    exampleSentence: "His laconic reply of 'no' ended the conversation abruptly.",
  ),
  VocabularyWord(
    word: "Ambiguous",
    phonetic: "/æmˈbɪɡ.ju.əs/",
    exampleSentence: "The instructions were ambiguous, leaving us unsure of what to do next.",
  ),
  VocabularyWord(
    word: "Enigma",
    phonetic: "/əˈnɪɡ.mə/",
    exampleSentence: "The reason for his sudden departure remains an enigma to us all.",
  ),
  VocabularyWord(
    word: "Vex",
    phonetic: "/veks/",
    exampleSentence: "The constant delays and cancellations started to vex the travelers.",
  ),
  VocabularyWord(
    word: "Zephyr",
    phonetic: "/ˈzef.ər/",
    exampleSentence: "A gentle zephyr rustled the curtains on the warm summer evening.",
  ),
  VocabularyWord(
    word: "Solitude",
    phonetic: "/ˈsɑː.lə.tuːd/",
    exampleSentence: "He enjoyed the peace and solitude of his cabin in the woods.",
  ),
  VocabularyWord(
    word: "Supine",
    phonetic: "/ˈsuː.paɪn/",
    exampleSentence: "He was lying supine on the yoga mat, focusing on his breathing.",
  ),
  VocabularyWord(
    word: "Idyllic",
    phonetic: "/aɪˈdɪl.ɪk/",
    exampleSentence: "They spent an idyllic week relaxing on the picturesque island.",
  ),

  // ... Thousands more words can be added to this list.
];