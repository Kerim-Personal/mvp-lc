// lib/widgets/profile_screen/achievements_section.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class AchievementsSection extends StatelessWidget {
  final int streak; // mevcut anlık streak
  final int highestStreak; // en yüksek streak
  final int totalPracticeTime; // toplam pratik süresi (dakika)
  final int partnerCount; // partner sayısı
  final String level; // seviye (string olabilir)

  const AchievementsSection({
    super.key,
    required this.streak,
    required this.highestStreak,
    required this.totalPracticeTime,
    required this.partnerCount,
    required this.level,
  });

  static List<Achievement> buildAchievementsFromStats({
    required int streak,
    required int highestStreak,
    required int totalPracticeTime,
    required int partnerCount,
    required String level,
  }) {
    int _extractLevelNumber(String lvl) {
      final match = RegExp(r'(\d+)').firstMatch(lvl);
      if (match == null) return 0;
      return int.tryParse(match.group(1)!) ?? 0;
    }

    final lvlNum = _extractLevelNumber(level);
    return [
      Achievement(
        id: 'first_step',
        name: 'First Step',
        icon: Icons.flag,
        color: Colors.green,
        earned: (totalPracticeTime > 0) || highestStreak > 0 || partnerCount > 0,
        description: 'İlk adımı at: bir süre çalış veya etkileşim kur.',
      ),
      Achievement(
        id: 'streak_5',
        name: '5 Day Streak',
        icon: Icons.filter_5,
        color: Colors.lightBlue,
        earned: highestStreak >= 5,
        description: '5 günlük öğrenme serisine ulaş.',
      ),
      Achievement(
        id: 'streak_30',
        name: '30 Day Streak',
        icon: Icons.calendar_month,
        color: Colors.indigo,
        earned: highestStreak >= 30,
        description: '30 günlük kesintisiz seri.',
      ),
      Achievement(
        id: 'streak_100',
        name: '100 Day Streak',
        icon: Icons.timelapse,
        color: Colors.deepPurple,
        earned: highestStreak >= 100,
        description: '100 günlük efsanevi seri.',
      ),
      Achievement(
        id: 'consistent_7',
        name: 'Consistent',
        icon: Icons.calendar_today,
        color: Colors.teal,
        earned: streak >= 7 || highestStreak >= 7,
        description: 'Art arda 7 gün aktif ol.',
      ),
      Achievement(
        id: 'practice_60',
        name: 'Practice 60m',
        icon: Icons.timer,
        color: Colors.orange,
        earned: totalPracticeTime >= 60,
        description: 'Toplam 60+ dakika pratik yap.',
      ),
      Achievement(
        id: 'practice_300',
        name: 'Practice 300m',
        icon: Icons.av_timer,
        color: Colors.deepOrange,
        earned: totalPracticeTime >= 300,
        description: 'Toplam 300+ dakika pratik.',
      ),
      Achievement(
        id: 'social_3',
        name: 'Social 3',
        icon: Icons.people,
        color: Colors.green,
        earned: partnerCount >= 3,
        description: '3 farklı partnerle bağlantı kur.',
      ),
      Achievement(
        id: 'networker_10',
        name: 'Networker 10',
        icon: Icons.groups,
        color: Colors.greenAccent,
        earned: partnerCount >= 10,
        description: '10 farklı partnerle bağlantı kur.',
      ),
      Achievement(
        id: 'level_5',
        name: 'Level Up 5',
        icon: Icons.trending_up,
        color: Colors.purple,
        earned: lvlNum >= 5,
        description: 'Seviyeni en az 5\'e çıkar.',
      ),
    ];
  }

  static List<String> computeEarnedBadgeIds({
    required int streak,
    required int highestStreak,
    required int totalPracticeTime,
    required int partnerCount,
    required String level,
  }) {
    return buildAchievementsFromStats(
      streak: streak,
      highestStreak: highestStreak,
      totalPracticeTime: totalPracticeTime,
      partnerCount: partnerCount,
      level: level,
    ).where((a) => a.earned).map((a) => a.id).toList();
  }

  List<Achievement> _buildAchievements() {
    return buildAchievementsFromStats(
      streak: streak,
      highestStreak: highestStreak,
      totalPracticeTime: totalPracticeTime,
      partnerCount: partnerCount,
      level: level,
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: achievements.map((a) => _AchievementBadge(achievement: a)).toList(),
      ),
    );
  }
}

class Achievement {
  final String id; // eklenen stabil kimlik
  final String name;
  final IconData icon;
  final Color color;
  final bool earned;
  final String description;
  const Achievement({
    required this.id,
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
      barrierColor: Colors.transparent,
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
                    border: a.earned ? Border.all(color: a.color.withValues(alpha: 0.5), width: 2) : null,
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
                  color: a.earned ? onSurface.withValues(alpha: 0.9) : onSurface.withValues(alpha: 0.55),
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
                            a.color.withValues(alpha: .14),
                            a.color.withValues(alpha: .08),
                            Theme.of(context).colorScheme.surface.withValues(alpha: .58),
                          ],
                        ),
                        border: Border.all(color: a.color, width: 3.0),
                        boxShadow: [
                          BoxShadow(color: a.color.withValues(alpha: .95), blurRadius: 14, spreadRadius: 1),
                          BoxShadow(color: a.color.withValues(alpha: .70), blurRadius: 34, spreadRadius: 8),
                          BoxShadow(color: a.color.withValues(alpha: .45), blurRadius: 60, spreadRadius: 20),
                          BoxShadow(color: a.color.withValues(alpha: .28), blurRadius: 90, spreadRadius: 36),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: .5, color: onSurface.withValues(alpha: .95))),
                          const SizedBox(height: 14),
                          Text(
                            a.description,
                            style: TextStyle(fontSize: 15, color: onSurface.withValues(alpha: .82), height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: a.earned ? Colors.green.withValues(alpha: .18) : Colors.orange.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(34),
                                  border: Border.all(color: a.earned ? Colors.green : Colors.orange, width: 1.1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(a.earned ? Icons.check_circle : Icons.lock_clock, size: 18, color: a.earned ? Colors.green : Colors.orange),
                                    const SizedBox(width: 7),
                                    Text(
                                      a.earned ? 'Kazanıldı' : 'Henüz değil',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: a.earned ? Colors.green : Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                child: const Text('Kapat'),
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
                                  colors: [a.color, a.color.withValues(alpha: .10), a.color],
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
                                  BoxShadow(color: a.color.withValues(alpha: .75), blurRadius: 26, spreadRadius: -2),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: a.color,
                                child: Icon(a.icon, size: 40, color: Colors.white),
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
                                      boxShadow: [BoxShadow(color: a.color.withValues(alpha: .5), blurRadius: 12)],
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
