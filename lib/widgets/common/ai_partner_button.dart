import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vocachat/screens/vocabot_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocachat/widgets/home_screen/premium_upsell_dialog.dart';

class AiPartnerButton extends StatefulWidget {
  const AiPartnerButton({super.key});

  @override
  State<AiPartnerButton> createState() => _AiPartnerButtonState();
}

class _AiPartnerButtonState extends State<AiPartnerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _openAiPartner() async {
    if (!mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Oturum yoksa direkt upsell göster
        if (!mounted) return;
        showDialog(context: context, barrierDismissible: true, builder: (_) => const PremiumUpsellDialog());
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final isPremium = data != null && (data['isPremium'] == true);
      if (isPremium) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LinguaBotChatScreen()),
        );
      } else {
        if (!mounted) return;
        showDialog(context: context, barrierDismissible: true, builder: (_) => const PremiumUpsellDialog());
      }
    } catch (_) {
      if (!mounted) return;
      // Hata halinde güvenli default: upsell göster
      showDialog(context: context, barrierDismissible: true, builder: (_) => const PremiumUpsellDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open AI Partner',
      button: true,
      child: GestureDetector(
        onTap: _openAiPartner,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, child) {
            final v = _sparkleController.value;
            double local(double start, double end) {
              if (v < start || v > end) return 0.0;
              final t = (v - start) / (end - start);
              return math.sin(t * math.pi).clamp(0.0, 1.0);
            }
            final glow = math.max(local(0, 0.08), local(0.55, 0.63));
            final base = Colors.tealAccent;
            final fg = Color.lerp(base, Colors.white, glow) ?? Colors.white;
            final shadow = base.withValues(alpha: glow * 0.8);
            return Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                boxShadow: glow > 0 ? [BoxShadow(color: shadow, blurRadius: 14 + 8 * glow, spreadRadius: 1 + glow)] : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: Icon(Icons.smart_toy_outlined, size: 30, color: fg),
                    ),
                  ),
                  if (glow > 0.25)
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Transform.rotate(
                        angle: -glow * math.pi,
                        child: Icon(Icons.auto_awesome, size: 18 + glow * 4, color: Colors.amberAccent.withValues(alpha: 0.5 + glow * 0.4)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
