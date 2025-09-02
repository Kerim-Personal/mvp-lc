import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/chat_screen.dart';

class PartnerFoundScreen extends StatefulWidget {
  final String chatRoomId;
  const PartnerFoundScreen({super.key, required this.chatRoomId});

  @override
  State<PartnerFoundScreen> createState() => _PartnerFoundScreenState();
}

class _PartnerFoundScreenState extends State<PartnerFoundScreen> with TickerProviderStateMixin {
  Timer? _timer;
  Timer? _tick;
  String? _partnerName;
  String? _partnerAvatarUrl;
  bool _loadingPartner = true;
  static const int _waitSeconds = 3;
  int _secondsLeft = _waitSeconds;
  late final AnimationController _pulse;
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _fetchPartner();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer(const Duration(seconds: _waitSeconds), _goToChat);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        t.cancel();
      }
    });
  }

  Future<void> _fetchPartner() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).get();
      if (!chatDoc.exists) return;
      final users = (chatDoc.data()?['users'] as List<dynamic>?)?.cast<String>() ?? [];
      final partnerId = users.firstWhere((u) => u != currentUser.uid, orElse: () => '');
      if (partnerId.isEmpty) return;
      final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerId).get();
      if (!partnerDoc.exists) return;
      final data = partnerDoc.data() as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _partnerName = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : 'Unknown';
        _partnerAvatarUrl = (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : null;
        _loadingPartner = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPartner = false);
    }
  }

  void _goToChat() {
    if (!mounted) return;
    _pulse.stop();
    _bgAnim.stop();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (c,a,sa)=> ChatScreen(chatRoomId: widget.chatRoomId),
      transitionsBuilder: (c,a,sa,child)=> FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 450),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick?.cancel();
    _pulse.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 1 - (_secondsLeft / _waitSeconds).clamp(0.0, 1.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _bgAnim,
              builder: (context, _) {
                final v = _bgAnim.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.2 - v * 0.4, -0.3 + v * 0.6),
                      radius: 1.2,
                      colors: [
                        Colors.teal.shade900.withValues(alpha: 0.95),
                        Colors.teal.shade700.withValues(alpha: 0.85),
                        Colors.teal.shade400.withValues(alpha: 0.55),
                        Colors.teal.shade200.withValues(alpha: 0.25),
                      ],
                      stops: const [0, .35, .7, 1],
                    ),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: const SizedBox(),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHandshake(progress),
                        const SizedBox(height: 30),
                        Text('Partner Found', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.5, color: Colors.white)),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _loadingPartner ? _shimmerSkeleton() : _partnerInfoCard(),
                        ),
                        const SizedBox(height: 32),
                        Opacity(
                          opacity: .85,
                          child: Text('Preparing... Chat is about to start', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 14)),
                        ),
                        const SizedBox(height: 32),
                        _progressBar(progress),
                        const SizedBox(height: 18),
                        _countdownChips(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandshake(double progress) {
    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 150 * (1 + _pulse.value * 0.06),
              height: 150 * (1 + _pulse.value * 0.06),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  startAngle: 0,
                  endAngle: 6.283,
                  colors: [
                    Colors.tealAccent.withValues(alpha: .08),
                    Colors.tealAccent.withValues(alpha: .0),
                    Colors.tealAccent.withValues(alpha: .08),
                  ],
                  stops: const [0, .5, 1],
                  transform: GradientRotation(_pulse.value * 6.283),
                ),
              ),
            ),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .08), width: 2),
              gradient: LinearGradient(colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.teal.shade400.withValues(alpha: .25), blurRadius: 32, spreadRadius: 4),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(Icons.handshake, size: 54, color: Colors.teal.shade50),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _CircularProgressGlow(progress: progress)),
          ),
        ],
      ),
      );

  }

  Widget _progressBar(double progress) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      height: 8,
      child: Stack(children: [
        Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: .08), Colors.white.withValues(alpha: .02)]))),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal.shade300, Colors.teal.shade600]),
            ),
          ),
        ),
      ]),
    ),
  );

  Widget _countdownChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_waitSeconds, (i) {
        final remainingIndex = _waitSeconds - _secondsLeft - 1; // completed index
        final done = i <= remainingIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: done ? Colors.teal.shade500 : Colors.white.withValues(alpha: .08),
            border: Border.all(color: done ? Colors.tealAccent.withValues(alpha: .6) : Colors.white.withValues(alpha: .15), width: 1),
            boxShadow: done ? [BoxShadow(color: Colors.teal.shade300.withValues(alpha: .45), blurRadius: 14, spreadRadius: 1)] : [],
          ),
          child: Text('${i+1}', style: TextStyle(fontWeight: FontWeight.w600, color: done ? Colors.white : Colors.white70)),
        );
      }),
    );
  }

  Widget _shimmerSkeleton() {
    return SizedBox(
      height: 68,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _animatedShimmer(Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), shape: BoxShape.circle),
          )),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animatedShimmer(Container(width: 140, height: 14, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 10),
              _animatedShimmer(Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(4)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _animatedShimmer(Widget child) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment(-1 - _pulse.value, 0),
            end: Alignment(1 + _pulse.value, 0),
            colors: [Colors.white.withValues(alpha: .05), Colors.white.withValues(alpha: .25), Colors.white.withValues(alpha: .05)],
            stops: const [0, .5, 1],
          ).createShader(rect);
        },
        blendMode: BlendMode.srcATop,
        child: child,
      ),
    );
  }

  Widget _partnerInfoCard() {
    final name = _partnerName ?? 'Unknown';
    final avatarUrl = _partnerAvatarUrl;
    final avatar = _buildAvatar(avatarUrl, name);
    return Container(
      key: const ValueKey('partnerInfo'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: .06),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 26, offset: const Offset(0,10))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: 18),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.check_circle, size: 14, color: Colors.teal.shade300),
                const SizedBox(width: 4),
                Text('Connecting', style: TextStyle(fontSize: 12, color: Colors.teal.shade200, letterSpacing: .4)),
              ])
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    if (url == null) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.teal.shade600,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      );
    }
    if (url.endsWith('.svg') || url.contains('dicebear')) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.teal.shade50,
        child: ClipOval(
          child: SvgPicture.network(url, width: 60, height: 60, placeholderBuilder: (_) => const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.teal.shade50,
      backgroundImage: NetworkImage(url),
    );
  }
}

class _CircularProgressGlow extends CustomPainter {
  final double progress;
  _CircularProgressGlow({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white.withValues(alpha: .08);
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..shader = SweepGradient(colors: [
        Colors.tealAccent.withValues(alpha: .9),
        Colors.tealAccent.withValues(alpha: .2),
      ], startAngle: 0, endAngle: 6.283).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, track);
    final sweep = progress * 6.283;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.5708, sweep, false, active);
  }
  @override
  bool shouldRepaint(covariant _CircularProgressGlow old) => old.progress != progress;
}
