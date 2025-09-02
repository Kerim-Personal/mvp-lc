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
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open safety guide',
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

// Safety warning dialog function
void _showSafetyDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final accent = colorScheme.secondary;

  final principles = [
    'Report & Block: Protect your peace.',
    'Privacy: Do not disclose personal information.',
    'Financial Safety: Decline requests for money transfers.',
    'Do Not Meet Offline: Your safety comes first.'
  ];

  final sections = [
    (
      icon: Icons.report_gmailerrorred_outlined,
      title: 'Reporting & Blocking',
      body:
          'If you encounter behavior that bothers you or violates community guidelines (harassment, hate speech, fraud, etc.), report the person without hesitation and then block them.'
    ),
    (
      icon: Icons.privacy_tip_outlined,
      title: 'Data Privacy & Confidentiality',
      body:
          'Avoid sharing personally identifying information like your full name, phone number, home/work/school address, ID/passport number, or anything similar.'
    ),
    (
      icon: Icons.savings_outlined,
      title: 'Financial Safety',
      body:
          'Be extremely skeptical of anyone asking you for money, gift cards, crypto, or any financial transfer for any reason. Almost all such requests are scams.'
    ),
    (
      icon: Icons.person_pin_circle_outlined,
      title: 'Meeting in Real Life',
      body:
          'Non‑negotiable: Do not meet. Malicious people online can hide their identities. Warmth can be a mask to manipulate you; one careless moment can have irreversible consequences.'
    ),
    (
      icon: Icons.psychology_alt_outlined,
      title: 'Social Engineering / Manipulation',
      body:
          'Manipulation exploits your emotions against your logic. They create fake urgency (crisis, opportunity, secret). Your strongest defense is TIME. If you feel emotional pressure, pause; saying “Let me think” or “I will share this with someone I trust” breaks the script. Their plan depends on instant compliance. You are valuable; no decision outranks your peace and safety.'
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
                // Gradient Başlık
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
                            child: const Icon(Icons.shield_moon_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Digital Safety Guide',
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
                        'A safe and positive experience is essential. The guide below supports your decisions.',
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
                          Text('Core Principles', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          ...principles.map((p) => _BulletLine(text: p, color: accent)),
                          const SizedBox(height: 22),
                          ...sections.map((s) => _SafetySectionCard(section: s, accent: accent)),
                          const SizedBox(height: 4),
                          _HighlightBox(
                            icon: Icons.lightbulb_outline,
                            title: 'Remember',
                            message:
                                'Being informed and cautious is the key to existing freely and safely in the digital world. You can always reopen this guide by tapping the help icon.',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                // Alt Butonlar
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

class _HighlightBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _HighlightBox({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cs.secondaryContainer.withValues(alpha: .75), cs.secondaryContainer.withValues(alpha: .55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.secondary.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.onSecondaryContainer.withValues(alpha: 0.08),
              border: Border.all(color: cs.onSecondaryContainer.withValues(alpha: .18)),
            ),
            child: Icon(icon, color: cs.onSecondaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletLine({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 8, color: color.withValues(alpha: 0.9)),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          )
        ],
      ),
    );
  }
}