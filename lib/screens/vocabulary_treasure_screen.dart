// lib/screens/vocabulary_treasure_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/vocabulary_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';

class VocabularyTreasureScreen extends StatefulWidget {
  final VocabularyWord word;

  const VocabularyTreasureScreen({super.key, required this.word});

  @override
  State<VocabularyTreasureScreen> createState() =>
      _VocabularyTreasureScreenState();
}

class _VocabularyTreasureScreenState extends State<VocabularyTreasureScreen> with TickerProviderStateMixin {
  late FlutterTts flutterTts;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1d2630),
      body: Stack(
        children: [
          const _GlowyBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                // FIX: Disabling the automatic back button.
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                  stretchModes: const [StretchMode.zoomBackground],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), // Adjusted top padding
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // The "Meaning" card has been removed as per your request.
                    _AnimatedContent(
                      animationController: _animationController,
                      interval: const Interval(0.6, 1.0),
                      child: _buildInfoCard(
                        icon: Icons.format_quote_rounded,
                        title: 'Example Sentence',
                        content: widget.word.exampleSentence,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BackButton(color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black12],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => _speak(widget.word.word),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.word.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 20, color: Colors.black54)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.word.phonetic,
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content, required Color color}) {
    return GlassmorphicContainer(
      width: double.infinity,
      blur: 12,
      borderRadius: 20,
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowyBackground extends StatelessWidget {
  const _GlowyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          left: -200,
          child: CircleAvatar(radius: 250, backgroundColor: Colors.green.withOpacity(0.3)),
        ),
        Positioned(
          bottom: -200,
          right: -180,
          child: CircleAvatar(radius: 220, backgroundColor: Colors.teal.withOpacity(0.3)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}

class _AnimatedContent extends StatelessWidget {
  final AnimationController animationController;
  final Interval interval;
  final Widget child;

  const _AnimatedContent({
    required this.animationController,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animationController, curve: interval),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(CurvedAnimation(parent: animationController, curve: interval)),
        child: child,
      ),
    );
  }
}