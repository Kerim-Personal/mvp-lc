// lib/widgets/home_screen/premium_status_panel.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Premium kullanıcıya değer hissettiren, faydaları özetleyen panel.
class PremiumStatusPanel extends StatefulWidget {
  const PremiumStatusPanel({super.key});

  @override
  State<PremiumStatusPanel> createState() => _PremiumStatusPanelState();
}

class _PremiumStatusPanelState extends State<PremiumStatusPanel>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _bgController =
    AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final scale = (w / 360).clamp(0.75, 1.0);
      return RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
                child: _AnimatedGoldBackground(controller: _bgController)),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _PanelContent(
                  shimmerController: _shimmerController,
                  textScale: scale,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Ayrılmış arka plan
class _AnimatedGoldBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedGoldBackground({required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final wave1 = math.sin(t * math.pi * 2);
        final colors = [
          const Color(0xFF3B2A00),
          const Color(0xFF8B6300),
          const Color(0xFFE5B53A),
        ].map((c) {
          final l = (0.08 + 0.10 * (math.sin(t * 6) + 1) / 2);
          return Color.lerp(c, Colors.white, l) ?? c;
        }).toList();
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  colors.first.withValues(alpha: 0.88),
                  colors.last.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5B53A)
                      .withValues(alpha: 0.30 + 0.05 * wave1.abs()),
                  blurRadius: 26 + 4 * wave1.abs(),
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                  width: 1.1, color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Stack(children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE28A)
                              .withValues(alpha: 0.12 + 0.08 * wave1.abs()),
                          blurRadius: 40 + 6 * wave1.abs(),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _PanelContent extends StatelessWidget {
  final AnimationController shimmerController;
  final double textScale;
  const _PanelContent(
      {required this.shimmerController, required this.textScale});

  List<_Benefit> get _benefits => const [
    _Benefit('assets/animations/no ads icon.json', 'Ad-free'),
    _Benefit('assets/animations/Translate.json', 'Instant Translation'),
    _Benefit('assets/animations/Support.json', 'Priority Support'),
    _Benefit('assets/animations/Data Analysis.json', 'Grammar Analysis'),
    _Benefit('assets/animations/Robot says hello.json', 'VocaBot'),
    _Benefit('assets/animations/Happy SUN.json', 'Shimmer'),
  ];

  @override
  Widget build(BuildContext context) {
    final titleBaseSize = 20.0 * textScale; // Başlık boyutunu küçülttüm
    final bodySize = 12.0 * textScale; // Açıklama boyutunu küçülttüm
    final chipFont = 10.0 * textScale; // Chip font boyutunu küçülttüm
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shimmer başlık en üstte
        _ShimmerTitle(
            controller: shimmerController,
            fontSize: titleBaseSize.clamp(16, 20)), // Max boyutu düşürdüm
        const SizedBox(height: 3), // Boşluğu azalttım
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'A faster, focused, and enjoyable learning experience with Pro.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize.clamp(10, 12), // Boyutu küçülttüm
              height: 1.2, // Line height'ı azalttım
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8), // Boşluğu azalttım
        // Özellikler ortada
        RepaintBoundary(
          child: _BenefitGrid(benefits: _benefits, chipFontSize: chipFont),
        ),
        const SizedBox(height: 8), // Boşluğu azalttım
        // Teşekkür en sonda - orijinal mesajla
        const _ThanksRow(),
      ],
    );
  }
}

class _ShimmerTitle extends StatelessWidget {
  final AnimationController controller;
  final double fontSize;
  const _ShimmerTitle({required this.controller, required this.fontSize});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        double start = (v * 1.4 - 0.4).clamp(0.0, 1.0);
        double end = (start + 0.35).clamp(0.0, 1.0);
        if (end - start < 0.05) {
          end = (start + 0.05).clamp(0.0, 1.0);
        }
        final mid = start + (end - start) / 2;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => LinearGradient(
            colors: const [
              Color(0xFFFFE8A3),
              Colors.white,
              Color(0xFFFFE8A3)
            ],
            stops: [start, mid, end],
          ).createShader(b),
          child: Text(
            'You are a VocaChat Pro Member',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  final List<_Benefit> benefits;
  final double chipFontSize;
  const _BenefitGrid({required this.benefits, required this.chipFontSize});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final maxW = c.maxWidth;
      // Tek kolon - alt alta dizilim
      final int cols = 1;
      final double chipWidth = math.min(maxW * 0.9, 280); // Daha geniş chip'ler
      final rows = (benefits.length / cols).ceil();
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxW,
        ),
        child: Column(
          children: List.generate(rows, (r) {
            final start = r * cols;
            final end = (start + cols).clamp(0, benefits.length);
            final slice = benefits.sublist(start, end);
            return Padding(
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : 8), // Normal boşluk
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < slice.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          right: i == slice.length - 1 ? 0 : 10),
                      child: _BenefitChip(
                        benefit: slice[i],
                        width: chipWidth,
                        fontSize: chipFontSize,
                        index: start + i,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }
}

class _BenefitChip extends StatelessWidget {
  final _Benefit benefit;
  final double width;
  final double fontSize;
  final int index;
  const _BenefitChip(
      {required this.benefit,
        required this.width,
        required this.fontSize,
        required this.index});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.78),
              Colors.white.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border:
          Border.all(color: Colors.white.withValues(alpha: 0.16), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              benefit.animationPath,
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              // color: const Color(0xFFFFE28A)
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                benefit.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                // softWrap true by default
                style: TextStyle(
                  fontSize: fontSize.clamp(11, 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThanksRow extends StatelessWidget {
  const _ThanksRow();
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 1.5, // Çizgi kalınlığını azalttım
            width: 120, // Çizgi genişliğini azalttım
            margin: const EdgeInsets.only(bottom: 6), // Margin'i azalttım
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFE8A3),
                  Color(0xFFE5B53A),
                  Color(0xFFFFE8A3)
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8, // Spacing'i azalttım
            runSpacing: 4, // Run spacing'i azalttım
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFFFFE8A3), size: 16), // İkon boyutunu küçülttüm
              Flexible(
                child: Text(
                  'Your support strengthens the learning community. Thank you, Pro member!',
                  textAlign: TextAlign.center,
                  maxLines: 2, // 2 satıra izin verdim
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.0, // Font boyutunu küçülttüm
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2, // Line height'ı azalttım
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  final String animationPath; // IconData yerine animasyon dosya yolu
  final String label;
  const _Benefit(this.animationPath, this.label);
}
