// lib/repositories/writing_repository.dart
import 'dart:math' as math;
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
    WritingTask(
      id: 'beginner_6',
      task: 'Describe your room. What furniture is there? What colors are the walls? Do you like it?',
      level: WritingLevel.beginner,
      emoji: '🛏️',
    ),
    WritingTask(
      id: 'beginner_7',
      task: 'Write about your last weekend. Where did you go? Who did you meet? What did you do?',
      level: WritingLevel.beginner,
      emoji: '📅',
    ),
    WritingTask(
      id: 'beginner_8',
      task: 'Describe your favorite animal. What does it look like? Where does it live? Why do you like it?',
      level: WritingLevel.beginner,
      emoji: '🐾',
    ),
    WritingTask(
      id: 'beginner_9',
      task: 'Talk about a typical school or work day. When do you start and finish? What are your breaks like?',
      level: WritingLevel.beginner,
      emoji: '🏫',
    ),
    WritingTask(
      id: 'beginner_10',
      task: 'Give step-by-step instructions to make a simple sandwich. Use sequence words like first, then, next, finally.',
      level: WritingLevel.beginner,
      emoji: '🥪',
    ),
    WritingTask(
      id: 'beginner_11',
      task: 'Describe the weather today. How does the weather make you feel? What will you wear?',
      level: WritingLevel.beginner,
      emoji: '⛅',
    ),
    WritingTask(
      id: 'beginner_12',
      task: 'Write about what you wear in different seasons. What do you wear in winter and summer?',
      level: WritingLevel.beginner,
      emoji: '🧥',
    ),
    WritingTask(
      id: 'beginner_13',
      task: 'Describe your hobbies. When did you start them? How often do you do them?',
      level: WritingLevel.beginner,
      emoji: '🎨',
    ),
    WritingTask(
      id: 'beginner_14',
      task: 'Write about your city or town. What places can people visit? What is special about it?',
      level: WritingLevel.beginner,
      emoji: '🏙️',
    ),
    WritingTask(
      id: 'beginner_15',
      task: 'Describe a person you admire. What are they like? What do they do?',
      level: WritingLevel.beginner,
      emoji: '🌟',
    ),
    WritingTask(
      id: 'beginner_16',
      task: 'Write about the apps you use most on your phone and why you use them.',
      level: WritingLevel.beginner,
      emoji: '📱',
    ),
    WritingTask(
      id: 'beginner_17',
      task: 'Explain your morning routine step by step from waking up to leaving home.',
      level: WritingLevel.beginner,
      emoji: '⏰',
    ),
    WritingTask(
      id: 'beginner_18',
      task: 'Describe a visit to the supermarket. What do you buy? How do you pay?',
      level: WritingLevel.beginner,
      emoji: '🛒',
    ),
    WritingTask(
      id: 'beginner_19',
      task: 'Write about using public transport. Which transport do you prefer and why?',
      level: WritingLevel.beginner,
      emoji: '🚌',
    ),
    WritingTask(
      id: 'beginner_20',
      task: 'Describe your dream vacation in simple words. Where would you go and what would you do?',
      level: WritingLevel.beginner,
      emoji: '🏖️',
    ),
    WritingTask(
      id: 'beginner_21',
      task: 'Write about your pet or a pet you would like to have. How would you take care of it?',
      level: WritingLevel.beginner,
      emoji: '🐶',
    ),
    WritingTask(
      id: 'beginner_22',
      task: 'Describe your favorite movie in simple words. Who are the characters? What happens?',
      level: WritingLevel.beginner,
      emoji: '🎬',
    ),
    WritingTask(
      id: 'beginner_23',
      task: 'Explain how you celebrate a holiday or special day in your country.',
      level: WritingLevel.beginner,
      emoji: '🎉',
    ),
    WritingTask(
      id: 'beginner_24',
      task: 'Write about your best teacher. What did they teach you and how did they help you?',
      level: WritingLevel.beginner,
      emoji: '👩‍🏫',
    ),
    WritingTask(
      id: 'beginner_25',
      task: 'Describe your favorite place to relax. Where is it and why do you like it?',
      level: WritingLevel.beginner,
      emoji: '🛋️',
    ),
    WritingTask(
      id: 'beginner_26',
      task: 'Write a simple recipe you know. List the ingredients and steps.',
      level: WritingLevel.beginner,
      emoji: '🍲',
    ),
    WritingTask(
      id: 'beginner_27',
      task: 'Talk about a time you felt very happy. What happened and why?',
      level: WritingLevel.beginner,
      emoji: '😄',
    ),
    WritingTask(
      id: 'beginner_28',
      task: 'Explain what you do to stay healthy. What do you eat and what exercise do you do?',
      level: WritingLevel.beginner,
      emoji: '🏃',
    ),
    WritingTask(
      id: 'beginner_29',
      task: 'Write about your goals for this year. What do you want to learn or achieve?',
      level: WritingLevel.beginner,
      emoji: '🎯',
    ),
    WritingTask(
      id: 'beginner_30',
      task: 'If you had a superpower, what would it be and how would you use it?',
      level: WritingLevel.beginner,
      emoji: '🦸',
    ),
    WritingTask(
      id: 'beginner_31',
      task: 'Describe your first day at a new school or job. How did you feel and what did you do?',
      level: WritingLevel.beginner,
      emoji: '📝',
    ),
    WritingTask(
      id: 'beginner_32',
      task: 'Write a short and polite complaint about a product you bought that did not work.',
      level: WritingLevel.beginner,
      emoji: '✍️',
    ),
    WritingTask(
      id: 'beginner_33',
      task: 'Give directions from your home to a place you often visit. Use left, right, straight.',
      level: WritingLevel.beginner,
      emoji: '🧭',
    ),
    WritingTask(
      id: 'beginner_34',
      task: 'Describe your neighborhood. What places are nearby? Are there parks or shops?',
      level: WritingLevel.beginner,
      emoji: '🏘️',
    ),
    WritingTask(
      id: 'beginner_35',
      task: 'Talk about a sport you like. How do you play it and why do you enjoy it?',
      level: WritingLevel.beginner,
      emoji: '🏀',
    ),
    WritingTask(
      id: 'beginner_36',
      task: 'Describe your study routine. When and where do you study? What helps you focus?',
      level: WritingLevel.beginner,
      emoji: '📚',
    ),
    WritingTask(
      id: 'beginner_37',
      task: 'Write about a festival in your country. What do people do, eat, or wear?',
      level: WritingLevel.beginner,
      emoji: '🪅',
    ),
    WritingTask(
      id: 'beginner_38',
      task: 'Describe your favorite book in simple words. What is it about and why do you like it?',
      level: WritingLevel.beginner,
      emoji: '📚',
    ),
    WritingTask(
      id: 'beginner_39',
      task: 'Write about a memorable meal you had. Who were you with and what did you eat?',
      level: WritingLevel.beginner,
      emoji: '🍽️',
    ),
    WritingTask(
      id: 'beginner_40',
      task: 'What do you usually do on rainy days? Describe activities at home or outside.',
      level: WritingLevel.beginner,
      emoji: '🌧️',
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
    WritingTask(
      id: 'intermediate_6',
      task: 'Write a formal email requesting information about a language course. Ask about schedule, price, and level placement.',
      level: WritingLevel.intermediate,
      emoji: '✉️',
    ),
    WritingTask(
      id: 'intermediate_7',
      task: 'Describe a challenge you overcame. What was difficult? How did you solve it? What did you learn?',
      level: WritingLevel.intermediate,
      emoji: '🧗',
    ),
    WritingTask(
      id: 'intermediate_8',
      task: 'Argue whether school uniforms should be mandatory. Present reasons and counterarguments.',
      level: WritingLevel.intermediate,
      emoji: '👔',
    ),
    WritingTask(
      id: 'intermediate_9',
      task: 'Describe an invention that changed your daily life. How does it work and why is it important?',
      level: WritingLevel.intermediate,
      emoji: '💡',
    ),
    WritingTask(
      id: 'intermediate_10',
      task: 'Write a detailed review of a restaurant you visited. Describe service, food, atmosphere, and price.',
      level: WritingLevel.intermediate,
      emoji: '🍽️',
    ),
    WritingTask(
      id: 'intermediate_11',
      task: 'Discuss the benefits of volunteering for individuals and communities. Give examples.',
      level: WritingLevel.intermediate,
      emoji: '👐',
    ),
    WritingTask(
      id: 'intermediate_12',
      task: 'Describe a cultural tradition from your country. Explain its origin and meaning.',
      level: WritingLevel.intermediate,
      emoji: '🎎',
    ),
    WritingTask(
      id: 'intermediate_13',
      task: 'Explain how to manage time effectively. Share techniques that work for you and why.',
      level: WritingLevel.intermediate,
      emoji: '⏳',
    ),
    WritingTask(
      id: 'intermediate_14',
      task: 'Write about a book that influenced you. Summarize the plot and explain its impact on your thinking.',
      level: WritingLevel.intermediate,
      emoji: '📖',
    ),
    WritingTask(
      id: 'intermediate_15',
      task: 'Argue for or against remote work. Consider productivity, work-life balance, and company culture.',
      level: WritingLevel.intermediate,
      emoji: '🏡',
    ),
    WritingTask(
      id: 'intermediate_16',
      task: 'Explain the importance of mental health and how people can maintain it in daily life.',
      level: WritingLevel.intermediate,
      emoji: '🧠',
    ),
    WritingTask(
      id: 'intermediate_17',
      task: 'Describe a historical figure you admire. What did they do and why are they inspiring?',
      level: WritingLevel.intermediate,
      emoji: '🏛️',
    ),
    WritingTask(
      id: 'intermediate_18',
      task: 'Write a how-to guide for saving money on a limited budget. Include practical steps and tips.',
      level: WritingLevel.intermediate,
      emoji: '💰',
    ),
    WritingTask(
      id: 'intermediate_19',
      task: 'Discuss social media privacy concerns and how users can protect themselves.',
      level: WritingLevel.intermediate,
      emoji: '🔒',
    ),
    WritingTask(
      id: 'intermediate_20',
      task: 'Describe your ideal city. Consider transportation, green spaces, housing, and safety.',
      level: WritingLevel.intermediate,
      emoji: '🏙️',
    ),
    WritingTask(
      id: 'intermediate_21',
      task: 'Write a short story that begins with: "I woke up and the city was silent." Develop setting and conflict.',
      level: WritingLevel.intermediate,
      emoji: '🌆',
    ),
    WritingTask(
      id: 'intermediate_22',
      task: 'Compare two learning methods you tried (e.g., videos vs. textbooks). Which worked better and why?',
      level: WritingLevel.intermediate,
      emoji: '⚖️',
    ),
    WritingTask(
      id: 'intermediate_23',
      task: 'Discuss whether exams are a fair measure of ability. Offer alternatives and justify them.',
      level: WritingLevel.intermediate,
      emoji: '📝',
    ),
    WritingTask(
      id: 'intermediate_24',
      task: 'Explain the steps to prepare for a job interview. Include research, practice, and follow-up.',
      level: WritingLevel.intermediate,
      emoji: '👔',
    ),
    WritingTask(
      id: 'intermediate_25',
      task: 'Describe a difficult conversation you handled. How did you prepare and what was the result?',
      level: WritingLevel.intermediate,
      emoji: '🗣️',
    ),
    WritingTask(
      id: 'intermediate_26',
      task: 'Write a complaint letter to an airline about lost luggage. Be polite but firm and include details.',
      level: WritingLevel.intermediate,
      emoji: '🧳',
    ),
    WritingTask(
      id: 'intermediate_27',
      task: 'Discuss the impact of climate change in your region. Provide examples and possible solutions.',
      level: WritingLevel.intermediate,
      emoji: '🌡️',
    ),
    WritingTask(
      id: 'intermediate_28',
      task: 'Explain the benefits and risks of artificial intelligence in education. Give concrete cases.',
      level: WritingLevel.intermediate,
      emoji: '🤖',
    ),
    WritingTask(
      id: 'intermediate_29',
      task: 'Tell about a project you led. Describe objectives, obstacles, team roles, and outcomes.',
      level: WritingLevel.intermediate,
      emoji: '🧭',
    ),
    WritingTask(
      id: 'intermediate_30',
      task: 'Debate the statement: "Travel is the best way to learn." Present arguments and counterarguments.',
      level: WritingLevel.intermediate,
      emoji: '🌍',
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
    WritingTask(
      id: 'advanced_6',
      task: 'Critically evaluate the idea of universal basic income. Use evidence to discuss potential benefits and drawbacks.',
      level: WritingLevel.advanced,
      emoji: '🏛️',
    ),
    WritingTask(
      id: 'advanced_7',
      task: 'Analyze the role of algorithmic bias in decision-making systems. Propose strategies to mitigate it.',
      level: WritingLevel.advanced,
      emoji: '⚙️',
    ),
    WritingTask(
      id: 'advanced_8',
      task: 'Debate how governments should regulate big tech companies. Present a concrete policy framework.',
      level: WritingLevel.advanced,
      emoji: '🧩',
    ),
    WritingTask(
      id: 'advanced_9',
      task: 'Explore the ethical implications of gene editing (CRISPR). Consider medical, social, and legal angles.',
      level: WritingLevel.advanced,
      emoji: '🧬',
    ),
    WritingTask(
      id: 'advanced_10',
      task: 'Argue whether art and culture should be publicly funded. Address counterarguments and opportunity costs.',
      level: WritingLevel.advanced,
      emoji: '🎭',
    ),
    WritingTask(
      id: 'advanced_11',
      task: 'Investigate global supply chain resilience after the pandemic. Identify vulnerabilities and solutions.',
      level: WritingLevel.advanced,
      emoji: '🌐',
    ),
    WritingTask(
      id: 'advanced_12',
      task: 'Examine how media literacy can combat misinformation. Propose an education program with metrics.',
      level: WritingLevel.advanced,
      emoji: '📰',
    ),
    WritingTask(
      id: 'advanced_13',
      task: 'Assess the impact of remote work on urban economies and commercial real estate.',
      level: WritingLevel.advanced,
      emoji: '🏙️',
    ),
    WritingTask(
      id: 'advanced_14',
      task: 'Write a literary analysis on a theme of your choice in any novel. Support claims with textual evidence.',
      level: WritingLevel.advanced,
      emoji: '📚',
    ),
    WritingTask(
      id: 'advanced_15',
      task: 'Compose a brief research proposal including background, methodology, hypothesis, and expected results.',
      level: WritingLevel.advanced,
      emoji: '🧪',
    ),
    WritingTask(
      id: 'advanced_16',
      task: 'Compare philosophical positions on free will and determinism. Reference notable thinkers and arguments.',
      level: WritingLevel.advanced,
      emoji: '🤯',
    ),
    WritingTask(
      id: 'advanced_17',
      task: 'Analyze how colonization shaped modern borders. Provide at least two case studies and discuss consequences.',
      level: WritingLevel.advanced,
      emoji: '🗺️',
    ),
    WritingTask(
      id: 'advanced_18',
      task: 'Evaluate carbon pricing mechanisms (tax vs. cap-and-trade). Compare efficiency, equity, and feasibility.',
      level: WritingLevel.advanced,
      emoji: '💨',
    ),
    WritingTask(
      id: 'advanced_19',
      task: 'Write an op-ed on the balance between data privacy and innovation. Use persuasive techniques.',
      level: WritingLevel.advanced,
      emoji: '🔐',
    ),
    WritingTask(
      id: 'advanced_20',
      task: 'Analyze the rhetoric of a famous speech. Identify ethos, pathos, and logos with examples.',
      level: WritingLevel.advanced,
      emoji: '🗣️',
    ),
    WritingTask(
      id: 'advanced_21',
      task: 'Discuss potential implications of quantum computing for modern cryptography and cybersecurity.',
      level: WritingLevel.advanced,
      emoji: '🧮',
    ),
    WritingTask(
      id: 'advanced_22',
      task: 'Propose a startup idea. Include problem statement, market analysis, competition, and go-to-market plan.',
      level: WritingLevel.advanced,
      emoji: '🚀',
    ),
    WritingTask(
      id: 'advanced_23',
      task: 'Design a policy to reduce wealth inequality. Explain mechanisms, trade-offs, and evaluation metrics.',
      level: WritingLevel.advanced,
      emoji: '⚖️',
    ),
    WritingTask(
      id: 'advanced_24',
      task: 'Analyze globalization’s effects on local cultures and languages. Suggest ways to preserve diversity.',
      level: WritingLevel.advanced,
      emoji: '🌏',
    ),
    WritingTask(
      id: 'advanced_25',
      task: 'Evaluate proposals to reform standardized testing. Cite evidence on validity and unintended consequences.',
      level: WritingLevel.advanced,
      emoji: '📊',
    ),
    WritingTask(
      id: 'advanced_26',
      task: 'Argue for or against platform-level censorship. Propose transparent moderation frameworks.',
      level: WritingLevel.advanced,
      emoji: '🚫',
    ),
    WritingTask(
      id: 'advanced_27',
      task: 'Critically analyze the environmental footprint of fast fashion and explore sustainable alternatives.',
      level: WritingLevel.advanced,
      emoji: '👗',
    ),
    WritingTask(
      id: 'advanced_28',
      task: 'Write a short story with an unreliable narrator and a non-linear timeline. Ensure thematic coherence.',
      level: WritingLevel.advanced,
      emoji: '🌀',
    ),
    WritingTask(
      id: 'advanced_29',
      task: 'Compose a debate speech defending an unpopular opinion. Anticipate and rebut strong counterarguments.',
      level: WritingLevel.advanced,
      emoji: '🎤',
    ),
    WritingTask(
      id: 'advanced_30',
      task: 'Analyze factors driving inflation and discuss possible central bank responses and their trade-offs.',
      level: WritingLevel.advanced,
      emoji: '📈',
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

  // Ek yardımcı metotlar
  int get totalTaskCount => _tasks.length;

  Map<WritingLevel, List<WritingTask>> get groupedByLevel => {
        for (final level in WritingLevel.values) level: getTasksByLevel(level),
      };

  List<WritingTask> search(String query, {WritingLevel? level}) {
    final q = query.trim().toLowerCase();
    Iterable<WritingTask> source = _tasks;
    if (level != null) {
      source = source.where((t) => t.level == level);
    }
    if (q.isEmpty) return source.toList();
    return source
        .where((t) => t.task.toLowerCase().contains(q) || t.id.toLowerCase().contains(q))
        .toList();
  }

  WritingTask? getRandomTask([WritingLevel? level]) {
    final list = level == null ? _tasks : _tasks.where((t) => t.level == level).toList();
    if (list.isEmpty) return null;
    final idx = math.Random().nextInt(list.length);
    return list[idx];
  }

  List<WritingTask> getTasksPage({WritingLevel? level, int page = 1, int pageSize = 10}) {
    assert(page >= 1 && pageSize >= 1);
    final list = level == null ? _tasks : _tasks.where((t) => t.level == level).toList();
    final start = (page - 1) * pageSize;
    if (start >= list.length) return const [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }
}
