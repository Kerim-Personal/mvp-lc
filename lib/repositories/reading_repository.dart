// lib/repositories/reading_repository.dart
import 'package:lingua_chat/models/reading_models.dart';

class ReadingRepository {
  ReadingRepository._();
  static final ReadingRepository instance = ReadingRepository._();

  final List<ReadingStory> _stories = _seed();

  List<ReadingStory> all() => List.unmodifiable(_stories);
  ReadingStory? byId(String id) => _stories.firstWhere((e) => e.id == id, orElse: () => _stories.first);

  static List<ReadingStory> _seed() {
    return [
      const ReadingStory(
        id: 'r1',
        title: 'A Busy Morning',
        category: 'Daily Life',
        level: ReadingLevel.beginner,
        description: 'Simple morning routine story.',
        content: 'Emma wakes up early. She opens the window and feels the fresh air. She makes a cup of tea. Then she writes a short list for the day. Emma likes quiet mornings.',
      ),
      const ReadingStory(
        id: 'r2',
        title: 'The Lost Key',
        category: 'Mystery',
        level: ReadingLevel.intermediate,
        description: 'A small mystery about a missing key.',
        content: 'Liam arrives home and cannot find his key. He checks every pocket twice. He looks under the doormat and inside a dusty plant pot. A light rain starts to fall. Finally he remembers the small coffee shop. The key is still on the counter where he paid. He laughs at himself and walks back through the rain.',
      ),
      const ReadingStory(
        id: 'r3',
        title: 'Winds Above the Valley',
        category: 'Literary',
        level: ReadingLevel.advanced,
        description: 'Reflective descriptive prose.',
        content: 'High above the valley the old observatory groans with each cold gust. Cables hum like distant bees while rusted panels tremble. Inside, charts fade at the edges and dust softens the bold ink of forgotten discoveries. Yet the silence is not empty; it is a spacious pause holding the weight of patient questions. Outside, night gathers its scattered colors, folding them into a deep indigo that promises another clear dawn for anyone still willing to look upward.',
      ),
    ];
  }
}

