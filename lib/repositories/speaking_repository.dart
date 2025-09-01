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
        title: 'Kahve Siparişi',
        mode: SpeakingMode.roleplay,
        context: 'Bir kafedesin. Barista ile kahve siparişi veriyorsun.',
        partnerLine: 'Hi there! What can I get you today?',
        targets: [
          "Hi! I'd like a medium latte, please.",
          "Can you make it with oat milk?",
          "That's all, thank you." ,
        ],
        tips: [
          'Nazik giriş (Hi / Hello) ile başla.',
          'İstek + miktar + tür: a medium latte',
          'Ekstra / tercih: with oat milk',
          'Kapanışta teşekkür et.'
        ],
      ),
      SpeakingPrompt(
        id: 's2',
        title: 'Gölge Okuma 1',
        mode: SpeakingMode.shadowing,
        context: 'Shadowing: Cümleyi dinle ve hemen arkasından aynı ritimde tekrar et.',
        targets: [
          'Learning a new language is a journey, not a race.',
          'Consistency beats intensity when building a habit.',
        ],
        tips: [
          'Önce dinle, sonra nefes almadan ritme yakın tekrar et.',
          'Vurgu ve ritme odaklan.'
        ],
      ),
      SpeakingPrompt(
        id: 's3',
        title: 'Hızlı Soru-Cevap',
        mode: SpeakingMode.qna,
        context: 'Sorulara hızlı cevaplar ver. 5 saniye düşünme süresi.',
        targets: [
          'What do you usually have for breakfast?',
          'How do you relax after a busy day?',
        ],
        tips: [
          'İlk aklına gelen doğal cevabı ver.',
          'Duraklamayı azalt, akıcılığı hedefle.'
        ],
      ),
      SpeakingPrompt(
        id: 's4',
        title: 'Tekrar Pratiği',
        mode: SpeakingMode.repeat,
        context: 'Cümleyi net ve temiz telaffuzla tekrar et.',
        targets: [
          'Practice makes progress.',
          'Small steps every day create big change.',
        ],
        tips: [
          'Açık ve anlaşılır sesle konuş.',
          'Net artikülasyon, acele yok.'
        ],
      ),
    ];
  }
}

