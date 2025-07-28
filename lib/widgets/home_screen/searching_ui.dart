// lib/widgets/home_screen/searching_ui.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/linguabot_chat_screen.dart'; // Yönlendirme için import edildi

class SearchingUI extends StatefulWidget {
  final bool isSearching;
  final AnimationController searchAnimationController;
  final VoidCallback onCancelSearch;

  const SearchingUI({
    super.key,
    required this.isSearching,
    required this.searchAnimationController,
    required this.onCancelSearch,
  });

  @override
  State<SearchingUI> createState() => _SearchingUIState();
}

class _SearchingUIState extends State<SearchingUI> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tips = [
      "Yeni bir kelime öğrendiğinde, onu 3 farklı cümlede kullanmaya çalış.",
      "Hata yapmaktan korkma! Hatalar öğrenme sürecinin bir parçasıdır.",
      "Anlamadığın bir şey olduğunda tekrar sormaktan çekinme."
    ];
    final randomTip = (List.of(tips)..shuffle()).first;

    return IgnorePointer(
      ignoring: !widget.isSearching,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: widget.isSearching ? 1 : 0,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3), // Üst boşluk
              Hero(
                tag: 'find-partner-hero',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: widget.searchAnimationController,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            center: Alignment.center,
                            colors: [Colors.transparent, Colors.cyan],
                            stops: [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    const Material(
                      color: Colors.transparent,
                      child: Icon(Icons.person_search_rounded,
                          color: Colors.teal, size: 60),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text('Partner Aranıyor...',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal)),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(26),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('İpucu: $randomTip',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ),
              const Spacer(flex: 2), // Orta boşluk
              _buildLinguaBotCard(context),
              const SizedBox(height: 30),
              TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10)),
                onPressed: widget.onCancelSearch,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Aramayı İptal Et',
                    style: TextStyle(fontSize: 16)),
              ),
              const Spacer(flex: 1), // Alt boşluk
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinguaBotCard(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: InkWell(
        onTap: () {
          // GÜNCELLENDİ: SnackBar yerine LinguaBot sohbet ekranına yönlendiriliyor.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LinguaBotChatScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade500, Colors.deepPurple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withAlpha(128),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy_outlined,
                        color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Beklemek istemiyor musun?",
                            style: TextStyle(
                                fontSize: 13, color: Colors.white70),
                          ),
                          Text(
                            "LinguaBot'u dene!",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black26, blurRadius: 4)
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          -MediaQuery.of(context).size.width * 0.7 +
                              (_shimmerController.value *
                                  MediaQuery.of(context).size.width *
                                  1.4),
                          0,
                        ),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha(0),
                                  Colors.white.withAlpha(64),
                                  Colors.white.withAlpha(0),
                                ],
                                stops: const [0.1, 0.5, 0.9],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}