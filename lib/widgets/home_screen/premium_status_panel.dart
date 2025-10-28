// lib/widgets/home_screen/premium_status_panel.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

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
    AnimationController(vsync: this, duration: const Duration(seconds: 25))
      ..repeat();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
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
      return RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
                child: _AnimatedGoldBackground(controller: _bgController)),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: _PanelContent(
                  shimmerController: _shimmerController,
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
  const _PanelContent({required this.shimmerController});

  List<_Benefit> get _benefits => const [
    _Benefit('assets/animations/no ads icon.json', 'Ad-free'),
    _Benefit('assets/animations/Translate.json', 'Instant Translation'),
    _Benefit('assets/animations/Flags.json', 'Language Diversity'),
    _Benefit('assets/animations/Support.json', 'Priority Support'),
    _Benefit('assets/animations/Data Analysis.json', 'Grammar Analysis'),
    _Benefit('assets/animations/Robot says hello.json', 'VocaBot'),
    _Benefit('assets/animations/olympicsports.json', 'Practice'),
    _Benefit('assets/animations/Happy SUN.json', 'Shimmer'),
  ];

  @override
  Widget build(BuildContext context) {
    final shimmerSize = 13.5;
    final bodySize = 11.0;
    final chipFont = 10.5;

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShimmerTitle(controller: shimmerController, fontSize: shimmerSize),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'A faster, focused, and enjoyable learning experience with Pro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bodySize.clamp(11, 12),
                  height: 1.3,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _BenefitGrid(benefits: _benefits, chipFontSize: chipFont),
            const SizedBox(height: 10),
            const _ThanksRow(),
            const SizedBox(height: 12),
            const _ManageSubscriptionButton(),
          ],
        ),
      );
    });
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
    return Column(
      children: [
        for (int i = 0; i < benefits.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == benefits.length - 1 ? 0 : 6),
            child: _BenefitChip(
              benefit: benefits[i],
              fontSize: chipFontSize,
              index: i,
            ),
          ),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final _Benefit benefit;
  final double fontSize;
  final int index;
  const _BenefitChip(
      {required this.benefit,
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
            offset: Offset(0, (1 - t) * 6),
            child: child,
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              benefit.animationPath,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),
            Text(
              benefit.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize.clamp(11, 12),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
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
            height: 1.2,
            width: 100,
            margin: const EdgeInsets.only(bottom: 5),
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
            spacing: 6,
            runSpacing: 3,
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFFFFE8A3), size: 15),
              Flexible(
                child: Text(
                  'Your support strengthens the learning community. Thank you, Pro member!',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
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

class _ManageSubscriptionButton extends StatelessWidget {
  const _ManageSubscriptionButton();

  Future<void> _openSubscriptionManagement(BuildContext context) async {
    const url = 'https://play.google.com/store/account/subscriptions';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open subscription management'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSubscriptionManagement(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings,
                color: Colors.white.withValues(alpha: 0.95),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Manage Subscription',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit {
  final String animationPath;
  final String label;
  const _Benefit(this.animationPath, this.label);
}

