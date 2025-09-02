// lib/repositories/listening_repository.dart
import 'package:lingua_chat/models/listening_models.dart';

/// Simple in-memory repository (can be replaced with Firestore / Remote API in the future)
class ListeningRepository {
  static final ListeningRepository instance = ListeningRepository._();
  ListeningRepository._();

  final List<ListeningExercise> _exercises = _seed();

  List<ListeningExercise> all() => List.unmodifiable(_exercises);
  ListeningExercise? byId(String id) => _exercises.firstWhere(
        (e) => e.id == id,
    orElse: () => const ListeningExercise(
      id: 'not_found',
      title: 'Not Found',
      category: 'N/A',
      level: ListeningLevel.beginner,
      audioUrl: 'asset:sweet-music.mp3', // A placeholder, should not be reached
      durationMs: 10000,
      transcript: 'Exercise not found.',
      timings: [],
      questions: [],
    ),
  );

  static List<ListeningExercise> _seed() {
    // Helper: generate rough timings from transcript (approx. 500ms per word + 60ms gap)
    List<WordTiming> _timings(String transcript) {
      final words = transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final list = <WordTiming>[];
      int cursor = 0;
      for (final w in words) {
        const wordLen = 500; // 0.50 sec
        list.add(WordTiming(word: w, startMs: cursor, endMs: cursor + wordLen));
        cursor += wordLen + 60; // gap
      }
      return list;
    }

    // --- DIFFICULTY-ALIGNED TRANSCRIPTS ---
    // Beginner (A1/A2): short, simple words and sentences
    String introSimple = 'I wake up. I drink a glass of water. I open the window and feel the cool air. Then I make a simple breakfast: bread, cheese, and tea. After eating I write a short to-do list. This helps me start my day calm and clear.';

    String storySimple = 'Maya left the big city. She now lives near the sea. The town is quiet. She walks to the small market and says hello to the same friendly people. At home she washes dishes and listens to a short English story. Little by little she understands faster.';

    String travelDialog = 'A: Excuse me, is this seat free? B: Yes, you can sit. A: Thank you. Is this the train to Brighton? B: Yes, but it is ten minutes late. A: Okay, I still have time. B: They will announce it soon.';

    // Intermediate (B1/B2): longer, compound sentences but non-technical
    String marketsIntermediate = 'Street markets give people a flexible place to buy food and talk. When prices change, sellers adjust quickly and customers compare options. New residents practice daily conversation, learn local jokes, and pick up polite phrases without a formal class. In this way the market teaches language and culture at the same time.';

    String restInterviewIntermediate = 'Interviewer: You say rest builds better work. What do you mean? Guest: Focus uses energy and creates weak spots. Rest lets the brain repair and organize what we learned. Interviewer: So taking breaks is not lazy? Guest: No, a planned break protects quality and reduces hidden stress.';

    // Advanced (C1/C2): more abstract or technical terminology
    String techEnergyAdvanced = 'A new open source layer now profiles energy use in common machine learning inference runtimes. It instruments allocator events and presents a compact live timeline so engineers can decide when to release GPU context state. Early adopters report notable overnight energy reductions across translation clusters.';

    String photosynthesisAdvanced = 'Photosynthesis is often shown as a tidy equation, yet inside the chloroplast an intricate sequence manages energy with remarkable precision. Antenna complexes channel excitations, reaction centers separate charge, and proton gradients drive ATP synthase to synthesize chemical fuel. These coupled efficiencies inspire biomimetic carbon capture designs.';

    String deliberateRestAdvanced = 'Deliberate rest functions like an internal refactoring cycle. Intense cognitive sprints accumulate structural noise; strategically timed disengagement allows consolidation, pruning fragile associations while strengthening frequently co-activated networks. Neglecting this cycle creates biological technical debt that degrades long-term creative throughput.';

    final exercises = <ListeningExercise>[
      // BEGINNER
      ListeningExercise(
        id: 'intro_daily_routines',
        title: 'Simple Morning Routine',
        category: 'Daily Life',
        level: ListeningLevel.beginner,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: introSimple,
        timings: _timings(introSimple),
        accent: 'US',
        skills: const [],
        description: 'A simple morning routine (A1/A2).',
        questions: const [
          ListeningQuestion(
            id: 'b_intro_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What is for breakfast?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Cake and coffee'),
              ListeningQuestionOption(id: 'b', text: 'Bread, cheese, and tea'),
              ListeningQuestionOption(id: 'c', text: 'Eggs and fish'),
              ListeningQuestionOption(id: 'd', text: 'Pasta'),
            ],
            correctOptionId: 'b',
            startMs: 0,
            endMs: 7000,
          ),
          ListeningQuestion(
            id: 'b_intro_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'I drink a glass of ______.',
            answer: 'water',
            startMs: 0,
            endMs: 4000,
          ),
          ListeningQuestion(
            id: 'b_intro_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What does the to-do list provide?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Stress'),
              ListeningQuestionOption(id: 'b', text: 'A calm and clear start'),
              ListeningQuestionOption(id: 'c', text: 'Chaos'),
              ListeningQuestionOption(id: 'd', text: 'Sleep'),
            ],
            correctOptionId: 'b',
            startMs: 4000,
            endMs: 9000,
          ),
          ListeningQuestion(
            id: 'b_intro_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'I make a simple ______.',
            answer: 'breakfast',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'b_intro_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: I open the window.',
            answer: 'i open the window',
            startMs: 0,
            endMs: 6000,
          ),
        ],
      ),
      ListeningExercise(
        id: 'story_coast_move',
        title: 'Maya Moves',
        category: 'Story',
        level: ListeningLevel.beginner,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: storySimple,
        timings: _timings(storySimple),
        accent: 'US',
        skills: const [],
        description: 'A short story about moving (A1/A2).',
        questions: const [
          ListeningQuestion(
            id: 'b_story_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Where does Maya live near now?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'The sea'),
              ListeningQuestionOption(id: 'b', text: 'A mountain'),
              ListeningQuestionOption(id: 'c', text: 'A desert'),
              ListeningQuestionOption(id: 'd', text: 'A forest'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'b_story_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'She listens to a short English ______.',
            answer: 'story',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'b_story_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'How are the people in the market?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Angry'),
              ListeningQuestionOption(id: 'b', text: 'Silent'),
              ListeningQuestionOption(id: 'c', text: 'Friendly'),
              ListeningQuestionOption(id: 'd', text: 'Scared'),
            ],
            correctOptionId: 'c',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'b_story_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'She now lives near the ______.',
            answer: 'sea',
            startMs: 0,
            endMs: 3000,
          ),
          ListeningQuestion(
            id: 'b_story_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: Little by little.',
            answer: 'little by little',
            startMs: 0,
            endMs: 6000,
          ),
        ],
      ),
      ListeningExercise(
        id: 'dialog_travel',
        title: 'Train to Brighton',
        category: 'Conversation',
        level: ListeningLevel.beginner,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: travelDialog,
        timings: _timings(travelDialog),
        accent: 'UK',
        skills: const [],
        description: 'A short train dialogue (A1/A2).',
        questions: const [
          ListeningQuestion(
            id: 'b_dialog_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'How many minutes is the train late?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Five'),
              ListeningQuestionOption(id: 'b', text: 'Ten'),
              ListeningQuestionOption(id: 'c', text: 'Thirty'),
              ListeningQuestionOption(id: 'd', text: 'Twenty'),
            ],
            correctOptionId: 'b',
            startMs: 0,
            endMs: 5000,
          ),
          ListeningQuestion(
            id: 'b_dialog_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'Is this the ______ to Brighton?',
            answer: 'train',
            startMs: 0,
            endMs: 4000,
          ),
          ListeningQuestion(
            id: 'b_dialog_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Is the seat free?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'No'),
              ListeningQuestionOption(id: 'b', text: 'Yes'),
              ListeningQuestionOption(id: 'c', text: 'We don\'t know'),
              ListeningQuestionOption(id: 'd', text: 'Maybe'),
            ],
            correctOptionId: 'b',
            startMs: 0,
            endMs: 3000,
          ),
          ListeningQuestion(
            id: 'b_dialog_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'It is ten minutes ______.',
            answer: 'late',
            startMs: 0,
            endMs: 5000,
          ),
          ListeningQuestion(
            id: 'b_dialog_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: Thank you.',
            answer: 'thank you',
            startMs: 0,
            endMs: 3000,
          ),
        ],
      ),
      // INTERMEDIATE
      ListeningExercise(
        id: 'culture_markets',
        title: 'Markets and Language',
        category: 'Culture',
        level: ListeningLevel.intermediate,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: marketsIntermediate,
        timings: _timings(marketsIntermediate),
        accent: 'US',
        skills: const [],
        description: 'The social role of markets (B1/B2).',
        questions: const [
          ListeningQuestion(
            id: 'i_markets_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What do newcomers learn at the market?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Official laws'),
              ListeningQuestionOption(id: 'b', text: 'Local jokes and polite phrases'),
              ListeningQuestionOption(id: 'c', text: 'Only prices'),
              ListeningQuestionOption(id: 'd', text: 'Nothing'),
            ],
            correctOptionId: 'b',
            startMs: 0,
            endMs: 7000,
          ),
          ListeningQuestion(
            id: 'i_markets_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'The market teaches language and ______ at the same time.',
            answer: 'culture',
            startMs: 4000,
            endMs: 9000,
          ),
          ListeningQuestion(
            id: 'i_markets_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What do sellers do when prices change?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'They adjust quickly'),
              ListeningQuestionOption(id: 'b', text: 'They close the shop'),
              ListeningQuestionOption(id: 'c', text: 'They hide the price'),
              ListeningQuestionOption(id: 'd', text: 'They shout'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'i_markets_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'New residents practice daily ______.',
            answer: 'conversation',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_markets_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: flexible place',
            answer: 'flexible place',
            startMs: 0,
            endMs: 4000,
          ),
        ],
      ),
      ListeningExercise(
        id: 'interview_rest',
        title: 'Planned Breaks',
        category: 'Interview',
        level: ListeningLevel.intermediate,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: restInterviewIntermediate,
        timings: _timings(restInterviewIntermediate),
        accent: 'US',
        skills: const [],
        description: 'The effect of rest (B1/B2).',
        questions: const [
          ListeningQuestion(
            id: 'i_rest_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'According to the guest, what does a planned break do?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'It protects quality'),
              ListeningQuestionOption(id: 'b', text: 'It increases stress'),
              ListeningQuestionOption(id: 'c', text: 'It wastes energy'),
              ListeningQuestionOption(id: 'd', text: 'It prevents focus'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_rest_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'Rest lets the brain ______ and organize what we learned.',
            answer: 'repair',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_rest_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What does focus create?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Weak spots'),
              ListeningQuestionOption(id: 'b', text: 'Endless energy'),
              ListeningQuestionOption(id: 'c', text: 'Deep sleep'),
              ListeningQuestionOption(id: 'd', text: 'Nothing'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_rest_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'A planned break protects ______.',
            answer: 'quality',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_rest_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: taking breaks',
            answer: 'taking breaks',
            startMs: 0,
            endMs: 6000,
          ),
        ],
      ),
      // ADVANCED
      ListeningExercise(
        id: 'tech_energy',
        title: 'Profiling Inference Energy',
        category: 'Technology',
        level: ListeningLevel.advanced,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: techEnergyAdvanced,
        timings: _timings(techEnergyAdvanced),
        accent: 'UK',
        skills: const [],
        description: 'Energy profiling layer (C1/C2).',
        questions: const [
          ListeningQuestion(
            id: 'a_energy_q1',
            type: ListeningQuestionType.gapFill,
            prompt: 'Layer profiles energy use in machine learning ______ runtimes.',
            answer: 'inference',
            startMs: 0,
            endMs: 7000,
          ),
          ListeningQuestion(
            id: 'a_energy_q2',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Engineers can decide when to release what?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'GPU context state'),
              ListeningQuestionOption(id: 'b', text: 'Color scale selection'),
              ListeningQuestionOption(id: 'c', text: 'Music tempo'),
              ListeningQuestionOption(id: 'd', text: 'Camera angle'),
            ],
            correctOptionId: 'a',
            startMs: 4000,
            endMs: 10000,
          ),
          ListeningQuestion(
            id: 'a_energy_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What does the layer instrument?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Allocator events'),
              ListeningQuestionOption(id: 'b', text: 'Sound waves'),
              ListeningQuestionOption(id: 'c', text: 'Color palette'),
              ListeningQuestionOption(id: 'd', text: 'GPS signal'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_energy_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'It presents a compact live ______.',
            answer: 'timeline',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_energy_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: energy reductions',
            answer: 'energy reductions',
            startMs: 0,
            endMs: 8000,
          ),
        ],
      ),
      ListeningExercise(
        id: 'science_photosynthesis',
        title: 'Chloroplast Dynamics',
        category: 'Science',
        level: ListeningLevel.advanced,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: photosynthesisAdvanced,
        timings: _timings(photosynthesisAdvanced),
        accent: 'US',
        skills: const [],
        description: 'The internal processes of photosynthesis (C1/C2).',
        questions: const [
          ListeningQuestion(
            id: 'a_photo_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What do antenna complexes channel?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Excitations'),
              ListeningQuestionOption(id: 'b', text: 'Mineral salts'),
              ListeningQuestionOption(id: 'c', text: 'Nitrogen gas'),
              ListeningQuestionOption(id: 'd', text: 'Fat droplets'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 7000,
          ),
          ListeningQuestion(
            id: 'a_photo_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'Proton gradients drive ATP ______.',
            answer: 'synthase',
            startMs: 4000,
            endMs: 9000,
          ),
          ListeningQuestion(
            id: 'a_photo_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'How is the sequence inside the chloroplast?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Intricate'),
              ListeningQuestionOption(id: 'b', text: 'Simple'),
              ListeningQuestionOption(id: 'c', text: 'Not visible'),
              ListeningQuestionOption(id: 'd', text: 'Flat'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'a_photo_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'Coupled efficiencies inspire ______ designs.',
            answer: 'biomimetic',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_photo_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: chemical fuel',
            answer: 'chemical fuel',
            startMs: 0,
            endMs: 7000,
          ),
        ],
      ),
      ListeningExercise(
        id: 'interview_rest_advanced',
        title: 'Deliberate Rest Cycle',
        category: 'Interview',
        level: ListeningLevel.advanced,
        audioUrl: 'tts:',
        durationMs: 0,
        transcript: deliberateRestAdvanced,
        timings: _timings(deliberateRestAdvanced),
        accent: 'US',
        skills: const [],
        description: 'The neurocognitive effect of deliberate rest (C1/C2).',
        questions: const [
          ListeningQuestion(
            id: 'a_rest_q1',
            type: ListeningQuestionType.gapFill,
            prompt: 'Deliberate rest allows the ______ of fragile associations.',
            answer: 'pruning',
            startMs: 0,
            endMs: 7000,
          ),
          ListeningQuestion(
            id: 'a_rest_q2',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What does a lack of rest create?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Biological technical debt'),
              ListeningQuestionOption(id: 'b', text: 'Instant perfection'),
              ListeningQuestionOption(id: 'c', text: 'Permanent energy surplus'),
              ListeningQuestionOption(id: 'd', text: 'Full immunity'),
            ],
            correctOptionId: 'a',
            startMs: 4000,
            endMs: 10000,
          ),
          ListeningQuestion(
            id: 'a_rest_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'What do intense cognitive sprints accumulate?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Structural noise'),
              ListeningQuestionOption(id: 'b', text: 'Clean energy'),
              ListeningQuestionOption(id: 'c', text: 'A void'),
              ListeningQuestionOption(id: 'd', text: 'Nothing'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'a_rest_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'It strengthens frequently co-activated ______.',
            answer: 'networks',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_rest_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Dictate: creative throughput',
            answer: 'creative throughput',
            startMs: 0,
            endMs: 8000,
          ),
        ],
      ),
    ];
    return exercises;
  }
}