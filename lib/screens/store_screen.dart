// lib/screens/store_screen.dart

import 'package:flutter/material.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              expandedHeight: 200.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Mağaza',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.cyan.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const Icon(Icons.shopping_bag_outlined,
                        size: 80, color: Colors.white24)
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const PlanCard(
                      title: 'Lingua Plus',
                      price: '49.99 TL/ay',
                      features: [
                        'Sınırsız Partner Bulma',
                        'Cinsiyete Göre Arama',
                        'Sınırsız Sohbet Çevirisi',
                        'Sohbet Geçmişine Erişim',
                        'Reklamsız Deneyim',
                      ],
                      isPopular: false,
                    ),
                    const SizedBox(height: 20),
                    const PlanCard(
                      title: 'Lingua Pro',
                      price: '89.99 TL/ay',
                      features: [
                        'Tüm Plus Özellikleri',
                        'İleri Seviye Partnerlerle Eşleşme (C1-C2)',
                        'İleri Seviye İstatistikler',
                        'Öncelikli Destek',
                        'Özel Tema Seçenekleri',
                      ],
                      isPopular: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isPopular;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? Border.all(color: Colors.amber, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPopular ? Colors.amber.shade800 : Colors.teal),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54),
                ),
                const Divider(height: 32),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color:
                          isPopular ? Colors.amber.shade800 : Colors.green,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(feature,
                              style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? Colors.amber : Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Planı Seç',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -15,
              right: 20,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Popüler',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}