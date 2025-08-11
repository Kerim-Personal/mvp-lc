// lib/screens/help_and_support_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// SSS için veri modeli
class FaqItem {
  final String question;
  final String answer;

  // HATA ÇÖZÜMÜ 1: Bu sınıfın nesnelerinin bir 'const' liste içinde kullanılabilmesi
  // için yapıcısını (constructor) 'const' olarak işaretliyoruz.
  const FaqItem({required this.question, required this.answer});
}

class HelpAndSupportScreen extends StatelessWidget {
  // HATA ÇÖZÜMÜ 2: 'faqItems' listesi bu sınıf içinde anında (instance-level)
  // tanımlandığı için, widget'ın kendi yapıcısı 'const' olamaz. Bu yüzden siliyoruz.
  HelpAndSupportScreen({super.key});

  // Sıkça sorulan soruların listesi
  final List<FaqItem> faqItems = const [
    FaqItem(
      question: 'LinguaChat nedir ve nasıl çalışır?',
      answer:
      'LinguaChat, dil pratiği yapmak isteyen kullanıcıları rastgele eşleştirerek onlara canlı sohbet imkanı sunan bir mobil uygulamadır. Ana ekrandaki "Partner Bul" butonuna tıklayarak anında yeni biriyle konuşmaya başlayabilirsiniz.',
    ),
    FaqItem(
      question: 'Uygulamayı kullanmak ücretli mi?',
      answer:
      'Uygulamanın temel özellikleri tamamen ücretsizdir. Ancak, cinsiyete göre filtreleme, reklamsız deneyim ve LinguaBot Pro gibi ek özelliklere erişmek için Lingua Pro aboneliği satın alabilirsiniz.',
    ),
    FaqItem(
      question: 'Partner ararken neden kimseyi bulamıyorum?',
      answer:
      'Eşleşmeler, o an partner arayan aktif kullanıcılar arasından yapılır. Eğer arama çok uzun sürüyorsa, bu durum o anki aktif kullanıcı sayısının az olmasından kaynaklanıyor olabilir. Lütfen daha sonra tekrar deneyin veya LinguaBot ile pratik yapın.',
    ),
    FaqItem(
      question: 'Dil seviyemi nasıl belirleyebilirim veya değiştirebilirim?',
      answer:
      'Uygulamaya ilk girişte seviye belirleme testi yapabilirsiniz. Seviyenizi daha sonra "Keşfet" bölümündeki "Seviyeni Keşfet" kartına tıklayarak yeniden değerlendirebilirsiniz.',
    ),
    FaqItem(
      question: 'Sohbet sırasında rahatsız edici bir durumla karşılaştım, ne yapmalıyım?',
      answer:
      'Topluluk kurallarını ihlal eden bir kullanıcıyla karşılaşırsanız, sohbet ekranının sağ üst köşesindeki menüden "Kullanıcıyı Bildir" seçeneğini kullanarak durumu bize bildirebilirsiniz. Ekibimiz gerekli incelemeyi yapacaktır.',
    ),
    FaqItem(
      question: 'Pratik sürem ve serim nasıl hesaplanıyor?',
      answer:
      'Yaptığınız her sohbetin süresi "Toplam Süre" istatistiğinize eklenir. Birbirini takip eden günlerde en az bir kez pratik yaparsanız "Seri" sayınız artar. Eğer bir gün pratik yapmazsanız seri bozulur.',
    ),
    FaqItem(
      question: 'LinguaBot nedir?',
      answer:
      'LinguaBot, partner beklemek istemediğiniz zamanlarda pratik yapabileceğiniz yapay zeka tabanlı sohbet arkadaşımızdır. Dil becerilerinizi test eder ve size anında geri bildirimler sunar.',
    ),
    FaqItem(
      question: 'Hesap bilgilerimi (kullanıcı adı, şifre vb.) nasıl güncelleyebilirim?',
      answer:
      'Profil sayfanızdaki "Hesap Yönetimi" bölümünden "Profili Düzenle" seçeneğine tıklayarak kullanıcı adı, avatar gibi bilgilerinizi güncelleyebilirsiniz. Şifre değişikliği gibi güvenlik işlemleri için şimdilik destek ekibimizle iletişime geçmeniz gerekmektedir.',
    ),
  ];

  // E-posta gönderme fonksiyonu
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@linguachat.com', // Destek e-posta adresiniz
      queryParameters: {'subject': 'LinguaChat Destek Talebi'},
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      // HATA ÇÖZÜMÜ 3: Asenkron işlemden (`await`) sonra `context` kullanmadan önce,
      // widget'ın hala ekranda olduğundan emin olmak için 'mounted' kontrolü ekliyoruz.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'E-posta uygulaması açılamadı. Lütfen manuel olarak support@linguachat.com adresine mail atın.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım & Destek'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Sıkça Sorulan Sorular',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...faqItems.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(item.question,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(item.answer,
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade700)),
                )
              ],
            ),
          )),
          const Divider(height: 40),
          const Text(
            'Aradığınızı bulamadınız mı?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Destek ekibimizle iletişime geçmekten çekinmeyin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _launchEmail(context),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Bize E-posta Gönderin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}