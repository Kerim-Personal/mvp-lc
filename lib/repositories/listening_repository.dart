// lib/repositories/listening_repository.dart
import 'package:lingua_chat/models/listening_models.dart';

/// Basit in-memory repository (ileride Firestore / Remote API ile değiştirilebilir)
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
          audioUrl: 'asset:tatli-muzik.mp3',
          durationMs: 10000,
          transcript: 'Exercise not found.',
          timings: [],
          questions: [],
        ),
      );

  static List<ListeningExercise> _seed() {
    // Helper: transcript'ten kaba timing üret (kelime başına ~500ms + 60ms boşluk)
    List<WordTiming> _timings(String transcript) {
      final words = transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final list = <WordTiming>[];
      int cursor = 0;
      for (final w in words) {
        const wordLen = 500; // 0.50 sn
        list.add(WordTiming(word: w, startMs: cursor, endMs: cursor + wordLen));
        cursor += wordLen + 60; // boşluk
      }
      return list;
    }

    // --- ZORLUK UYUMLU TRANSCRIPT'LER ---
    // Beginner (A1/A2): kısa, basit kelime ve cümleler
    String introSimple = 'I wake up. I drink a glass of water. I open the window and feel the cool air. Then I make a simple breakfast: bread, cheese, and tea. After eating I write a short to-do list. This helps me start my day calm and clear.';

    String storySimple = 'Maya left the big city. She now lives near the sea. The town is quiet. She walks to the small market and says hello to the same friendly people. At home she washes dishes and listens to a short English story. Little by little she understands faster.';

    String travelDialog = 'A: Excuse me, is this seat free? B: Yes, you can sit. A: Thank you. Is this the train to Brighton? B: Yes, but it is ten minutes late. A: Okay, I still have time. B: They will announce it soon.';

    // Intermediate (B1/B2): daha uzun, birleşik cümleler fakat teknik olmayan
    String marketsIntermediate = 'Street markets give people a flexible place to buy food and talk. When prices change, sellers adjust quickly and customers compare options. New residents practice daily conversation, learn local jokes, and pick up polite phrases without a formal class. In this way the market teaches language and culture at the same time.';

    String restInterviewIntermediate = 'Interviewer: You say rest builds better work. What do you mean? Guest: Focus uses energy and creates weak spots. Rest lets the brain repair and organize what we learned. Interviewer: So taking breaks is not lazy? Guest: No, a planned break protects quality and reduces hidden stress.';

    // Advanced (C1/C2): daha soyut veya teknik terminoloji
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
        description: 'Basit sabah rutini (A1/A2).',
        questions: const [
          ListeningQuestion(
            id: 'b_intro_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Kahvaltıda ne var?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Pasta ve kahve'),
              ListeningQuestionOption(id: 'b', text: 'Bread cheese and tea'),
              ListeningQuestionOption(id: 'c', text: 'Yumurta ve balık'),
              ListeningQuestionOption(id: 'd', text: 'Makarna'),
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
            prompt: 'To-do list ne sağlıyor?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Stres'),
              ListeningQuestionOption(id: 'b', text: 'Calm and clear start'),
              ListeningQuestionOption(id: 'c', text: 'Karmaşa'),
              ListeningQuestionOption(id: 'd', text: 'Uyku'),
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
            prompt: 'Yaz: I open the window.',
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
        description: 'Kısa taşınma hikâyesi (A1/A2).',
        questions: const [
          ListeningQuestion(
            id: 'b_story_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Maya şimdi nereye yakın yaşıyor?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Deniz'),
              ListeningQuestionOption(id: 'b', text: 'Dağ'),
              ListeningQuestionOption(id: 'c', text: 'Çöl'),
              ListeningQuestionOption(id: 'd', text: 'Orman'),
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
            prompt: 'People in the market nasıllar?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Angry'),
              ListeningQuestionOption(id: 'b', text: 'Silent'),
              ListeningQuestionOption(id: 'c', text: 'Friendly'),
              ListeningQuestionOption(id: 'd', text: 'Korkmuş'),
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
            prompt: 'Yaz: Little by little.',
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
        description: 'Kısa tren diyaloğu (A1/A2).',
        questions: const [
          ListeningQuestion(
            id: 'b_dialog_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Tren kaç dakika geç?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Beş'),
              ListeningQuestionOption(id: 'b', text: 'On'),
              ListeningQuestionOption(id: 'c', text: 'Otuz'),
              ListeningQuestionOption(id: 'd', text: 'Yirmi'),
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
            prompt: 'Koltuk boş mu?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Hayır'),
              ListeningQuestionOption(id: 'b', text: 'Evet'),
              ListeningQuestionOption(id: 'c', text: 'Bilmiyoruz'),
              ListeningQuestionOption(id: 'd', text: 'Belki'),
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
            prompt: 'Yaz: Thank you.',
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
        description: 'Pazarların sosyal rolü (B1/B2).',
        questions: const [
          ListeningQuestion(
            id: 'i_markets_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Yeni gelenler pazarda ne öğreniyor?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Resmi yasalar'),
              ListeningQuestionOption(id: 'b', text: 'Yerel şakalar ve nazik ifadeler'),
              ListeningQuestionOption(id: 'c', text: 'Sadece fiyatlar'),
              ListeningQuestionOption(id: 'd', text: 'Hiçbir şey'),
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
            prompt: 'When prices change sellers ne yapıyor?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Hemen uyum sağlar'),
              ListeningQuestionOption(id: 'b', text: 'Dükkanı kapatır'),
              ListeningQuestionOption(id: 'c', text: 'Fiyatı gizler'),
              ListeningQuestionOption(id: 'd', text: 'Bağırır'),
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
            prompt: 'Yaz: flexible place',
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
        description: 'Dinlenmenin etkisi (B1/B2).',
        questions: const [
          ListeningQuestion(
            id: 'i_rest_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Konuk göre planlı mola ne yapar?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Kaliteyi korur'),
              ListeningQuestionOption(id: 'b', text: 'Stresi artırır'),
              ListeningQuestionOption(id: 'c', text: 'Enerjiyi boşa harcar'),
              ListeningQuestionOption(id: 'd', text: 'Odaklanmayı engeller'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_rest_q2',
            type: ListeningQuestionType.gapFill,
            prompt: 'Rest lets the brain ______ what we learned.',
            answer: 'repair',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'i_rest_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Focus ne üretir?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Weak spots'),
              ListeningQuestionOption(id: 'b', text: 'Sonsuz enerji'),
              ListeningQuestionOption(id: 'c', text: 'Derin uyku'),
              ListeningQuestionOption(id: 'd', text: 'Hiçbir şey'),
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
            prompt: 'Yaz: taking breaks',
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
        description: 'Enerji profil katmanı (C1/C2).',
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
            prompt: 'Mühendisler ne zaman karar verebiliyor?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Context state release'),
              ListeningQuestionOption(id: 'b', text: 'Renk skalası seçimi'),
              ListeningQuestionOption(id: 'c', text: 'Müzik temposu'),
              ListeningQuestionOption(id: 'd', text: 'Kamera açısı'),
            ],
            correctOptionId: 'a',
            startMs: 4000,
            endMs: 10000,
          ),
          ListeningQuestion(
            id: 'a_energy_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Katman neyi enstrümante ediyor?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Allocator events'),
              ListeningQuestionOption(id: 'b', text: 'Ses dalgaları'),
              ListeningQuestionOption(id: 'c', text: 'Renk paleti'),
              ListeningQuestionOption(id: 'd', text: 'GPS sinyali'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_energy_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'Presents a compact live ______.',
            answer: 'timeline',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_energy_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Yaz: energy reductions',
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
        description: 'Fotosentezin iç süreçleri (C1/C2).',
        questions: const [
          ListeningQuestion(
            id: 'a_photo_q1',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Antenna complexes neyi kanalize eder?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Excitations'),
              ListeningQuestionOption(id: 'b', text: 'Mineral tuzları'),
              ListeningQuestionOption(id: 'c', text: 'Azot gazı'),
              ListeningQuestionOption(id: 'd', text: 'Yağ damlaları'),
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
            prompt: 'Sequence inside chloroplast nasıl?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'İntricate'),
              ListeningQuestionOption(id: 'b', text: 'Basit'),
              ListeningQuestionOption(id: 'c', text: 'Görünmez değil'),
              ListeningQuestionOption(id: 'd', text: 'Düz'),
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
            prompt: 'Yaz: chemical fuel',
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
        description: 'Bilinçli dinlenmenin nörobilişsel etkisi (C1/C2).',
        questions: const [
          ListeningQuestion(
            id: 'a_rest_q1',
            type: ListeningQuestionType.gapFill,
            prompt: 'Deliberate rest allows ______ of fragile associations.',
            answer: 'pruning',
            startMs: 0,
            endMs: 7000,
          ),
          ListeningQuestion(
            id: 'a_rest_q2',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Dinlenme eksikliği ne üretir?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Biological technical debt'),
              ListeningQuestionOption(id: 'b', text: 'Anında mükemmellik'),
              ListeningQuestionOption(id: 'c', text: 'Kalıcı enerji fazlası'),
              ListeningQuestionOption(id: 'd', text: 'Tam bağışıklık'),
            ],
            correctOptionId: 'a',
            startMs: 4000,
            endMs: 10000,
          ),
          ListeningQuestion(
            id: 'a_rest_q3',
            type: ListeningQuestionType.multipleChoice,
            prompt: 'Intense cognitive sprints ne biriktirir?',
            options: [
              ListeningQuestionOption(id: 'a', text: 'Structural noise'),
              ListeningQuestionOption(id: 'b', text: 'Temiz enerji'),
              ListeningQuestionOption(id: 'c', text: 'Boşluk'),
              ListeningQuestionOption(id: 'd', text: 'Hiçbir şey'),
            ],
            correctOptionId: 'a',
            startMs: 0,
            endMs: 6000,
          ),
          ListeningQuestion(
            id: 'a_rest_q4',
            type: ListeningQuestionType.gapFill,
            prompt: 'Strengthening frequently co-activated ______.',
            answer: 'networks',
            startMs: 0,
            endMs: 8000,
          ),
          ListeningQuestion(
            id: 'a_rest_q5',
            type: ListeningQuestionType.dictation,
            prompt: 'Yaz: creative throughput',
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
