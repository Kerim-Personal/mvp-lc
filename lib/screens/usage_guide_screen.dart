// lib/screens/usage_guide_screen.dart
import 'package:flutter/material.dart';

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verimli Kullanım Rehberi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Başlarken',
            icon: Icons.rocket_launch_outlined,
            color: cs.primary,
            items: const [
              'Profilini tamamla: ana dil ve hedef dil bilgilerini güncelle.',
              'Günlük mini hedef belirle (ör. 10 dk).',
              'Uygulama bildirimlerini açık tut ki ritmini koruyabilesin.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'VocaBot ile verimli pratik',
            icon: Icons.smart_toy_outlined,
            color: Colors.teal,
            items: const [
              'Kısa ve net mesajlar yaz; 1 fikir = 1 mesaj.',
              'Botun sorularına tam cümlelerle cevap ver.',
              '“Please evaluate my grammar briefly.” gibi hazır önerileri kullan.',
              'Zorlandığında “How would a native say that?” de ve alternatif iste.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Dil analizi ve geri bildirim',
            icon: Icons.analytics_outlined,
            color: Colors.orange,
            items: const [
              'Mesaj üzerinde uzun basarak kopyala/TTS/analiz seçeneklerini gör.',
              'Kısa dönüt iste: “Correct only the essentials please.”',
              'Yeni kelimeleri aynı gün 3 farklı cümlede tekrar et.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Çeviri ve telaffuz',
            icon: Icons.translate_outlined,
            color: Colors.indigo,
            items: const [
              'Anadilini ayarladığında çeviri özellikleri kolaylaşır.',
              'Zor cümleleri parçalara böl, parça parça çevir.',
              'TTS ile telaffuz dinle; aynı cümleyi 2-3 kez tekrar et.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Rutin ve motivasyon',
            icon: Icons.calendar_month_outlined,
            color: Colors.pink,
            items: const [
              'Her gün 10-15 dakika: tutarlılık, yoğunluktan daha etkilidir.',
              'Tek seferde çok mesaj yerine sık aralıklarla kısa seanslar yap.',
              'Haftalık ilerlemeyi istatistiklerden takip et.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'İleri ipuçları',
            icon: Icons.tips_and_updates_outlined,
            color: Colors.green,
            items: const [
              'Konu ver: "Test me with B1 travel questions."',
              'Kelime defteri oluştur ve aynı bağlamda farklı cümleler yaz.',
              'Hedef: her mesajda 1 yeni yapı/kelime dene.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Dijital güvenlik',
            icon: Icons.shield_outlined,
            color: Colors.redAccent,
            items: const [
              'Kişisel bilgilerini paylaşma: ad-soyad, e‑posta, telefon, adres, konum, kimlik/finansal bilgiler.',
              'Şifre, tek kullanımlık kod (OTP) ve ödeme bilgilerini asla yazma veya ekran görüntüsüyle paylaşma.',
              'Bilinmeyen bağlantılara tıklama; uygulama içindeki resmi akışları kullan.',
              'Bilinmeyen kişilerden gelen dosya/linklere şüpheyle yaklaş; ekran görüntülerinde gizliliğe dikkat et.',
              'Taciz, nefret söylemi veya uygunsuz içerikle karşılaşırsan kullanıcıyı rapor et ve engelle.',
              'Güçlü şifre ve cihaz kilidi kullan; uygulamayı güncel tut ve mümkünse 2 adımlı doğrulamayı etkinleştir.',
              'Topluluk kurallarına uy; hassas/zararlı içerik paylaşma veya isteme.',
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Yapay zekâ ile etkili konuşma',
            icon: Icons.chat_bubble_outline_rounded,
            color: Colors.blueGrey,
            items: const [
              'Hedef ve bağlamı söyle: seviye (örn. B1), konu, rol ve amacını belirt.',
              'İstenen çıktıyı netleştir: örnek cümle, kısa açıklama, kontrol listesi, tablo vb.',
              'Tek amaç, tek mesaj: karmaşık işleri adımlara böl, gerektiğinde “adım adım ilerleyelim” de.',
              'Kısıtları ver: uzunluk sınırı, dil/ton (resmî/samimi), kaç örnek gerektiği.',
              'Geri bildirim iste: “Hatalarımı kısaca düzeltir misin?” veya “Daha doğal ifade önerir misin?”.',
              'Kişisel veri paylaşma; tıbbî/hukukî/finansal kritik konularda yanıtları doğrula.',
              'Uygunsuz/zararlı içerik isteme; güvenli ve saygılı bir dil kullan.',
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Anladım, başlayalım'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _Section({required this.title, required this.icon, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
