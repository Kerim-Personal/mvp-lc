import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _confetti = ConfettiController(duration: const Duration(milliseconds: 500));
  int _index = 0;

  final _pages = const [
    _OnbPage(
      title: 'Learn faster. Enjoy more.',
      desc: 'Master vocabulary with bite‑sized drills that fit your day.',
      lottie: 'assets/animations/Happy SUN.json',
    ),
    _OnbPage(
      title: 'Practice in real conversations',
      desc: 'Chat with VocaBot — speak, write, and listen to build confident fluency.',
      lottie: 'assets/animations/Robot says hello.json',
    ),
    _OnbPage(
      title: 'Own your progress',
      desc: 'Earn badges, climb leaderboards, and stay on track.',
      lottie: 'assets/animations/The winner receives gold medal.json',
    ),
  ];

  // Her sayfa için hafif bir degrade arka plan paleti
  late final List<Gradient> _backgrounds = [
    const LinearGradient(colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    const LinearGradient(colors: [Color(0xFFFF9966), Color(0xFFFF5E62)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finishWithDelight();
    }
  }

  Future<void> _finishWithDelight() async {
    _confetti.play();
    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan SafeArea dışında: tam ekran
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: _backgrounds[_index % _backgrounds.length],
            ),
          ),
          Container(color: Theme.of(context).scaffoldBackgroundColor.withAlpha(18)),

          // İçerikler SafeArea içinde
          SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _AnimatedOnb(child: _pages[i], index: i, current: _index),
                ),
                // Skip
                Positioned(
                  right: 12,
                  top: 8,
                  child: TextButton(
                    onPressed: _finishWithDelight,
                    child: const Text('Skip'),
                  ),
                ),
                // Alt kısım: göstergeler + CTA
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: active ? 22 : 8,
                            decoration: BoxDecoration(
                              color: active ? color.primary : color.onSurface.withAlpha(64),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _next,
                            icon: Icon(isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded),
                            label: Text(isLast ? 'Get started' : 'Next'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Konfeti üstte
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.0,
                numberOfParticles: 18,
                maxBlastForce: 12,
                minBlastForce: 6,
                gravity: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final String title;
  final String desc;
  final String lottie;
  const _OnbPage({required this.title, required this.desc, required this.lottie});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Semantics(
            label: title,
            child: Lottie.asset(lottie, height: 240, repeat: true),
          ),
          const SizedBox(height: 24),
          Text(title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            desc,
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _AnimatedOnb extends StatelessWidget {
  final Widget child;
  final int index;
  final int current;
  const _AnimatedOnb({required this.child, required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1 : 0.6,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(index == current),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        tween: Tween(begin: isActive ? 20 : 40, end: 0),
        builder: (context, dy, _) {
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
      ),
    );
  }
}
