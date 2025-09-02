// lib/screens/challenge_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/models/challenge_model.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart'; // FIX: Added missing import

class ChallengeScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeScreen({super.key, required this.challenge});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff2a2a2a), // A dark and modern background
      body: Stack(
        children: [
          // Background effects
          const _GlowyBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                pinned: true,
                automaticallyImplyLeading: false, // Remove automatic back button
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(),
                  stretchModes: const [StretchMode.zoomBackground],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _AnimatedContent(
                      animationController: _animationController,
                      interval: const Interval(0.4, 1.0),
                      child: const Text(
                        'Example Sentences',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(widget.challenge.exampleSentences.length,
                            (index) {
                          return _AnimatedContent(
                            animationController: _animationController,
                            interval: Interval(0.5 + (index * 0.1), 1.0,
                                curve: Curves.easeOut),
                            child: _buildExampleCard(
                                widget.challenge.exampleSentences[index]),
                          );
                        }),
                  ]),
                ),
              ),
            ],
          ),
          // Custom Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BackButton(color: Colors.white.withAlpha(204)),
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
          colors: [Colors.transparent, Colors.black26],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.flag_circle_outlined,
                size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              widget.challenge.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black38)],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.challenge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withAlpha(204)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(String sentence) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        blur: 12,
        borderRadius: 16,
        border: Border.all(color: Colors.white.withAlpha(26)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(38),
            Colors.white.withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sentence,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withAlpha(230),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.copy_all_outlined,
                    color: Colors.white.withAlpha(179)),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sentence));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.teal,
                      content: const Text('Sentence copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for the background
class _GlowyBackground extends StatelessWidget {
  const _GlowyBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -150,
          child: CircleAvatar(
              radius: 200, backgroundColor: Colors.amber.withAlpha(64)),
        ),
        Positioned(
          bottom: -180,
          left: -150,
          child: CircleAvatar(
              radius: 220, backgroundColor: Colors.orange.withAlpha(64)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}

// Helper widget for animations
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
            .animate(
            CurvedAnimation(parent: animationController, curve: interval)),
        child: child,
      ),
    );
  }
}