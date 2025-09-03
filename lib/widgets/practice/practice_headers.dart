import 'package:flutter/material.dart';

class ModeHeroHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final String image;
  final List<Color> colors;
  final IconData icon;
  final double height;
  final EdgeInsets margin;
  final bool hero;

  const ModeHeroHeader(
      {super.key,
      required this.tag,
      required this.title,
      required this.subtitle,
      required this.image,
      required this.colors,
      required this.icon,
      this.height = 150,
      this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
      this.hero = true});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: colors.last.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors)))),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.15)
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    if (!hero) return content;
    return Hero(tag: tag, child: content);
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final List<Widget>? actions;

  const EmptyState(
      {super.key, required this.message, this.icon = Icons.inbox_rounded, this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (actions != null) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}
