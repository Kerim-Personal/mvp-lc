// lib/widgets/profile_screen/achievements_section.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  // All badge definitions (static data). Could be made dynamic from backend later.
  static const List<Achievement> _achievements = [
    Achievement(
      name: 'First Step',
      icon: Icons.flag,
      color: Colors.green,
      earned: true,
      description: 'Send your first message or finish your first lesson.',
    ),
    Achievement(
      name: 'Consistent',
      icon: Icons.calendar_today,
      color: Colors.teal,
      earned: true,
      description: 'Log in 7 days in a row.',
    ),
    Achievement(
      name: '5 Day Streak',
      icon: Icons.filter_5,
      color: Colors.lightBlue,
      earned: true,
      description: 'Reach a 5‑day learning streak.',
    ),
    Achievement(
      name: '30 Day Streak',
      icon: Icons.calendar_month,
      color: Colors.indigo,
      earned: false,
      description: 'Be active 30 days consecutively.',
    ),
    Achievement(
      name: '100 Day Streak',
      icon: Icons.timelapse,
      color: Colors.deepPurple,
      earned: false,
      description: 'Achieve a 100‑day uninterrupted streak.',
    ),
    Achievement(
      name: 'Chatty',
      icon: Icons.chat_bubble,
      color: Colors.blue,
      earned: true,
      description: 'Send a total of 100 messages.',
    ),
    Achievement(
      name: 'Conversation Master',
      icon: Icons.forum,
      color: Colors.blueGrey,
      earned: false,
      description: 'Send a total of 1000 messages.',
    ),
    Achievement(
      name: 'Night Owl',
      icon: Icons.nights_stay,
      color: Colors.deepOrange,
      earned: false,
      description: 'Be active on 3 different nights (00:00–03:00).',
    ),
    Achievement(
      name: 'Early Bird',
      icon: Icons.wb_sunny,
      color: Colors.orange,
      earned: false,
      description: 'Complete 5 morning (06:00–08:00) sessions.',
    ),
    Achievement(
      name: 'Explorer',
      icon: Icons.language,
      color: Colors.orangeAccent,
      earned: true,
      description: 'Join at least 3 different language rooms.',
    ),
    Achievement(
      name: 'Linguist',
      icon: Icons.menu_book,
      color: Colors.purple,
      earned: false,
      description: 'Learn 500 distinct words.',
    ),
    Achievement(
      name: 'Word Sage',
      icon: Icons.library_books,
      color: Colors.purpleAccent,
      earned: false,
      description: 'Learn 1000 distinct words.',
    ),
    Achievement(
      name: 'Translation Pro',
      icon: Icons.translate,
      color: Colors.redAccent,
      earned: false,
      description: 'Successfully translate 200 sentences.',
    ),
    Achievement(
      name: 'Grammar Slayer',
      icon: Icons.rule,
      color: Colors.brown,
      earned: false,
      description: 'Complete 100 grammar exercises correctly.',
    ),
    Achievement(
      name: 'Polyglot',
      icon: Icons.public,
      color: Colors.cyan,
      earned: false,
      description: 'Add 3 different languages to your learning list.',
    ),
    Achievement(
      name: 'Popular',
      icon: Icons.whatshot,
      color: Colors.red,
      earned: false,
      description: 'Reach 500 likes / interactions on your posts.',
    ),
    Achievement(
      name: 'Progress Tracker',
      icon: Icons.trending_up,
      color: Colors.greenAccent,
      earned: false,
      description: 'Level up 10 times.',
    ),
    Achievement(
      name: 'Marathoner',
      icon: Icons.directions_run,
      color: Colors.lightGreen,
      earned: false,
      description: 'Accumulate 300+ minutes practice over 7 days.',
    ),
    Achievement(
      name: 'Expert',
      icon: Icons.star,
      color: Colors.amber,
      earned: false,
      description: 'Earn the advanced proficiency badge.',
    ),
    Achievement(
      name: 'Legend',
      icon: Icons.emoji_events,
      color: Colors.deepOrangeAccent,
      earned: false,
      description: 'Complete all core badges and toughest goals.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: _achievements.map((a) => _AchievementBadge(achievement: a)).toList(),
      ),
    );
  }
}

class Achievement {
  final String name;
  final IconData icon;
  final Color color;
  final bool earned;
  final String description;
  const Achievement({
    required this.name,
    required this.icon,
    required this.color,
    required this.earned,
    required this.description,
  });
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  const _AchievementBadge({required this.achievement});

  void _showInfo(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'achievement',
      barrierColor: Colors.transparent, // Removed darkened background
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _AchievementDialog(achievement: achievement),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: anim,
          child: Transform.scale(scale: .9 + (.1 * curved.value), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 90,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _showInfo(context),
        child: Container(
          margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'achv-${a.name}',
                flightShuttleBuilder: (ctx, anim, dir, fromCtx, toCtx) => ScaleTransition(scale: anim, child: toCtx.widget),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: a.earned ? Border.all(color: a.color.withOpacity(0.5), width: 2) : null,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: a.earned ? a.color : Colors.grey.shade200,
                    child: Icon(a.icon, color: Colors.white, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                a.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: a.earned ? FontWeight.w600 : FontWeight.normal,
                  color: a.earned ? onSurface.withOpacity(0.9) : onSurface.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementDialog extends StatefulWidget {
  final Achievement achievement;
  const _AchievementDialog({required this.achievement});
  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _checkScale = CurvedAnimation(parent: _controller, curve: const Interval(.2, 1, curve: Curves.elasticOut));
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
    if (widget.achievement.earned) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 200), () => _confetti.play());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    const double avatarSize = 100; // reduced (110 -> 100)
    const double avatarVerticalOffset = -12; // slightly up
    final double topCardPadding = avatarSize / 2 + 44; // adjusted after size change

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Content
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth * .8).clamp(300, 460).toDouble();
                return Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Neon card (no blur, glass feel simulated with gradient)
                    Container(
                      width: width,
                      padding: EdgeInsets.fromLTRB(26, topCardPadding, 26, 30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            a.color.withOpacity(.14),
                            a.color.withOpacity(.08),
                            Theme.of(context).colorScheme.surface.withOpacity(.58),
                          ],
                        ),
                        border: Border.all(color: a.color, width: 3.0),
                        boxShadow: [
                          BoxShadow(color: a.color.withOpacity(.95), blurRadius: 14, spreadRadius: 1),
                          BoxShadow(color: a.color.withOpacity(.70), blurRadius: 34, spreadRadius: 8),
                          BoxShadow(color: a.color.withOpacity(.45), blurRadius: 60, spreadRadius: 20),
                          BoxShadow(color: a.color.withOpacity(.28), blurRadius: 90, spreadRadius: 36),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: .5, color: onSurface.withOpacity(.95))),
                          const SizedBox(height: 14),
                          Text(
                            a.description,
                            style: TextStyle(fontSize: 15, color: onSurface.withOpacity(.82), height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: a.earned ? Colors.green.withOpacity(.18) : Colors.orange.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(34),
                                  border: Border.all(color: a.earned ? Colors.green : Colors.orange, width: 1.1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(a.earned ? Icons.check_circle : Icons.lock_clock, size: 18, color: a.earned ? Colors.green : Colors.orange),
                                    const SizedBox(width: 7),
                                    Text(
                                      a.earned ? 'Earned' : 'Not earned yet',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: a.earned ? Colors.green : Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Top avatar + animation
                    Positioned(
                      top: avatarVerticalOffset,
                      child: Hero(
                        tag: 'achv-${a.name}',
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: avatarSize + 8,
                              height: avatarSize + 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [a.color, a.color.withOpacity(.10), a.color],
                                  startAngle: 0,
                                  endAngle: 6.283,
                                ),
                              ),
                            ),
                            Container(
                              width: avatarSize - 18,
                              height: avatarSize - 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: a.color.withOpacity(.75), blurRadius: 26, spreadRadius: -2),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: a.color,
                                child: Icon(a.icon, size: 40, color: Colors.white), // icon reduced (46 -> 40)
                              ),
                            ),
                            if (a.earned)
                              ScaleTransition(
                                scale: _checkScale,
                                child: Container(
                                  width: avatarSize + 20,
                                  height: avatarSize + 20,
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: a.color.withOpacity(.5), blurRadius: 12)],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.check, color: a.color, size: 28),
                                  ),
                                ),
                              ),
                            if (a.earned)
                              Positioned(
                                child: ConfettiWidget(
                                  confettiController: _confetti,
                                  blastDirectionality: BlastDirectionality.explosive,
                                  numberOfParticles: 18,
                                  maxBlastForce: 20,
                                  minBlastForce: 8,
                                  emissionFrequency: 0.5,
                                  gravity: 0.4,
                                  colors: [a.color, Colors.white, Colors.amber, Colors.greenAccent],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}