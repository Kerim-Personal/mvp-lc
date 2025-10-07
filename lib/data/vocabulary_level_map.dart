// lib/data/vocabulary_level_map.dart
// Thematic pack -> CEFR level mapping (initial pedagogical approximation)
// Notes: This is a pack-level assignment. Word-level CEFR tagging can refine this later.

const Map<String, String> vocabularyPackLevel = {
  // A1 (6)
  'Daily Life': 'A1',
  'Home & Furniture': 'A1',
  'Family & Relationships': 'A1',
  'Food & Kitchen': 'A1',
  'Sports & Activities': 'A1',
  'Weather & Seasons': 'A1',

  // A2 (6)
  'Travel & Tourism': 'A2',
  'Education & School': 'A2',
  'Emotions & Feelings': 'A2',
  'Music & Instruments': 'A2',
  'Health & Fitness': 'A2',
  'Work & Office': 'A2',

  // B1 (6)
  'Technology & Software': 'B1',
  'Art & Culture': 'B1',
  'Character & Personality': 'B1',
  'Nature & Environment': 'B1',
  'Phrasal Verbs': 'B1',
  'Hobbies & Leisure': 'B1',

  // B2 (6)
  'Business English': 'B2',
  'Finance & Economy': 'B2',
  'Science & Research': 'B2',
  'History & Mythology': 'B2',
  'Transportation & Directions': 'B2',
  'Media & Entertainment': 'B2',

  // C1 (6)
  'Marketing & Advertising': 'C1',
  'Law & Justice': 'C1',
  'Idioms': 'C1',
  'Slang & Colloquialisms': 'C1',
  'Academic Skills': 'C1',
  'Debate & Rhetoric': 'C1',

  // C2 (6)
  'IELTS/TOEFL Prep': 'C2',
  'Research Methods': 'C2',
  'Philosophy & Ethics': 'C2',
  'Literary Devices': 'C2',
  'Policy & Governance': 'C2',
  'Advanced Science': 'C2',
};

const List<String> cefrLevels = ['A1','A2','B1','B2','C1','C2'];

String? previousLevelOf(String level) {
  final i = cefrLevels.indexOf(level);
  if (i <= 0) return null;
  return cefrLevels[i - 1];
}
