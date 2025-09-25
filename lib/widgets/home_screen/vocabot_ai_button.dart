// lib/widgets/home_screen/vocabot_ai_button.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class PartnerFinderSection extends StatefulWidget {
  final VoidCallback onFindPartner;
  final AnimationController pulseAnimationController;
  final double? size;
  final String? buttonText;
  final Color? primaryColor;
  final Color? secondaryColor;

  const PartnerFinderSection({
    super.key,
    required this.onFindPartner,
    required this.pulseAnimationController,
    this.size,
    this.buttonText,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<PartnerFinderSection> createState() => _PartnerFinderSectionState();
}

class _PartnerFinderSectionState extends State<PartnerFinderSection>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isAnimationLoaded = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Theme constants
  static const double _defaultSize = 180.0;
  static const String _defaultButtonText = 'Chat';
  static const double _shadowBlurRadius = 30.0;
  static const double _shadowSpreadRadius = 5.0;
  static const Offset _shadowOffset = Offset(0, 15);
  static const double _pressedScale = 0.95;
  static const double _pulseIntensity = 0.05;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _preloadAssets();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _pressedScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _preloadAssets() async {
    try {
      await rootBundle.load('assets/animations/chat.json');
      if (mounted) {
        setState(() => _isAnimationLoaded = true);
      }
    } catch (e) {
      // Animation dosyası bulunamazsa varsayılan ikon kullanılacak
      debugPrint('Chat animation asset could not be loaded: $e');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  double get _buttonSize => widget.size ?? _defaultSize;
  String get _buttonText => widget.buttonText ?? _defaultButtonText;
  Color get _primaryColor => widget.primaryColor ?? Colors.teal;
  Color get _secondaryColor => widget.secondaryColor ?? Colors.cyan;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _resetButtonState();
    widget.onFindPartner();
  }

  void _handleTapCancel() {
    _resetButtonState();
  }

  void _resetButtonState() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  Widget _buildAnimationContent() {
    final animationSize = _buttonSize * 0.5; // Boyutu %67'den %50'ye düşürdüm

    if (_isAnimationLoaded) {
      return Lottie.asset(
        'assets/animations/chat.json',
        height: animationSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(animationSize),
      );
    }

    return _buildFallbackIcon(animationSize);
  }

  Widget _buildFallbackIcon(double size) {
    return Icon(
      Icons.chat_bubble_outline_rounded,
      color: Colors.white,
      size: size,
    );
  }

  Widget _buildButtonContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: _buttonSize * 0.08), // Üst boşluğu azalttım
        Text(
          _buttonText,
          style: TextStyle(
            color: Colors.white,
            fontSize: _buttonSize * 0.12, // Font boyutunu biraz küçülttüm
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: _buttonSize * 0.02), // Arası boşluğu azalttım
        Flexible(child: _buildAnimationContent()), // Flexible ile sarmaladım
      ],
    );
  }

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [widget.pulseAnimationController, _scaleAnimation]),
      builder: (context, child) {
        final pulseScale = 1.0 - (widget.pulseAnimationController.value *
            _pulseIntensity);
        final pressScale = _scaleAnimation.value;
        final finalScale = _isPressed ? pressScale : pulseScale;

        return Transform.scale(
          scale: finalScale,
          child: Container(
            width: _buttonSize,
            height: _buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.4),
                  blurRadius: _shadowBlurRadius,
                  spreadRadius: _shadowSpreadRadius,
                  offset: _shadowOffset,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: _buildButtonContent(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Hero(
            tag: 'find-partner-hero',
            child: _buildButton(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}