import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DiamondPackGridTile extends StatelessWidget {
  final String productId;
  final String title;
  final String price;
  final String? badge;
  final Color? badgeColor;
  final bool loading;
  final VoidCallback? onTap;

  const DiamondPackGridTile({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    this.badge,
    this.badgeColor,
    this.loading = false,
    this.onTap,
  });

  // Sabit animasyon boyutu
  double get _animationSize => 60.0;

  // Container yüksekliğini sabit boyuta göre ayarla
  double get _containerHeight => 80.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showBadge = badge != null && badge!.isNotEmpty;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: loading ? 0.6 : 1,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: showBadge
                      ? (badgeColor ?? Colors.amber).withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.15),
                  width: showBadge ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rozet alanı - her durumda sabit yükseklik
                  SizedBox(
                    height: 28,
                    child: showBadge
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              // margin: const EdgeInsets.only(bottom: 8), // sabit alan ile gereksiz
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    (badgeColor ?? Colors.amber),
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Merkezi elmas animasyonu - sabit boyut
                  Flexible(
                    child: Container(
                      height: _containerHeight,
                      child: Center(
                        child: AnimatedScale(
                          scale: loading ? 0.8 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Lottie.asset(
                            'assets/animations/diamonds.json',
                            width: _animationSize,
                            height: _animationSize,
                            repeat: true,
                            animate: !loading,
                            fit: BoxFit.contain,
                            options: LottieOptions(
                              enableMergePaths: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Başlık - sabit font size
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Fiyat butonu - sabit boyut ve min genişlik
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minWidth: 88),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: loading
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : [const Color(0xFFFFD54F), const Color(0xFFFF8F00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: loading
                            ? Colors.grey.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            price,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
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
