import 'package:flutter/material.dart';

class DiamondPackTile extends StatefulWidget {
  final String productId;
  final String title; // e.g. "100 Elmas"
  final String price; // localized price
  final String? badge; // e.g. POPÜLER / EN İYİ DEĞER
  final Color? badgeColor;
  final bool loading;
  final VoidCallback? onTap;

  const DiamondPackTile({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    this.badge,
    this.badgeColor,
    this.loading = false,
    this.onTap,
  });

  @override
  State<DiamondPackTile> createState() => _DiamondPackTileState();
}

class _DiamondPackTileState extends State<DiamondPackTile> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 140), lowerBound: 0.0, upperBound: 1.0)..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : 1.0;
    final baseGradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.09),
        Colors.white.withValues(alpha: 0.03),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: scale,
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.loading ? null : widget.onTap,
        onHighlightChanged: (v) => _setPressed(v),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: baseGradient,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: Row(
            children: [
              _DiamondIcon(glow: widget.badge != null),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (widget.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  (widget.badgeColor ?? Colors.amber),
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Text(
                              widget.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: 0.72,
                      child: Text(
                        'Instant balance boost',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PriceButton(
                price: widget.price,
                loading: widget.loading,
                onTap: widget.loading ? null : widget.onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  final String price;
  final bool loading;
  final VoidCallback? onTap;
  const _PriceButton({required this.price, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
          )
        : Text(
            price,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: 0.2,
            ),
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Center(child: child),
    );
  }
}

class _DiamondIcon extends StatelessWidget {
  final bool glow;
  const _DiamondIcon({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: const Icon(Icons.diamond, color: Colors.white, size: 26),
    );
  }
}
