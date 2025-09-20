// lib/screens/leaderboard_screen.dart

import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocachat/widgets/community_screen/leaderboard_table.dart';

// --- DATA MODELLERİ ---
class LeaderboardUser {
  final String userId;
  final String name;
  final String avatarUrl;
  final int rank;
  final int streak;
  final bool isPremium;
  final String role; // admin/moderator/user

  LeaderboardUser({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.streak,
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
    Query baseQuery = FirebaseFirestore.instance
        .collection('users')
        .orderBy('streak', descending: true)
        .limit(100);

    QuerySnapshot snapshot;
    snapshot = await baseQuery.get();

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
                  Text('An error occurred: ' + _leaderboardError.toString()),
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
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Leaderboard', style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 24),
            ],
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
          const SizedBox(height: 10),
          // Efsanevi rozetler
          _buildLegendRow(),
          const SizedBox(height: 10),
          // Kullanıcı sırası veya bilgi kartı
          _buildMyRankOrHint(),
        ],
      ),
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

  Widget _buildLegendRow() {
    final cs = Theme.of(context).colorScheme;
    Widget chip(Color c, String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Row(children: [
        Icon(Icons.circle, size: 10, color: c),
        const SizedBox(width: 6),
        Text(t, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
      ]),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(Colors.amber, 'Gold'),
        const SizedBox(width: 8),
        chip(Colors.grey.shade400, 'Silver'),
        const SizedBox(width: 8),
        chip(Colors.brown.shade400, 'Bronze'),
      ],
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
            const Expanded(child: Text("You're outside Top 100. Increase your streak to climb!")),
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
                mine!.avatarUrl,
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
                  '#${mine!.rank}  •  ${mine!.name}',
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
                const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text('${mine!.streak}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
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

// KALDIRILAN: _LeaderboardModePicker (overlay tabanlı açılır menü)
