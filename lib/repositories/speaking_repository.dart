// lib/repositories/speaking_repository.dart
import 'package:vocachat/models/speaking_models.dart';

class SpeakingRepository {
  SpeakingRepository._();
  static final SpeakingRepository instance = SpeakingRepository._();

  final List<SpeakingPrompt> _prompts = _seed();

  List<SpeakingPrompt> all() => List.unmodifiable(_prompts);
  SpeakingPrompt? byId(String id) => _prompts.firstWhere((e) => e.id == id, orElse: () => _prompts.first);

  static List<SpeakingPrompt> _seed() {
    return const [
      // ============ BEGINNER LEVEL ============
      SpeakingPrompt(
        id: 's1',
        title: 'Introducing Yourself',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.beginner,
        context: 'Practice basic self-introduction sentences.',
        targets: [
          "Hello, my name is Alex .",
          "I am from America.",
          "Nice to meet you.",
        ],
        tips: [
          'Speak slowly and clearly.',
          'Focus on correct pronunciation.',
        ],
      ),
      SpeakingPrompt(
        id: 's2',
        title: 'Daily Greetings',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.beginner,
        context: 'Learn common greeting phrases.',
        targets: [
          "Good morning!",
          "How are you today?",
          "I'm fine, thank you.",
        ],
        tips: [
          'Use a friendly tone.',
          'Practice the rhythm of questions.',
        ],
      ),
      SpeakingPrompt(
        id: 's3',
        title: 'Ordering Coffee',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.beginner,
        context: 'You are in a cafe. Order a drink from the barista.',
        partnerLine: 'Hi there! What can I get you today?',
        targets: [
          "Hi! I'd like a medium latte, please.",
          "Can you make it without milk?",
          "That's all, thank you.",
        ],
        tips: [
          'Start with a polite greeting.',
          'State your request clearly.',
          'Always say thank you.',
        ],
      ),
      SpeakingPrompt(
        id: 's4',
        title: 'Simple Questions',
        mode: SpeakingMode.qna,
        level: SpeakingLevel.beginner,
        context: 'Answer simple everyday questions.',
        targets: [
          "What is your favorite color?",
          "Do you like coffee or tea?",
          "What time do you wake up?",
        ],
        tips: [
          'Give short, simple answers.',
          'Don\'t worry about mistakes.',
        ],
      ),
      SpeakingPrompt(
        id: 's5',
        title: 'Numbers and Time',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.beginner,
        context: 'Practice saying numbers and telling time.',
        targets: [
          "It is ten thirty in the morning.",
          "My phone number is five five five, one two three four.",
          "I have two brothers and one sister.",
        ],
        tips: [
          'Pause between numbers for clarity.',
          'Practice time expressions.',
        ],
      ),
      SpeakingPrompt(
        id: 's6',
        title: 'Shopping Basics',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.beginner,
        context: 'You are shopping for clothes.',
        partnerLine: 'Can I help you find something?',
        targets: [
          "Yes, I'm looking for a blue shirt.",
          "Do you have it in medium size?",
          "How much does it cost?",
        ],
        tips: [
          'Use polite language.',
          'Ask clear questions.',
        ],
      ),
      SpeakingPrompt(
        id: 's7',
        title: 'Family and Friends',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.beginner,
        context: 'Talk about your family and friends.',
        targets: [
          "I have a small family.",
          "My best friend lives in Istanbul.",
          "We like to watch movies together.",
        ],
        tips: [
          'Use simple present tense.',
          'Connect your ideas clearly.',
        ],
      ),
      SpeakingPrompt(
        id: 's8',
        title: 'Food Preferences',
        mode: SpeakingMode.qna,
        level: SpeakingLevel.beginner,
        context: 'Talk about what you like to eat.',
        targets: [
          "What do you usually have for breakfast?",
          "Do you like spicy food?",
          "What is your favorite restaurant?",
        ],
        tips: [
          'Use "I like" and "I don\'t like".',
          'Be specific in your answers.',
        ],
      ),

      // ============ INTERMEDIATE LEVEL ============
      SpeakingPrompt(
        id: 's9',
        title: 'Making Plans',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.intermediate,
        context: 'You are making weekend plans with a friend.',
        partnerLine: 'Hey! Do you want to do something this weekend?',
        targets: [
          "Sure! How about going to the cinema on Saturday?",
          "We could watch that new movie everyone's talking about.",
          "Let's meet at the mall around seven.",
        ],
        tips: [
          'Use future tense and suggestions.',
          'Practice conversational phrases.',
        ],
      ),
      SpeakingPrompt(
        id: 's10',
        title: 'Travel Experience',
        mode: SpeakingMode.qna,
        level: SpeakingLevel.intermediate,
        context: 'Talk about your travel experiences.',
        targets: [
          "Have you ever been to another country?",
          "What was the most interesting place you visited?",
          "Would you like to travel more in the future?",
        ],
        tips: [
          'Use past tense correctly.',
          'Give detailed answers.',
        ],
      ),
      SpeakingPrompt(
        id: 's11',
        title: 'Shadowing Practice',
        mode: SpeakingMode.shadowing,
        level: SpeakingLevel.intermediate,
        context: 'Listen and repeat with natural rhythm and intonation.',
        targets: [
          'Learning a new language is a journey, not a race.',
          'Consistency beats intensity when building a habit.',
          'The more you practice, the more confident you become.',
        ],
        tips: [
          'Match the speaker\'s rhythm exactly.',
          'Focus on stress and intonation patterns.',
        ],
      ),
      SpeakingPrompt(
        id: 's12',
        title: 'Job Interview',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.intermediate,
        context: 'You are in a job interview.',
        partnerLine: 'Tell me about yourself and why you want this position.',
        targets: [
          "I have three years of experience in customer service.",
          "I'm very interested in this position because I love helping people.",
          "I believe my skills would be a great fit for your team.",
        ],
        tips: [
          'Be confident and clear.',
          'Use professional language.',
        ],
      ),
      SpeakingPrompt(
        id: 's13',
        title: 'Describing Situations',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.intermediate,
        context: 'Practice describing different situations.',
        targets: [
          "The weather was beautiful yesterday, so we went to the beach.",
          "If I had more time, I would learn to play the guitar.",
          "She has been studying English for two years now.",
        ],
        tips: [
          'Use different tenses correctly.',
          'Connect ideas smoothly.',
        ],
      ),
      SpeakingPrompt(
        id: 's14',
        title: 'Giving Opinions',
        mode: SpeakingMode.qna,
        level: SpeakingLevel.intermediate,
        context: 'Express your opinions on different topics.',
        targets: [
          "What do you think about social media?",
          "How do you feel about working from home?",
          "Do you agree that reading books is better than watching TV?",
        ],
        tips: [
          'Use opinion phrases: I think, I believe, In my opinion.',
          'Give reasons for your opinions.',
        ],
      ),
      SpeakingPrompt(
        id: 's15',
        title: 'Problem Solving',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.intermediate,
        context: 'You have a problem at a hotel reception.',
        partnerLine: 'How can I help you today?',
        targets: [
          "I'm afraid there's a problem with my room.",
          "The air conditioning isn't working properly.",
          "Could you please send someone to fix it?",
        ],
        tips: [
          'Be polite but clear about the problem.',
          'Use modal verbs: could, would.',
        ],
      ),
      SpeakingPrompt(
        id: 's16',
        title: 'Hobbies and Interests',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.intermediate,
        context: 'Talk about your hobbies in detail.',
        targets: [
          "I've been playing tennis for about five years now.",
          "Photography has always been a passion of mine.",
          "I try to practice at least three times a week.",
        ],
        tips: [
          'Use present perfect tense.',
          'Show enthusiasm in your voice.',
        ],
      ),

      // ============ ADVANCED LEVEL ============
      SpeakingPrompt(
        id: 's17',
        title: 'Complex Debate',
        mode: SpeakingMode.qna,
        level: SpeakingLevel.advanced,
        context: 'Discuss complex topics with nuanced opinions.',
        targets: [
          "What are your thoughts on artificial intelligence and its impact on employment?",
          "How should governments balance economic growth with environmental protection?",
          "Do you think technology makes us more or less connected to each other?",
        ],
        tips: [
          'Present multiple perspectives.',
          'Use advanced vocabulary and complex sentences.',
        ],
      ),
      SpeakingPrompt(
        id: 's18',
        title: 'Formal Presentation',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.advanced,
        context: 'Practice delivering formal presentations.',
        targets: [
          "Today I'd like to present our findings on consumer behavior patterns.",
          "The data suggests a significant shift towards sustainable products.",
          "In conclusion, we recommend implementing these strategies in the next quarter.",
        ],
        tips: [
          'Use formal language and clear structure.',
          'Maintain professional tone throughout.',
        ],
      ),
      SpeakingPrompt(
        id: 's19',
        title: 'Negotiation Skills',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.advanced,
        context: 'You are negotiating a business deal.',
        partnerLine: 'We can offer you a 10% discount on bulk orders.',
        targets: [
          "I appreciate the offer, but given the volume we're discussing, I was hoping for something closer to 15%.",
          "Perhaps we could meet in the middle if you could also include free shipping.",
          "That sounds reasonable. Let's finalize the terms and move forward.",
        ],
        tips: [
          'Use diplomatic language.',
          'Balance firmness with flexibility.',
        ],
      ),
      SpeakingPrompt(
        id: 's20',
        title: 'Storytelling',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.advanced,
        context: 'Tell a complex story with details.',
        targets: [
          "It was a typical Tuesday morning when everything changed unexpectedly.",
          "Looking back, I realize that decision shaped the course of my entire career.",
          "The experience taught me that sometimes the greatest opportunities come from unexpected challenges.",
        ],
        tips: [
          'Use varied sentence structures.',
          'Create vivid imagery with your words.',
        ],
      ),
      SpeakingPrompt(
        id: 's21',
        title: 'Advanced Shadowing',
        mode: SpeakingMode.shadowing,
        level: SpeakingLevel.advanced,
        context: 'Shadow complex sentences with perfect intonation.',
        targets: [
          "Despite numerous setbacks and challenges, she persevered and ultimately achieved her goals.",
          "The implications of this research extend far beyond what we initially anticipated.",
          "Had we known about these circumstances earlier, we could have taken preventive measures.",
        ],
        tips: [
          'Match every subtle intonation change.',
          'Maintain the speaker\'s pace precisely.',
        ],
      ),
      SpeakingPrompt(
        id: 's22',
        title: 'Critical Analysis',
        mode: SpeakingMode.qna,
        level: SpeakingLevel.advanced,
        context: 'Analyze and critique complex ideas.',
        targets: [
          "How would you evaluate the effectiveness of current education systems?",
          "What are the potential consequences of global economic integration?",
          "Can you analyze the relationship between culture and identity?",
        ],
        tips: [
          'Provide in-depth analysis.',
          'Support arguments with examples.',
        ],
      ),
      SpeakingPrompt(
        id: 's23',
        title: 'Professional Conflict Resolution',
        mode: SpeakingMode.roleplay,
        level: SpeakingLevel.advanced,
        context: 'Handle a difficult conversation with a colleague.',
        partnerLine: 'I don\'t understand why my proposal was rejected without discussion.',
        targets: [
          "I understand your frustration, and I want to address your concerns thoroughly.",
          "While I see the merits of your proposal, there were some practical constraints we needed to consider.",
          "Let's schedule a meeting to review this together and find a solution that works for everyone.",
        ],
        tips: [
          'Show empathy while being professional.',
          'Use tactful language to resolve conflicts.',
        ],
      ),
      SpeakingPrompt(
        id: 's24',
        title: 'Abstract Concepts',
        mode: SpeakingMode.repeat,
        level: SpeakingLevel.advanced,
        context: 'Discuss abstract and philosophical ideas.',
        targets: [
          "The nature of consciousness remains one of philosophy's most enduring mysteries.",
          "Cultural relativism suggests that moral principles vary across different societies.",
          "The intersection of ethics and technology raises profound questions about our future.",
        ],
        tips: [
          'Use sophisticated vocabulary.',
          'Express complex ideas clearly.',
        ],
      ),
    ];
  }
}
