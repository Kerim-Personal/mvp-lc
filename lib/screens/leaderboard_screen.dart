// lib/screens/leaderboard_screen.dart

import 'dart:ui' show ImageFilter;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocachat/widgets/community_screen/leaderboard_table.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- DATA MODELLERİ ---
class LeaderboardUser {
  final String userId;
  final String name;
  final String avatarUrl;
  final int rank;
  final int streak; // legacy: eskiden sıralama streak'e dayanıyordu
  final int totalRoomSeconds; // yeni: odalarda geçirilen toplam süre (saniye)
  final bool isPremium;
  final String role; // admin/moderator/user

  LeaderboardUser({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.streak,
    this.totalRoomSeconds = 0,
    this.isPremium = false,
    this.role = 'user',
  });
}

class GroupChatRoomInfo {
  // GroupChatCard bunu buradan import ettiği için bu model korunuyor
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final bool isFeatured;
  final int? memberCount;
  final List<String>? avatarsPreview;

  GroupChatRoomInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color1,
    required this.color2,
    this.isFeatured = false,
    this.memberCount,
    this.avatarsPreview,
  });
}


// --- ANA EKRAN WIDGET'I ---
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.initialTabIndex});
  final int? initialTabIndex; // Artık kullanılmıyor, ancak geri uyumluluk için tutuldu

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  String _leaderboardType = 'weekly';

  // Ek performans & animasyon kontrolü
  bool _leaderboardFirstAnimationDone = false;
  List<LeaderboardUser>? _overallCache;
  List<LeaderboardUser>? _weeklyCache;

  // Flicker azaltma cache'leri
  List<LeaderboardUser>? _leaderboardCache;
  bool _leaderboardLoading = false;
  Object? _leaderboardError;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard(initial: true);
    _maybeShowWeeklyRewardIntro();
  }

  Future<void> _maybeShowWeeklyRewardIntro() async {
    if (_leaderboardType != 'weekly') return;
    final prefs = await SharedPreferences.getInstance();
    const key = 'weekly_rewards_intro_seen_v1';
    final seen = prefs.getBool(key) ?? false;
    if (seen) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showWeeklyRewardDialog();
      final p = await SharedPreferences.getInstance();
      await p.setBool(key, true);
    });
  }

  Future<void> _loadLeaderboard({bool force = false, bool initial = false}) async {
    // Var olan cache'i hızlı göster (force değilse) - lag azaltma
    if (!force) {
      if (_leaderboardType == 'overall' && _overallCache != null) {
        _leaderboardCache = _overallCache; // anında göster
        if (!initial) setState(() {});
        if (!initial) return; // arka planda fetch tetiklemeden çık
      } else if (_leaderboardType == 'weekly' && _weeklyCache != null) {
        _leaderboardCache = _weeklyCache;
        if (!initial) setState(() {});
        if (!initial) return;
      }
    }

    if (_leaderboardLoading) return;
    setState(() {
      _leaderboardLoading = true;
      if (force) _leaderboardError = null;
    });
    try {
      final data = await _fetchLeaderboardData();
      if (!mounted) return;
      setState(() {
        _leaderboardCache = data;
        if (_leaderboardType == 'overall') {
          _overallCache = data;
        } else {
          _weeklyCache = data;
        }
        _leaderboardLoading = false;
        if (!_leaderboardFirstAnimationDone && data.isNotEmpty) {
          _leaderboardFirstAnimationDone = true; // ilk başarılı yüklemede işaretle
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leaderboardError = e;
        _leaderboardLoading = false;
      });
    }
  }

  Future<void> _refreshLeaderboard() async {
    await _loadLeaderboard(force: true);
  }

  Future<List<LeaderboardUser>> _fetchLeaderboardData() async {
    // Artık leaderboard toplam oda zamanına göre (totalRoomTime alanı) sıralanıyor
    Query baseQuery = FirebaseFirestore.instance
        .collection('users')
        .orderBy('totalRoomTime', descending: true)
        .limit(100);

    QuerySnapshot snapshot = await baseQuery.get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return _mapUsersFromSnapshot(snapshot);
  }

  List<LeaderboardUser> _mapUsersFromSnapshot(QuerySnapshot snapshot) {
    final users = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'];
      return status == null || (status != 'banned' && status != 'deleted');
    }).toList();
    return users.asMap().entries.map((entry) {
      final doc = entry.value;
      final data = doc.data() as Map<String, dynamic>;
      return LeaderboardUser(
        userId: doc.id,
        rank: entry.key + 1,
        name: (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : 'Unknown',
        avatarUrl: (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : 'https://api.dicebear.com/8.x/micah/svg?seed=guest',
        streak: (data['streak'] as num?)?.toInt() ?? 0,
        totalRoomSeconds: (data['totalRoomTime'] as num?)?.toInt() ?? 0,
        isPremium: data['isPremium'] == true,
        role: (data['role'] as String?) ?? 'user',
      );
    }).toList();
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _refreshLeaderboard,
      child: Builder(
        builder: (context) {
          if (_leaderboardLoading && (_leaderboardCache == null || _leaderboardCache!.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_leaderboardError != null && (_leaderboardCache == null || _leaderboardCache!.isEmpty)) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('An error occurred: ${_leaderboardError}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadLeaderboard(force: true),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          final data = _leaderboardCache;
          if (data == null || data.isEmpty) {
            return const Center(child: Text('No leaderboard data.'));
          }
          return LeaderboardTable(
            users: data,
            animate: !_leaderboardFirstAnimationDone,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final titleStyle = GoogleFonts.montserrat(
      fontSize: theme.textTheme.titleLarge?.fontSize ?? 22,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      color: theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Başlık
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.leaderboard_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Center(
                  child: Text(
                    'Leaderboard',
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                // Sağ üst: ödül bilgi butonu
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: Colors.transparent,
                    child: _RewardInfoButton(onTap: () { _showWeeklyRewardDialog(); }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Yeni segment switch
          _ModeSegmentedSwitch(
            current: _leaderboardType,
            onChanged: (val) {
              if (_leaderboardType == val) return;
              HapticFeedback.selectionClick();
              setState(() { _leaderboardType = val; });
              _loadLeaderboard(force: false);
            },
          ),
          const SizedBox(height: 12),
          // Top 3 Podyum
          _buildTopPodium(),
          const SizedBox(height: 12),
          // Kullanıcı sırası veya bilgi kartı
          _buildMyRankOrHint(),
        ],
      ),
    );
  }

  Future<void> _showWeeklyRewardDialog() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return showDialog(
      context: context,
      barrierColor: Colors.black87.withValues(alpha: 0.55),
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Weekly Rewards',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                        tooltip: 'Close',
                      )
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Trophy Lottie
                      Semantics(
                        label: 'Weekly Rewards Trophy',
                        child: Lottie.asset(
                          'assets/animations/Trophy.json',
                          height: 180,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Compete weekly, earn shiny rewards',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Climb the leaderboard and unlock weekly perks. Stay active, stay consistent, and claim your spot!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                          label: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopPodium() {
    final data = _leaderboardCache;
    if (data == null || data.isEmpty) return const SizedBox.shrink();
    final top = List<LeaderboardUser>.from(data)..sort((a, b) => a.rank.compareTo(b.rank));
    final items = top.take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    Color badgeColor(int rank) {
      switch (rank) {
        case 1: return Colors.amber;
        case 2: return Colors.grey.shade400;
        case 3: return Colors.brown.shade400;
        default: return Theme.of(context).colorScheme.primary;
      }
    }

    Widget pillar(LeaderboardUser u) {
      final color = badgeColor(u.rank);
      final isGold = u.rank == 1;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.18),
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isGold ? Icons.emoji_events : Icons.military_tech, color: color, size: 20),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: isGold ? 26 : 22,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: SvgPicture.network(
                    u.avatarUrl,
                    width: (isGold ? 52 : 44),
                    height: (isGold ? 52 : 44),
                    placeholderBuilder: (context) => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                u.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#${u.rank}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sıralama: 2 | 1 | 3 görünümü
    final l2 = items.length > 1 ? items[1] : items.first;
    final l1 = items.first;
    final l3 = items.length > 2 ? items[2] : items.last;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          pillar(l2),
          const SizedBox(width: 8),
          pillar(l1),
          const SizedBox(width: 8),
          pillar(l3),
        ],
      ),
    );
  }

  Widget _buildMyRankOrHint() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();
    final list = _leaderboardCache;
    if (list == null || list.isEmpty) return const SizedBox.shrink();

    LeaderboardUser? mine;
    for (final u in list) {
      if (u.userId == me.uid) {
        mine = u;
        break;
      }
    }

    if (mine == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text("You're outside Top 100. Spend more time in rooms to climb!")),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: SvgPicture.network(
                mine.avatarUrl,
                width: 36,
                height: 36,
                placeholderBuilder: (context) => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  '#${mine.rank}  •  ${mine.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(_formatDuration(mine.totalRoomSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0s';
    final d = Duration(seconds: totalSeconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m';
    }
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildLeaderboardTab()),
          ],
        ),
      ),
    );
  }
}

// --- YENİ TASARIM: CAM EFEKTLI, ANIMASYONLU SEGMENT SWITCH ---
class _ModeSegmentedSwitch extends StatefulWidget {
  final String current; // 'weekly' | 'overall'
  final ValueChanged<String> onChanged;
  const _ModeSegmentedSwitch({required this.current, required this.onChanged});

  @override
  State<_ModeSegmentedSwitch> createState() => _ModeSegmentedSwitchState();
}

class _ModeSegmentedSwitchState extends State<_ModeSegmentedSwitch> {
  int get _index => widget.current == 'overall' ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final thumbPad = 4.0;
        final height = 52.0;

        return Container(
          // Gradient border wrap
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.35),
                cs.secondary.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(1.2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: height,
                width: totalW,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(22), blurRadius: 18, offset: const Offset(0, 10)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sliding thumb (half width)
                      Padding(
                        padding: EdgeInsets.all(thumbPad),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          alignment: _index == 0 ? Alignment.centerLeft : Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            heightFactor: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content row
                      Row(
                        children: [
                          _segButton(
                            selected: _index == 0,
                            icon: Icons.calendar_view_week_rounded,
                            label: 'Weekly',
                            onTap: () => widget.onChanged('weekly'),
                          ),
                          _segButton(
                            selected: _index == 1,
                            icon: Icons.public_rounded,
                            label: 'Overall',
                            onTap: () => widget.onChanged('overall'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _segButton({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final Color textColor = selected ? cs.onPrimary : cs.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: (selected ? cs.onPrimary : cs.primary).withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: selected ? 0.3 : 0.1,
                        color: textColor,
                      ),
                      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reward info button with animation
class _RewardInfoButton extends StatefulWidget {
  const _RewardInfoButton({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_RewardInfoButton> createState() => _RewardInfoButtonState();
}

class _RewardInfoButtonState extends State<_RewardInfoButton> with SingleTickerProviderStateMixin {
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
      label: 'Reward Information',
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
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
                boxShadow: glow > 0 ? [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 14 + 8 * glow,
                    spreadRadius: 1 + glow,
                  ),
                ] : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Icon(Icons.card_giftcard_rounded, size: 30, color: fg),
                    ),
                  ),
                  if (glow > 0.25)
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Transform.rotate(
                        angle: -glow * math.pi,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 18 + glow * 4,
                          color: Colors.amberAccent.withValues(alpha: 0.5 + glow * 0.4),
                        ),
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
