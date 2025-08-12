// lib/screens/help_and_support_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// SSS için veri modeli
class FaqItem {
  final String question;
  final String answer;
  final IconData icon;

  const FaqItem({required this.question, required this.answer, required this.icon});
}

// --- VERİ ---
// Veriyi widget'tan ayırarak daha temiz bir yapı sağlıyoruz.
const List<FaqItem> _faqItems = [
  FaqItem(
    question: 'LinguaChat nedir ve nasıl çalışır?',
    answer:
    'LinguaChat, dil pratiği yapmak isteyen kullanıcıları rastgele eşleştirerek onlara canlı sohbet imkanı sunan bir mobil uygulamadır. Ana ekrandaki "Partner Bul" butonuna tıklayarak anında yeni biriyle konuşmaya başlayabilirsiniz.',
    icon: Icons.help_outline_rounded,
  ),
  FaqItem(
    question: 'Uygulamayı kullanmak ücretli mi?',
    answer:
    'Uygulamanın temel özellikleri tamamen ücretsizdir. Ancak, cinsiyete göre filtreleme, reklamsız deneyim ve LinguaBot Pro gibi ek özelliklere erişmek için Lingua Pro aboneliği satın alabilirsiniz.',
    icon: Icons.price_change_outlined,
  ),
  FaqItem(
    question: 'Şifremi unuttum, ne yapmalıyım?',
    answer:
    'Giriş ekranında bulunan "Şifremi Unuttum" bağlantısına tıklayarak e-posta adresinize bir sıfırlama linki gönderebilirsiniz. Gelen e-postadaki adımları takip ederek yeni bir şifre belirleyebilirsiniz.',
    icon: Icons.lock_reset_rounded,
  ),
  FaqItem(
    question: 'Partner ararken neden kimseyi bulamıyorum?',
    answer:
    'Eşleşmeler, o an partner arayan aktif kullanıcılar arasından yapılır. Eğer arama çok uzun sürüyorsa, bu durum o anki aktif kullanıcı sayısının az olmasından kaynaklanıyor olabilir. Lütfen daha sonra tekrar deneyin veya LinguaBot ile pratik yapın.',
    icon: Icons.person_search_outlined,
  ),
  FaqItem(
    question: 'Dil seviyemi nasıl belirleyebilirim veya değiştirebilirim?',
    answer:
    'Uygulamaya ilk girişte seviye belirleme testi yapabilirsiniz. Seviyenizi daha sonra "Keşfet" bölümündeki "Seviyeni Keşfet" kartına tıklayarak yeniden değerlendirebilirsiniz.',
    icon: Icons.bar_chart_rounded,
  ),
  FaqItem(
    question: 'Sohbet sırasında rahatsız edici bir durumla karşılaştım, ne yapmalıyım?',
    answer:
    'Topluluk kurallarını ihlal eden bir kullanıcıyla karşılaşırsanız, sohbet ekranının sağ üst köşesindeki menüden "Kullanıcıyı Bildir" seçeneğini kullanarak durumu bize bildirebilirsiniz. Ekibimiz gerekli incelemeyi yapacaktır.',
    icon: Icons.report_problem_outlined,
  ),
  FaqItem(
    question: 'Pratik sürem ve serim nasıl hesaplanıyor?',
    answer:
    'Yaptığınız her sohbetin süresi "Toplam Süre" istatistiğinize eklenir. Birbirini takip eden günlerde en az bir kez pratik yaparsanız "Seri" sayınız artar. Eğer bir gün pratik yapmazsanız seri bozulur.',
    icon: Icons.timer_outlined,
  ),
  FaqItem(
    question: 'Hesap bilgilerimi nasıl güncelleyebilirim?',
    answer:
    'Profil sayfanızdaki "Hesap Yönetimi" bölümünden "Profili Düzenle" seçeneğine tıklayarak kullanıcı adı, avatar gibi bilgilerinizi güncelleyebilirsiniz. E-posta veya şifre değişikliği gibi güvenlik işlemleri için destek ekibimizle iletişime geçmeniz gerekebilir.',
    icon: Icons.manage_accounts_outlined,
  ),
  FaqItem(
    question: 'Hesabımı nasıl silebilirim?',
    answer:
    'Profil sayfanızdaki "Hesap Yönetimi" bölümünde bulunan "Hesabı Sil" seçeneğini kullanarak hesabınızı kalıcı olarak silebilirsiniz. Bu işlemin geri alınamayacağını lütfen unutmayın.',
    icon: Icons.delete_forever_outlined,
  ),
  FaqItem(
    question: 'Verilerim güvende mi?',
    answer:
    'Evet, kullanıcı güvenliği ve veri gizliliği bizim için en önemli önceliktir. Tüm verileriniz modern şifreleme standartları ile korunmaktadır. Detaylı bilgi için Gizlilik Politikamızı inceleyebilirsiniz.',
    icon: Icons.privacy_tip_outlined,
  ),
];


// --- ANA WIDGET ---
class HelpAndSupportScreen extends StatelessWidget {
  HelpAndSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@linguachat.com',
      queryParameters: {'subject': 'LinguaChat Destek Talebi'},
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Yardım & Destek'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Başlık Bölümü
          _buildHeader(),
          const SizedBox(height: 24),

          // SSS Listesi
          ..._faqItems.map((item) => _FaqItemCard(item: item)),

          const SizedBox(height: 16),
          // Bize Ulaşın Kartı
          _ContactSupportCard(onTap: () => _launchEmail(context)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade300, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent_rounded, size: 40, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Size nasıl yardımcı olabiliriz?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Sorunuzun cevabını aşağıda bulabilir veya bizimle iletişime geçebilirsiniz.',
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// --- YARDIMCI WIDGET'LAR ---

// SSS Kartı
class _FaqItemCard extends StatelessWidget {
  final FaqItem item;
  const _FaqItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(item.icon, color: Colors.teal),
        title: Text(item.question,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(item.answer,
              style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

// Bize Ulaşın Kartı
class _ContactSupportCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ContactSupportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.email_outlined, size: 32, color: Colors.teal),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Bize E-posta Gönderin'),
            ),
          ],
        ),
      ),
    );
  }
}