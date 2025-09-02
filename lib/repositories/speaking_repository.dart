// lib/repositories/speaking_repository.dart
import 'package:lingua_chat/models/speaking_models.dart';

class SpeakingRepository {
  SpeakingRepository._();
  static final SpeakingRepository instance = SpeakingRepository._();

  final List<SpeakingPrompt> _prompts = _seed();

  List<SpeakingPrompt> all() => List.unmodifiable(_prompts);
  SpeakingPrompt? byId(String id) => _prompts.firstWhere((e) => e.id == id, orElse: () => _prompts.first);

  static List<SpeakingPrompt> _seed() {
    return const [
      SpeakingPrompt(
        id: 's1',
        title: 'Ordering Coffee',
        mode: SpeakingMode.roleplay,
        context: 'You are in a cafe. You are ordering a coffee from the barista.',
        partnerLine: 'Hi there! What can I get you today?',
        targets: [
          "Hi! I'd like a medium latte, please.",
          "Can you make it with oat milk?",
          "That's all, thank you." ,
        ],
        tips: [
          'Start with a polite greeting (e.g., "Hi" or "Hello").',
          'State your request: quantity + type (e.g., "a medium latte").',
          'Add any extras or preferences (e.g., "with oat milk").',
          'Finish with a thank you.'
        ],
      ),
      SpeakingPrompt(
        id: 's2',
        title: 'Shadowing 1',
        mode: SpeakingMode.shadowing,
        context: 'Shadowing: Listen to the sentence and then immediately repeat it with the same rhythm.',
        targets: [
          'Learning a new language is a journey, not a race.',
          'Consistency beats intensity when building a habit.',
        ],
        tips: [
          'Listen first, then repeat closely following the rhythm.',
          'Focus on the stress and intonation.'
        ],
      ),
      SpeakingPrompt(
        id: 's3',
        title: 'Quick Q&A',
        mode: SpeakingMode.qna,
        context: 'Give quick answers to the questions. You have 5 seconds to think.',
        targets: [
          'What do you usually have for breakfast?',
          'How do you relax after a busy day?',
        ],
        tips: [
          'Give the first natural answer that comes to mind.',
          'Reduce pauses and aim for fluency.'
        ],
      ),
      SpeakingPrompt(
        id: 's4',
        title: 'Repetition Practice',
        mode: SpeakingMode.repeat,
        context: 'Repeat the sentence with clear and precise pronunciation.',
        targets: [
          'Practice makes progress.',
          'Small steps every day create big change.',
        ],
        tips: [
          'Speak with a clear and understandable voice.',
          'Focus on clear articulation; don\'t rush.'
        ],
      ),
    ];
  }
}
