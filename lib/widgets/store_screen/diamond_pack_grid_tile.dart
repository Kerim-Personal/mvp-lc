import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final showBadge = badge != null && badge!.isNotEmpty;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: loading ? 0.6 : 1,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: showBadge
                  ? (badgeColor ?? Colors.amber).withOpacity(0.55)
                  : Colors.white.withOpacity(0.15),
              width: showBadge ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (showBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            (badgeColor ?? Colors.amber),
                            Colors.black.withOpacity(0.55),
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
                    )
                  else
                    const SizedBox(height: 18),
                  const Spacer(),
                  Icon(Icons.diamond, color: Colors.amber.shade300, size: 22),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.35),
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
                          valueColor: AlwaysStoppedAnimation(Colors.black),
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
    );
  }
}

