import 'package:flutter/material.dart';

class SearchingUI extends StatelessWidget {
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
  Widget build(BuildContext context) {
    const tips = [
      "Yeni bir kelime öğrendiğinde, onu 3 farklı cümlede kullanmaya çalış.",
      "Hata yapmaktan korkma! Hatalar öğrenme sürecinin bir parçasıdır.",
      "Anlamadığın bir şey olduğunda tekrar sormaktan çekinme."
    ];
    final randomTip = (List.of(tips)..shuffle()).first;

    return IgnorePointer(
      ignoring: !isSearching,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: isSearching ? 1 : 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'find-partner-hero',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: searchAnimationController,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(26),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('İpucu: $randomTip',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ),
            const SizedBox(height: 50),
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: onCancelSearch,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Aramayı İptal Et', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}