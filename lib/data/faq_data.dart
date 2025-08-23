// lib/data/faq_data.dart

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

final Map<String, List<FaqItem>> faqData = {
  'Uygulamayı Keşfet': [
    FaqItem(
      question: 'LinguaChat tam olarak nedir?',
      answer:
      'LinguaChat, yapay zeka destekli bir dil öğrenme platformudur. Amacı, sizi ana dili İngilizce olan veya akıcı konuşan kişilerle eşleştirerek pratik yapmanızı sağlamak ve dil becerilerinizi gerçek dünya senaryolarında geliştirmektir.',
    ),
    FaqItem(
      question: 'Pratik partnerleri nasıl seçiliyor?',
      answer:
      'Partner eşleştirme algoritmamız; dil seviyenizi, belirttiğiniz ilgi alanlarını ve öğrenme hedeflerinizi analiz eder. Bu sayede, hem keyifli sohbet edebileceğiniz hem de verimli pratik yapabileceğiniz en uygun kişileri karşınıza çıkarır.',
    ),
    FaqItem(
      question: 'LinguaBot ne işe yarar?',
      answer:
      'LinguaBot, kişisel yapay zeka asistanınızdır. Sohbet esnasında anlık çeviri yapabilir, gramer hatalarınızı düzeltebilir, daha uygun kelime önerilerinde bulunabilir ve hatta sohbet konusu bulmanıza yardımcı olabilir.',
    ),
    FaqItem(
      question: 'Kelime Hazinesi nasıl kullanılır?',
      answer:
      'Sohbet sırasında karşılaştığınız veya LinguaBot\'un önerdiği yeni kelimeleri tek dokunuşla kişisel "Kelime Hazinesi"ne ekleyebilirsiniz. Bu özellik, öğrendiğiniz kelimeleri daha sonra tekrar etmeniz ve kalıcı hale getirmeniz için tasarlanmıştır.',
    ),
  ],
  'Hesap ve Profil': [
    FaqItem(
      question: 'Profil bilgilerimi nasıl güncelleyebilirim?',
      answer:
      'Profil sekmesine gidin ve "Profili Düzenle" butonuna dokunun. Bu bölümden profil resminizi (avatar), kullanıcı adınızı, ilgi alanlarınızı ve hakkınızda kısa bir açıklama ekleyebilirsiniz. Profilinizi güncel tutmak, daha iyi partner eşleşmeleri bulmanıza yardımcı olur.',
    ),
    FaqItem(
      question: 'E-posta adresimi veya şifremi değiştirebilir miyim?',
      answer:
      'Evet. "Profil > Ayarlar > Hesap" menüsü altından hem e-posta adresinizi doğrulama adımlarıyla güncelleyebilir hem de mevcut şifrenizi değiştirerek yeni bir şifre belirleyebilirsiniz.',
    ),
    FaqItem(
      question: 'Hesabımı geçici olarak dondurabilir miyim?',
      answer:
      'Şu an için hesabı geçici olarak dondurma özelliği bulunmamaktadır. Ancak bildirim ayarlarını kapatarak uygulamadan bir süreliğine uzaklaşabilirsiniz. Hesabınızı kalıcı olarak silmek isterseniz, bu işlemi "Hesap" ayarları altından yapabilirsiniz.',
    ),
    FaqItem(
      question: 'Hesabımı silersem verilerime ne olur?',
      answer:
      'Hesabınızı sildiğinizde, profil bilgileriniz, sohbet geçmişiniz ve kelime hazineniz dahil olmak üzere tüm verileriniz kalıcı olarak sistemimizden kaldırılır. Bu işlem geri alınamaz.',
    ),
  ],
  'Güvenlik ve Gizlilik': [
    FaqItem(
      question: 'Bir kullanıcıyı nasıl engellerim?',
      answer:
      'Eğer bir kullanıcı sizi rahatsız ederse, o kullanıcının profiline giderek veya sohbet penceresinin sağ üst köşesindeki menüden "Engelle" seçeneğini kullanabilirsiniz. Engellenen kullanıcılar size mesaj gönderemez ve profilinizi göremez.',
    ),
    FaqItem(
      question: 'Uygunsuz davranışları nasıl şikayet edebilirim?',
      answer:
      'Kullanıcı profilindeki veya sohbet menüsündeki "Şikayet Et" seçeneğini kullanarak uygunsuz davranışları, tacizi veya topluluk kuralları ihlallerini bize bildirebilirsiniz. Destek ekibimiz şikayetleri titizlikle inceler ve gerekli aksiyonları alır.',
    ),
    FaqItem(
      question: 'Konum bilgilerim paylaşılıyor mu?',
      answer:
      'Hayır. LinguaChat, gizliliğinize saygı duyar ve konum bilginizi hiçbir şekilde diğer kullanıcılarla paylaşmaz.',
    ),
    FaqItem(
      // GÜNCELLENMİŞ CEVAP
      question: 'Sohbetlerim ne kadar güvenli?',
      answer:
      'Kullanıcı gizliliği ve veri güvenliği en önemli önceliklerimizdendir. Sohbetleriniz, sunucularımızda güvenli bir şekilde saklanır ve standart güvenlik protokolleri ile korunur. Gizliliğinize saygı duyuyoruz; bu nedenle, sohbet içeriklerinize keyfi olarak erişim sağlamayız veya incelemeyiz. Ancak, platformumuzun güvenliğini ve topluluk kurallarını korumak amacıyla iki istisnai durumda sohbet içeriklerine erişim sağlanabilir:\n\n'
          '1.  **Yasal Talepler:** Türkiye Cumhuriyeti yetkili adli makamları tarafından usulüne uygun olarak bir veri talebinde bulunulması halinde, yasal yükümlülüklerimiz gereği ilgili verileri paylaşabiliriz.\n'
          '2.  **Kullanıcı Şikayetleri:** Bir kullanıcının, topluluk kurallarımızı (örneğin taciz, nefret söylemi) ihlal ettiği yönünde şikayet edilmesi durumunda, şikayeti araştırmak ve doğrulamak amacıyla ilgili sohbet kayıtları incelenebilir.\n\n'
          'Bu durumlar dışında sohbetlerinize erişilmez. Amacımız, herkes için saygılı ve güvenli bir dil öğrenme ortamı sağlamaktır.',
    ),
  ],
  'Premium Üyelik ve Ödemeler': [
    FaqItem(
      question: 'Premium üyeliğin ne gibi avantajları var?',
      answer:
      'Premium üyeler; sınırsız sayıda partnerle sohbet etme, reklamsız bir deneyim, gelişmiş LinguaBot özellikleri (örneğin sesli analiz), özel kelime listelerine erişim ve topluluk etkinliklerinde öncelik gibi birçok ayrıcalığa sahip olur.',
    ),
    FaqItem(
      question: 'Aboneliğimi nasıl iptal edebilirim?',
      answer:
      'Aboneliğinizi, satın alımı yaptığınız platformun (Google Play Store veya Apple App Store) ilgili abonelik yönetimi bölümünden kolayca iptal edebilirsiniz. Aboneliğiniz, mevcut fatura döneminin sonuna kadar devam edecektir.',
    ),
    FaqItem(
      question: 'Ödeme yöntemimi nasıl değiştirebilirim?',
      answer:
      'Ödeme bilgileriniz doğrudan App Store veya Google Play hesabınız üzerinden yönetilir. Ödeme yönteminizi değiştirmek için lütfen ilgili uygulama mağazasının ayarlarını ziyaret edin.',
    ),
    FaqItem(
      question: 'Ücretsiz deneme süresi sunuyor musunuz?',
      answer:
      'Zaman zaman yeni kullanıcılar için özel promosyonlar ve ücretsiz deneme süreleri sunabiliyoruz. Güncel kampanyalar için lütfen Mağaza ekranını ve bildirimlerinizi kontrol edin.',
    ),
  ],
};