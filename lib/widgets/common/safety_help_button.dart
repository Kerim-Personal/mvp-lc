import 'dart:math' as math;
import 'package:flutter/material.dart';

class SafetyHelpButton extends StatefulWidget {
  const SafetyHelpButton({super.key});

  @override
  State<SafetyHelpButton> createState() => _SafetyHelpButtonState();
}

class _SafetyHelpButtonState extends State<SafetyHelpButton> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'View Premium features',
      button: true,
      child: GestureDetector(
        onTap: () => _showSafetyDialog(context),
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
                      child: Icon(Icons.help_outline_rounded, size: 30, color: fg),
                    ),
                  ),
                  if (glow > 0.25)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Transform.rotate(
                        angle: glow * math.pi,
                        child: Icon(Icons.star, size: 18 + glow * 4, color: Colors.amberAccent.withValues(alpha: 0.5 + glow * 0.4)),
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

// Premium features information dialog
void _showSafetyDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final accent = colorScheme.secondary;

  final sections = [
    (
      icon: Icons.speaker_notes_off_outlined,
      title: 'Ad-Free Experience',
      body:
          'Premium members enjoy uninterrupted learning with a completely ad-free interface, allowing better focus and concentration.'
    ),
    (
      icon: Icons.translate_outlined,
      title: 'Instant Translation',
      body:
          'Access real-time translation features without leaving the app. Translate messages and conversations seamlessly in over 100 languages.'
    ),
    (
      icon: Icons.language_outlined,
      title: 'Multi-Language Support',
      body:
          'VocaBot Premium supports 100+ languages for speech recognition, translation, and grammar analysis, enabling truly global learning.'
    ),
    (
      icon: Icons.psychology_outlined,
      title: 'Advanced Grammar Analysis',
      body:
          'Get detailed grammar feedback, clarity suggestions, and writing improvements powered by advanced AI to enhance your language skills.'
    ),
    (
      icon: Icons.smart_toy_outlined,
      title: 'Enhanced AI Conversations',
      body:
          'Experience more natural and context-aware conversations with VocaBot AI assistant, designed to adapt to your learning pace and style.'
    ),
    (
      icon: Icons.support_agent_outlined,
      title: 'Priority Support',
      body:
          'Receive faster response times and direct communication channels for any questions or technical assistance you may need.'
    ),
  ];

  showDialog(
    context: context,
    barrierColor: Colors.black87.withValues(alpha: 0.6),
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 700),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Gradient Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.92),
                        colorScheme.primaryContainer.withValues(alpha: 0.85),
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
                            child: const Icon(Icons.security_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Premium Features',
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
                        'Discover the enhanced features available with VocaChat Premium membership.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sections.map((s) => _SafetySectionCard(section: s, accent: accent)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: BoxDecoration(
                    color: (theme.colorScheme.surfaceContainerHighest).withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.6),
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
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SafetySectionCard extends StatelessWidget {
  final ({IconData icon, String title, String body}) section;
  final Color accent;
  const _SafetySectionCard({required this.section, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: .18), accent.withValues(alpha: .05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: accent.withValues(alpha: .35)),
                ),
                child: Icon(section.icon, size: 22, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      section.body,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.36),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
