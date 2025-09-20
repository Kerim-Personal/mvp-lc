// lib/repositories/writing_repository.dart
import 'package:vocachat/models/writing_models.dart';

class WritingRepository {
  WritingRepository._();
  static final WritingRepository instance = WritingRepository._();

  final List<WritingPrompt> _prompts = _seed();

  List<WritingPrompt> all() => List.unmodifiable(_prompts);
  WritingPrompt? byId(String id) => _prompts.firstWhere((e) => e.id == id, orElse: () => _prompts.first);

  static List<WritingPrompt> _seed() {
    return [
      const WritingPrompt(
        id: 'w1',
        title: 'Introduce Yourself Email',
        category: 'Introductions',
        level: WritingLevel.beginner,
        type: WritingType.email,
        instructions: 'Write an email (60-120 words) to a new international pen pal. Introduce yourself, where you live, one hobby and a question for them.',
        focusPoints: [
          'Greeting + closing',
          'Age or role (student/job)',
          'One hobby with short detail',
          'One friendly question',
        ],
        targetVocab: ['hobby','enjoy','live','share'],
        sampleOutline: '1) Hi + name. 2) Where you are from. 3) Hobby + detail. 4) Ask a question. 5) Close politely.',
        suggestedMinutes: 12,
      ),
      const WritingPrompt(
        id: 'w2',
        title: 'Weekend Activity Story',
        category: 'Narrative',
        level: WritingLevel.intermediate,
        type: WritingType.story,
        instructions: 'Write a short story (120-200 words) about a surprising thing that happened last weekend. Use past tenses and at least two adjectives.',
        focusPoints: [
          'Clear beginning, middle, end',
          'Past simple & past continuous mix',
          'Emotions / reactions',
        ],
        targetVocab: ['suddenly','realize','exhausted','excited'],
        sampleOutline: '1) Setting. 2) Unexpected event. 3) Reaction/challenge. 4) Resolution & feeling.',
        suggestedMinutes: 20,
      ),
      const WritingPrompt(
        id: 'w3',
        title: 'Social Media & Productivity Opinion',
        category: 'Opinion',
        level: WritingLevel.advanced,
        type: WritingType.opinion,
        instructions: 'Write an opinion paragraph (180-260 words) on whether social media improves or harms personal productivity. Support with at least two arguments & one counterpoint.',
        focusPoints: [
          'Clear position in first 1-2 sentences',
          'Supporting arguments + brief example',
          'Address a counterargument',
          'Concluding sentence with recommendation',
        ],
        targetVocab: ['distraction','focus','habit','evidence','prioritize'],
        sampleOutline: 'Intro stance -> Arg1 (example) -> Arg2 (example) -> Counter + refute -> Conclusion',
        suggestedMinutes: 25,
      ),
    ];
  }
}

