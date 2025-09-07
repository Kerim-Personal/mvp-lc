// lib/widgets/home_screen/premium_status_panel.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

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
      final scale = (w / 360).clamp(0.85, 1.0);
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
                  colors.first.withOpacity(0.88),
                  colors.last.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5B53A)
                      .withOpacity(0.30 + 0.05 * wave1.abs()),
                  blurRadius: 26 + 4 * wave1.abs(),
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                  width: 1.1, color: Colors.white.withOpacity(0.16)),
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
                              .withOpacity(0.12 + 0.08 * wave1.abs()),
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
    _Benefit(Icons.auto_awesome, 'Reklamsız'),
    _Benefit(Icons.translate_rounded, 'Anlık Çeviri'),
    _Benefit(Icons.filter_alt_rounded, 'Akıllı Filtre'),
    _Benefit(Icons.flash_on, 'Öncelikli Erişim'),
    _Benefit(Icons.lock_clock, 'Erken Özellikler'),
    _Benefit(Icons.support_agent, 'Öncelikli Destek'),
  ];

  @override
  Widget build(BuildContext context) {
    final titleBaseSize = 24.0 * textScale;
    final bodySize = 14.5 * textScale;
    final chipFont = 12.0 * textScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _ShimmerTitle(
            controller: shimmerController,
            fontSize: titleBaseSize.clamp(20, 24)),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Pro ile hızlanmış, odaklı ve keyifli öğrenme deneyimi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize.clamp(12.5, 15.0),
              height: 1.30,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 14),
        RepaintBoundary(
          child: _BenefitGrid(benefits: _benefits, chipFontSize: chipFont),
        ),
        const SizedBox(height: 18),
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
            'Lingua Pro Üyesisiniz',
            textAlign: TextAlign.center,
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
      int cols = (maxW / 130).floor().clamp(2, 4);
      final chipWidth = (maxW - (cols - 1) * 10) / cols;
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
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.78),
              Colors.white.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border:
          Border.all(color: Colors.white.withOpacity(0.16), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(benefit.icon, size: 18, color: const Color(0xFFFFE28A)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                benefit.label,
                overflow: TextOverflow.fade,
                softWrap: false,
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
            height: 2.0,
            width: 180,
            margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFFFFE8A3), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Desteğin öğrenen topluluğunu güçlendiriyor. Teşekkürler Pro üye! 💛',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.25,
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
  final IconData icon;
  final String label;
  const _Benefit(this.icon, this.label);
}
