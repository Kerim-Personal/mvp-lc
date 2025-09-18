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
      answer:
      'VocaChat is an AI‑powered language practice platform. It matches you with fluent or native speakers and provides real‑time AI assistance so you can improve in realistic contexts.',
    ),
    FaqItem(
      question: 'What does VocaBot do?',
      answer:
      'VocaBot is your contextual AI assistant. It can translate instantly, highlight grammar issues, suggest better wording, propose topics, and help you stay confident while chatting.',
    ),
    FaqItem(
      question: 'How does the Vocabulary feature work?',
      answer:
      'Any new word you see (or VocaBot suggests) can be saved to your personal list with one tap. You can later review, practice, and reinforce them for long‑term retention.',
    ),
  ],
  'Account & Profile': [
    FaqItem(
      question: 'How do I update my profile info?',
      answer:
      'Go to Profile > Edit Profile. There you can change your avatar, username, interests, and bio. Keeping it fresh improves match quality.',
    ),
    FaqItem(
      question: 'Can I change my email or password?',
      answer:
      'Yes. Open Profile > Settings > Account to update your email (with verification) or set a new password.',
    ),
    FaqItem(
      question: 'Can I temporarily deactivate my account?',
      answer:
      'Temporary deactivation is not supported yet. You can mute notifications if you need a break. To permanently delete your account, use the option under Account settings.',
    ),
    FaqItem(
      question: 'What happens if I delete my account?',
      answer:
      'All data (profile, chat history, vocabulary) is permanently removed and cannot be restored afterward.',
    ),
  ],
  'Security & Privacy': [
    FaqItem(
      question: 'How do I block a user?',
      answer:
      'Open their profile or use the menu in the chat header and tap Block. Blocked users cannot message you or view your profile.',
    ),
    FaqItem(
      question: 'How do I report inappropriate behavior?',
      answer:
      'Use the Report option in the profile or chat menu. Our trust & safety team reviews reports carefully and takes appropriate action.',
    ),
    FaqItem(
      question: 'Is my location shared?',
      answer:
      'No. We respect your privacy and never share your location with other users.',
    ),
    FaqItem(
      question: 'Are my chats secure?',
      answer:
      'We safeguard your conversations using industry standard security controls. We do not access or review chats arbitrarily. Two exceptions apply: (1) Valid legal requests from competent authorities. (2) Confirmed user reports of serious policy violations (e.g. harassment, hate). Outside of these cases, chat content remains private.',
    ),
  ],
  'Premium & Billing': [
    FaqItem(
      question: 'What are the benefits of Premium?',
      answer:
      'Premium unlocks unlimited partner chats, ad‑free experience, enhanced VocaBot features (e.g. voice analysis), exclusive vocabulary packs, and priority in community events.',
    ),
    FaqItem(
      question: 'How do I cancel my subscription?',
      answer:
      'Manage it through the platform you purchased on (Google Play or App Store). Your benefits remain active until the current billing period ends.',
    ),
    FaqItem(
      question: 'How do I change my payment method?',
      answer:
      'Payment methods are managed directly via your App Store or Google Play account settings.',
    ),
    FaqItem(
      question: 'Do you offer a free trial?',
      answer:
      'We occasionally run launch promos or free trials. Check the Store screen and notifications for current offers.',
    ),
  ],
};