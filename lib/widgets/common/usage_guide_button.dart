import 'dart:math' as math;
import 'package:flutter/material.dart';

class UsageGuideButton extends StatefulWidget {
  const UsageGuideButton({super.key});

  @override
  State<UsageGuideButton> createState() => _UsageGuideButtonState();
}

class _UsageGuideButtonState extends State<UsageGuideButton> with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _openGuide() {
    if (!mounted) return;
    _showUsageGuideDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Efficient Usage Guide',
      button: true,
      child: GestureDetector(
        onTap: _openGuide,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, child) {
            final v = _sparkleController.value;
            double local(double start, double end) {
              if (v < start || v > end) return 0.0;
              final t = (v - start) / (end - start);
              return math.sin(t * math.pi).clamp(0.0, 1.0);
            }
            final glow = math.max(local(0, 0.08), local(0.55, 0.63));
            final base = Colors.tealAccent;
            final fg = Color.lerp(base, Colors.white, glow) ?? Colors.white;
            final shadow = base.withValues(alpha: glow * 0.8);
            return Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                boxShadow: glow > 0 ? [BoxShadow(color: shadow, blurRadius: 14 + 8 * glow, spreadRadius: 1 + glow)] : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Icon(Icons.menu_book_outlined, size: 30, color: fg),
                    ),
                  ),
                  if (glow > 0.25)
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Transform.rotate(
                        angle: -glow * math.pi,
                        child: Icon(Icons.auto_awesome, size: 18 + glow * 4, color: Colors.amberAccent.withValues(alpha: 0.5 + glow * 0.4)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showUsageGuideDialog(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  final sections = [
    (
      icon: Icons.rocket_launch_outlined,
      title: 'Getting Started',
      items: const [
        'Set your native and target languages in profile.',
        'Aim for 10-15 minutes daily practice.',
        'Enable notifications for consistency.',
      ],
    ),
    (
      icon: Icons.school_outlined,
      title: 'Grammar Path',
      items: const [
        'Follow A1→C2 levels in order.',
        'Complete lessons to unlock next topics.',
        'Review completed lessons regularly.',
      ],
    ),
    (
      icon: Icons.library_books_outlined,
      title: 'Vocabulary',
      items: const [
        'Start with "Daily Life" pack first.',
        'Learn 5-8 words per session.',
        'Review learned words weekly.',
      ],
    ),
    (
      icon: Icons.fitness_center_outlined,
      title: 'Practice Skills',
      items: const [
        'Writing: One paragraph, one idea.',
        'Reading: Read twice for comprehension.',
        'Listening: Start with subtitles.',
        'Speaking: Record and compare.',
      ],
    ),
    (
      icon: Icons.smart_toy_outlined,
      title: 'VocaBot Chat',
      items: const [
        'Write clear, short messages.',
        'Ask "Check my grammar" for help.',
        'Long-press messages for tools.',
        'Practice daily conversations.',
      ],
    ),
    (
      icon: Icons.analytics_outlined,
      title: 'Track Progress',
      items: const [
        'Check completion percentages weekly.',
        'Monitor your chat time statistics.',
        'Maintain daily streaks.',
      ],
    ),
    (
      icon: Icons.tips_and_updates_outlined,
      title: 'Pro Tips',
      items: const [
        'Mix all four skills in sessions.',
        'Create sentences with new words.',
        'Ask VocaBot for level challenges.',
      ],
    ),
  ];

  showDialog(
    context: context,
    barrierColor: Colors.black87.withValues(alpha: 0.6),
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        backgroundColor: theme.dialogTheme.backgroundColor ?? cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Başlık (dijital güvenlikle aynı tema)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.92),
                        cs.primaryContainer.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.menu_book_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Efficient Usage Guide',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Make faster progress with short, focused and regular practice. Apply these tips right away.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // İçerik
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final s in sections) ...[
                            _SectionBlock(icon: s.icon, title: s.title, items: s.items),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Alt Buton
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: BoxDecoration(
                    color: (cs.surfaceContainerHighest).withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.6),
                    border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.25))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text('Got it'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SectionBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  const _SectionBlock({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary.withValues(alpha: .18), cs.primary.withValues(alpha: .05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: cs.primary.withValues(alpha: .35)),
                  ),
                  child: Icon(icon, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
