// lib/widgets/community_screen/group_chat_card.dart
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/screens/group_chat_screen.dart';

class GroupChatCard extends StatefulWidget {
  final GroupChatRoomInfo roomInfo;
  final bool compact; // yeni: kompakt gör��nüm
  const GroupChatCard({super.key, required this.roomInfo, this.compact = false});

  @override
  State<GroupChatCard> createState() => _GroupChatCardState();
}

class _GroupChatCardState extends State<GroupChatCard> {
  Offset _offset = Offset.zero;
  bool _loadingMembers = true;
  int _memberCount = 0;
  List<String> _avatarUrls = [];
  DateTime? _lastFetch;
  bool _pressed = false; // yeni: basılı animasyon durumu
  Timer? _periodic; // periyodik sayım güncelleme

  @override
  void initState() {
    super.initState();
    // Denormalize veriler geldiyse doğrudan kullan, ek okuma yapma
    final initialCount = widget.roomInfo.memberCount;
    final initialAvatars = widget.roomInfo.avatarsPreview;
    if (initialCount != null) {
      _memberCount = initialCount;
      _avatarUrls = (initialAvatars ?? []).take(3).toList();
      _loadingMembers = false;
    } else {
      _fetchMembers();
      _periodic = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) _fetchMembers();
      });
    }
  }

  @override
  void dispose() {
    _periodic?.cancel();
    super.dispose();
  }

  Future<void> _fetchMembers({bool force = false}) async {
    if (!force && widget.roomInfo.memberCount != null) return;
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!) < const Duration(seconds: 8)) return;
    try {
      setState(() => _loadingMembers = true);
      final membersRef = FirebaseFirestore.instance
          .collection('group_chats')
          .doc(widget.roomInfo.id)
          .collection('members');

      // Sadece aktif var mı ve avatar göstermek için birkaç kayıt
      final avatarSnap = await membersRef.limit(3).get();
      final avatars = <String>[];
      for (final d in avatarSnap.docs) {
        final data = d.data();
        final url = data['avatarUrl'];
        if (url is String && url.isNotEmpty) avatars.add(url);
      }

      int totalCount;
      try {
        final agg = await membersRef.count().get();
        totalCount = (agg.count ?? avatarSnap.size);
      } catch (_) {
        totalCount = avatarSnap.size;
      }

      if (mounted) {
        setState(() {
          _memberCount = totalCount; // sadece >0 kontrolü için tutuluyor
          _avatarUrls = avatars.take(3).toList();
          _loadingMembers = false;
          _lastFetch = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMembers = false;
          _lastFetch = DateTime.now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact(context);
    }
    return GestureDetector(
      onPanUpdate: (details) => setState(() => _offset += details.delta),
      onPanEnd: (_) => setState(() => _offset = Offset.zero),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              roomName: widget.roomInfo.name,
              roomIcon: widget.roomInfo.icon,
              roomId: widget.roomInfo.id,
            ),
          ),
        );
      },
      // onLongPress kaldırıldı
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_offset.dy * -0.002)
          ..rotateY(_offset.dx * 0.002),
        alignment: FractionalOffset.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 220,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [widget.roomInfo.color1, widget.roomInfo.color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.roomInfo.color2.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  )
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Önceki StreamBuilder kaldırıldı; tek seferlik fetch verileri kullanılıyor.
                  // Basit durum yönetimi:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeader(_memberCount),
                      const SizedBox(height: 12),
                      Text(
                        widget.roomInfo.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingMembers)
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Loading...', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                          ],
                        )
                      else
                        _buildFooter(_memberCount, _avatarUrls),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final hasMembers = _memberCount > 0;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              roomName: widget.roomInfo.name,
              roomIcon: widget.roomInfo.icon,
              roomId: widget.roomInfo.id,
            ),
          ),
        );
      },
      // onLongPress kaldırıldı
      onHighlightChanged: (v) => setState(() => _pressed = v),
      borderRadius: BorderRadius.circular(22),
      splashColor: Colors.white.withValues(alpha: 0.1),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ana arka plan
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    widget.roomInfo.color1.withValues(alpha: 0.92),
                    widget.roomInfo.color2.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.roomInfo.color2.withValues(alpha: 0.38),
                    blurRadius: _pressed ? 10 : 18,
                    spreadRadius: _pressed ? 0 : 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst bölüm
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İkon kabarcığı + radyal glow
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.32),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                            radius: 0.95,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            widget.roomInfo.icon,
                            color: Colors.white,
                            size: 24,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roomInfo.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.roomInfo.description.isNotEmpty
                                  ? widget.roomInfo.description
                                  : 'Henüz açıklama yok',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.8,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Alt footer
                  (_loadingMembers)
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.85)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Yükleniyor...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                )),
                          ],
                        )
                      : Row(
                          children: [
                            if (hasMembers) _buildMiniAvatars(),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.9),
                              ),
                              child: Icon(Icons.arrow_outward_rounded, size: 18, color: Colors.white.withValues(alpha: 0.95)),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            // Üst parlak overlay
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, 0.25, 0.6],
                    ),
                  ),
                ),
              ),
            ),
            // Canlı pulse (üye varsa)
            if (hasMembers)
              Positioned(
                top: 6,
                right: 6,
                child: _LivePulseDot(color: Colors.limeAccent.shade400),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int memberCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.roomInfo.icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.roomInfo.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
          ),
        ),
        if (memberCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 8)
              ],
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(int memberCount, List<String> avatarUrls) {
    if (memberCount <= 0) {
      return const SizedBox.shrink();
    }
    final avatarsToShow = avatarUrls.take(3).toList();
    return Row(
      children: [
        if (avatarsToShow.isNotEmpty)
          SizedBox(
            width: 70,
            height: 30,
            child: Stack(
              children: List.generate(
                avatarsToShow.length,
                (index) => Positioned(
                  left: (index * 20).toDouble(),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: SvgPicture.network(
                          avatarsToShow[index],
                          width: 28,
                          height: 28,
                          placeholderBuilder: (context) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    );
  }

  Widget _buildMiniAvatars() {
    if (_avatarUrls.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 10, backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.person, size: 12, color: Colors.white)),
        ],
      );
    }
    final list = _avatarUrls.take(3).toList();
    return SizedBox(
      width: (list.length * 18 + 12).toDouble(),
      height: 24,
      child: Stack(
        children: [
          for (int i = 0; i < list.length; i++)
            Positioned(
              left: (i * 18).toDouble(),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: SvgPicture.network(
                    list[i],
                    width: 22,
                    height: 22,
                    placeholderBuilder: (_) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Küçük canlı pulse widget
class _LivePulseDot extends StatefulWidget {
  final Color color;
  const _LivePulseDot({required this.color});
  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final scale = 0.6 + (t < 0.5 ? t : (1 - t)) * 0.5; // nefes efekti
          final opacity = 0.4 + (t < 0.5 ? t : (1 - t)) * 0.5;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 16 * scale,
                height: 16 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.4 * opacity),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6 * opacity),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
