// lib/data/faq_data.dart

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

final Map<String, List<FaqItem>> faqData = {
  'Explore the App': [
    FaqItem(
      question: 'What is VocaChat?',
      answer: 'VocaChat is an AI-powered next-generation language learning platform. Practice with VocaBot AI assistant through natural conversations, receive real-time feedback, and improve yourself in 4 different skill areas (speaking, listening, reading, writing). Unlike traditional language learning apps, it offers an interactive and enjoyable experience.',
    ),
    FaqItem(
      question: 'What Does VocaBot Do?',
      answer: 'VocaBot is your personal AI language assistant supporting 100+ languages. It provides instant translation in your conversations, gently corrects grammar mistakes, suggests more natural and fluent expressions, offers suitable conversation topics, and personalizes your learning journey. You experience a natural and supportive environment as if talking to a real teacher. VocaBot access requires Premium membership.',
    ),
    FaqItem(
      question: 'What are Practice Modes?',
      answer: 'With VocaChat Premium, you can access 4 comprehensive practice modes:\n\n• Speaking: Conversation practice in real scenarios, pronunciation improvement, and fluency exercises\n• Listening: Listening exercises with different accents and speeds, comprehension tests\n• Reading: Texts according to your level, vocabulary learning, and reading speed improvement\n• Writing: Creative writing, grammar practice, and strengthening written expression skills\n\nEach mode includes content and interactive exercises tailored from beginner to advanced levels. Access to these modes requires Premium membership.',
    ),
    FaqItem(
      question: 'What is Vocabulary Treasure?',
      answer: 'Vocabulary Treasure is a word collection prepared for your language learning. You encounter randomly selected words, view their meanings, phonetic pronunciations, and example sentences. You can listen to each word, translate it to your native language, and expand your vocabulary by discovering new words. It is freely accessible.',
    ),
  ],
  'Account & Profile': [
    FaqItem(
      question: 'How Do I Update My Profile?',
      answer: 'Go to Profile section and click "Edit Profile" option. From there, you can change your avatar, update your username and birth date, and select your native language. Your profile information is linked to your account and visible on the leaderboard.',
    ),
    FaqItem(
      question: 'How Can I Change Language Settings?',
      answer: 'You can update your native language selection from Profile > Edit Profile section. Premium members can change target language and learning levels (beginner, intermediate, advanced) from the settings (⚙️) icon in the top right corner of VocaBot chat screen. VocaBot immediately starts speaking according to your new settings and offers content at the appropriate difficulty level.',
    ),
    FaqItem(
      question: 'Can I Change My Password?',
      answer: 'Yes, you can change your password anytime for your security. Follow Profile > Settings > Change Password path. If you want to change your email address, please contact us through the Help and Support section within the app or send an email to our support team.',
    ),
    FaqItem(
      question: 'What is the Streak System?',
      answer: 'The Streak system is a motivation feature for Premium users. You increase your streak by chatting and practicing with VocaBot every day. When you maintain long streaks, you rise on the leaderboard and your success becomes visible in the community. Earning streaks requires Premium membership and regular access to VocaBot.',
    ),
  ],
  'Premium & Billing': [
    FaqItem(
      question: 'What are Premium Benefits?',
      answer: 'VocaChat Premium offers you a complete language learning experience:\n\n• Completely ad-free experience - uninterrupted learning\n• VocaBot AI assistant - ability to speak and practice in 100+ languages\n• Instant translation - immediate translation during chat\n• Advanced grammar analysis - AI-powered detailed feedback\n• Full access to all practice modes - Speaking, Listening, Reading, Writing\n• Priority customer support - quick solutions to your problems\n\nIn the free version, you can access some sections like Vocabulary Treasure, grammar, and vocabulary.',
    ),
    FaqItem(
      question: 'How Do I Cancel My Subscription?',
      answer: 'You can manage and cancel your subscription through the platform where you purchased it (Google Play Store or Apple App Store). Even if you cancel, you will continue to benefit from Premium advantages until the end of your current billing period. After cancellation, automatic renewal stops and your subscription ends at the end of the period.',
    ),
    FaqItem(
      question: 'What\'s Available in the Free Version?',
      answer: 'In the free version, you can learn words from Vocabulary Treasure, use grammar and vocabulary tabs completely free. VocaBot AI assistant, practice modes (Speaking, Listening, Reading, Writing), advanced grammar analysis, and much more unlock with Premium membership. Upgrade to Premium for the full learning experience and remove ads.',
    ),
  ],
  'Features & Usage': [
    FaqItem(
      question: 'How Does VocaBot and Grammar Analysis Work?',
      answer: 'VocaBot\'s AI-powered grammar analysis feature examines every message you write in real-time. It detects grammar errors, suggests more accurate expressions, and helps you make your sentences more natural. While chatting with VocaBot, you can make instant translations, learn natural expressions, and personalize your learning process. These features require Premium membership.',
    ),
    FaqItem(
      question: 'How to Use Vocabulary Treasure?',
      answer: 'Vocabulary Treasure is a freely accessible feature. You encounter random words, listen to their phonetic pronunciations, and see their usage in example sentences. You can translate each word to its equivalent in your native language and expand your vocabulary. You can access the entire word collection without Premium.',
    ),
    FaqItem(
      question: 'How Does the Leaderboard Work?',
      answer: 'The leaderboard shows the most active learners in the community. Premium members earn points by the time they spend with VocaBot. The highest-scoring users appear at the top of the leaderboard. You can see your position on the leaderboard and compare with other learners.',
    ),
    FaqItem(
      question: 'Can I Use It Offline?',
      answer: 'Most features of VocaChat (AI assistant, real-time translation, grammar analysis, synchronization) require an internet connection. However, you can remember the words you saw from Vocabulary Treasure offline and take notes. Internet connection is recommended for full functionality.',
    ),
  ],
  'Support & Help': [
    FaqItem(
      question: 'How to Report Technical Issues?',
      answer: 'If you experience any technical issues, go to Profile > Help and Support section and click "Create Support Request" option. Explain your problem in detail, attach a screenshot if possible. Our support team typically responds within 24 hours. Premium users receive priority support.',
    ),
    FaqItem(
      question: 'Which Languages Does It Support?',
      answer: 'VocaChat supports 100+ languages! Popular languages include: English, Turkish, Spanish, French, German, Italian, Portuguese, Russian, Japanese, Korean, Chinese (Mandarin and Cantonese), Arabic, Hindi, Persian, Swedish, Norwegian, Danish, Dutch, Polish, Ukrainian, and many more. We continuously add new language support.',
    ),
    FaqItem(
      question: 'Is My Data Safe?',
      answer: 'Yes, your data security is our priority. All your data is stored on Firebase\'s secure cloud infrastructure, protected with industry-standard encryption protocols, and never shared with third parties. We fully comply with GDPR and other data protection laws. Visit the settings section for more information about our privacy policy.',
    ),
  ],
};

