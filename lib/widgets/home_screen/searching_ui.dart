// lib/widgets/home_screen/searching_ui.dart

import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/linguabot_chat_screen.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';

class SearchingUI extends StatefulWidget {
  final bool isSearching;
  final VoidCallback onCancelSearch;
  final bool isPremium;

  const SearchingUI({
    super.key,
    required this.isSearching,
    required this.onCancelSearch,
    this.isPremium = false,
  });

  @override
  State<SearchingUI> createState() => _SearchingUIState();
}

class _SearchingUIState extends State<SearchingUI> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _sonarController;
  late final AnimationController _breathingController;
  // EKLENDİ: Arka planın yavaşça kaymasını sağlayacak animasyon controller'ı.
  late final AnimationController _backgroundController;

  late final Animation<Alignment> _backgroundAlignmentAnimation;

  Timer? _tipTimer;
  String _currentTip = "";
  final List<String> _tips = const [
    "When you learn a new word, try using it in 3 different sentences.",
    "Don't fear mistakes! They are part of learning.",
    "If you don't understand something, politely ask again.",
    "Break the ice by asking how your partner's day is going.",
    "Focus on communicating, not being perfect.",
    "Paraphrase what your partner said to confirm understanding."
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _sonarController = AnimationController(vsync: this, duration: const Duration(seconds: 2, milliseconds: 500))..repeat();
    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 3),)..repeat(reverse: true);

    // EKLENDİ: Arka plan controller'ı ve animasyonu ayarlandı.
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
    _backgroundAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _currentTip = _tips[Random().nextInt(_tips.length)];
  }

  @override
  void didUpdateWidget(covariant SearchingUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearching && !oldWidget.isSearching) {
      _entryController.forward(from: 0.0);
      _startTimers();
    }
    if (!widget.isSearching && oldWidget.isSearching) {
      _entryController.reverse(from: 1.0);
      _stopTimers();
    }
  }

  void _startTimers() {
    _tipTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) setState(() => _currentTip = (_tips..shuffle()).first);
      else timer.cancel();
    });
  }

  void _stopTimers() => _tipTimer?.cancel();

  @override
  void dispose() {
    _entryController.dispose();
    _sonarController.dispose();
    _breathingController.dispose();
    _backgroundController.dispose(); // EKLENDİ: Controller dispose edildi.
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isSearching,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.isSearching ? 1 : 0,
        child: Stack(
          children: [
            // GÜNCELLENDİ: Arka plan artık AnimatedBuilder ile dinamik.
            _buildCosmicDawnBackground(),
            Center(
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    RepaintBoundary( child: _buildSonarAnimation() ),
                    const SizedBox(height: 30),
                    _buildInfoPanel(),
                    const Spacer(flex: 2),
                    _buildLinguaBotCard(context),
                    const SizedBox(height: 20),
                    _buildCancelButton(),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCosmicDawnBackground() {
    // GÜNCELLENDİ: AnimatedBuilder ile gradyan merkezi yavaşça kaydırılıyor.
    return AnimatedBuilder(
      animation: _backgroundAlignmentAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _backgroundAlignmentAnimation.value,
              radius: 1.5,
              colors: const [
                Color(0xFFa741c8), // Canlı Macenta (Şafak)
                Color(0xFF232a4e), // Derin İndigo (Gece)
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildSonarAnimation() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut)
      ),
      child: CustomPaint(
        painter: _SonarPainter(_sonarController),
        child: Container(
          width: 180, height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFc886e3).withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFc886e3).withOpacity(0.4),
                blurRadius: 70, spreadRadius: 10,
              )
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_search_rounded,
              color: Colors.white, size: 60,
              shadows: [ Shadow(color: Color(0xFFc886e3), blurRadius: 25) ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
      child: FadeTransition(
        opacity: _entryController,
        child: GlassmorphicContainer(
          width: MediaQuery.of(context).size.width * 0.85,
          borderRadius: 24, blur: 15,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text('Searching for a Partner...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(
                    'Tip: $_currentTip',
                    key: ValueKey<String>(_currentTip),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinguaBotCard(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _entryController, curve: Curves.elasticOut.flipped),
      child: FadeTransition(
        opacity: _entryController,
        child: InkWell(
          onTap: () {
            widget.onCancelSearch();
            Navigator.push(context, MaterialPageRoute(builder: (context) => LinguaBotChatScreen(isPremium: widget.isPremium)));
          },
          borderRadius: BorderRadius.circular(20),
          child: GlassmorphicContainer(
            width: MediaQuery.of(context).size.width * 0.85,
            borderRadius: 20, blur: 10,
            border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
            gradient: LinearGradient(
              colors: [const Color(0xFFa741c8).withOpacity(0.3), const Color(0xFF232a4e).withOpacity(0.4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: Colors.pink.shade200, size: 36),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Don't want to wait?", style: TextStyle(fontSize: 13, color: Colors.white70)),
                        Text("Try LinguaBot!", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
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

  Widget _buildCancelButton() {
    return FadeTransition(
      opacity: _entryController,
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
        onPressed: widget.onCancelSearch,
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancel Search', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _SonarPainter extends CustomPainter {
  final Animation<double> _animation;
  _SonarPainter(this._animation) : super(repaint: _animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2);
    for (int wave = 2; wave >= 0; wave--) {
      _drawWave(canvas, rect, wave);
    }
  }

  void _drawWave(Canvas canvas, Rect rect, int wave) {
    final double value = (_animation.value + (wave * 0.33)) % 1.0;
    final double radius = rect.width / 2.0 * value;
    final double opacity = pow((1.0 - value), 2).toDouble();
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [ Colors.transparent, const Color(0xFFc886e3).withOpacity(opacity) ],
      ).createShader(Rect.fromCircle(center: rect.center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SonarPainter oldDelegate) => false;
}