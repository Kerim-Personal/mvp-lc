// lib/repositories/writing_repository.dart
import '../models/writing_models.dart';

class WritingRepository {
  static final instance = WritingRepository._();
  WritingRepository._();

  final List<WritingTask> _tasks = [
    // Başlangıç seviyesi
    WritingTask(
      id: 'beginner_1',
      task: 'Introduce yourself. Write about your name, age, where you live, and what you like to do.',
      level: WritingLevel.beginner,
      emoji: '👋',
    ),
    WritingTask(
      id: 'beginner_2',
      task: 'Describe your daily routine. What do you do in the morning, afternoon, and evening?',
      level: WritingLevel.beginner,
      emoji: '🌅',
    ),
    WritingTask(
      id: 'beginner_3',
      task: 'Write about your favorite food. What is it? Why do you like it?',
      level: WritingLevel.beginner,
      emoji: '🍕',
    ),
    WritingTask(
      id: 'beginner_4',
      task: 'Describe your best friend. What do they look like? What do you do together?',
      level: WritingLevel.beginner,
      emoji: '👫',
    ),
    WritingTask(
      id: 'beginner_5',
      task: 'Write about your family. How many people are in your family? What are they like?',
      level: WritingLevel.beginner,
      emoji: '👨‍👩‍👧‍👦',
    ),
    
    // Orta seviye
    WritingTask(
      id: 'intermediate_1',
      task: 'Write an email to a friend inviting them to your birthday party. Include date, time, location, and what you will do.',
      level: WritingLevel.intermediate,
      emoji: '📧',
    ),
    WritingTask(
      id: 'intermediate_2',
      task: 'Describe a memorable vacation you had. Where did you go? What did you do? Why was it special?',
      level: WritingLevel.intermediate,
      emoji: '✈️',
    ),
    WritingTask(
      id: 'intermediate_3',
      task: 'Write your opinion about learning languages online. What are the advantages and disadvantages?',
      level: WritingLevel.intermediate,
      emoji: '💭',
    ),
    WritingTask(
      id: 'intermediate_4',
      task: 'Tell a story about a time you helped someone or someone helped you. What happened?',
      level: WritingLevel.intermediate,
      emoji: '🤝',
    ),
    WritingTask(
      id: 'intermediate_5',
      task: 'Describe your dream job. What would you do? Why would you enjoy it?',
      level: WritingLevel.intermediate,
      emoji: '💼',
    ),
    
    // İleri seviye
    WritingTask(
      id: 'advanced_1',
      task: 'Write an essay discussing whether technology makes us more or less social. Provide examples and arguments.',
      level: WritingLevel.advanced,
      emoji: '📱',
    ),
    WritingTask(
      id: 'advanced_2',
      task: 'Describe a controversial decision you had to make. What factors did you consider? Do you think you made the right choice?',
      level: WritingLevel.advanced,
      emoji: '🤔',
    ),
    WritingTask(
      id: 'advanced_3',
      task: 'Write a persuasive article about an environmental issue you care about. Convince readers to take action.',
      level: WritingLevel.advanced,
      emoji: '🌍',
    ),
    WritingTask(
      id: 'advanced_4',
      task: 'Analyze how social media has changed the way people communicate. Discuss both positive and negative impacts.',
      level: WritingLevel.advanced,
      emoji: '💬',
    ),
    WritingTask(
      id: 'advanced_5',
      task: 'Write a short story that includes a surprising twist at the end. Make it engaging and well-structured.',
      level: WritingLevel.advanced,
      emoji: '📖',
    ),
  ];

  List<WritingTask> getAllTasks() => List.unmodifiable(_tasks);
  
  List<WritingTask> getTasksByLevel(WritingLevel level) {
    return _tasks.where((task) => task.level == level).toList();
  }
  
  WritingTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }
}
