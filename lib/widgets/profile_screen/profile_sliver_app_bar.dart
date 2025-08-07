// lib/widgets/profile_screen/profile_sliver_app_bar.dart

import 'dart:ui';
import 'dart:math'; // HATA 1 İÇİN ÇÖZÜM: Matematik kütüphanesi eklendi.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ProfileSliverAppBar: Gelişmiş animasyonlar ve estetik dokunuşlarla zenginleştirilmiş,
/// dinamik ve etkileşimli bir SliverAppBar.
///
/// Özellikler:
///   - Scroll (Kaydırma) hareketine duyarlı parallax efekti.
///   - Avatar ve metinler için yumuşak ölçeklenme ve geçiş (fade) animasyonları.
///   - Sürekli ve yavaşça hareket eden "kozmik" bir arkaplan animasyonu.
///   - Avatar etrafında nefes alıp veren, canlı bir parlama efekti.
///   - Performans ve okunabilirlik için optimize edilmiş, modüler kod yapısı.
class ProfileSliverAppBar extends StatefulWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;

  const ProfileSliverAppBar({
    super.key,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  @override
  State<ProfileSliverAppBar> createState() => _ProfileSliverAppBarState();
}

class _ProfileSliverAppBarState extends State<ProfileSliverAppBar> with TickerProviderStateMixin {
  // Avatarın etrafındaki "nefes alma" efektini kontrol eden animasyon denetleyicisi.
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cihazın üst kısmındaki güvenli alan (saat, pil vb. olan kısım) ve
    // standart toolbar yüksekliğini hesaba katarak çökme (collapse) yüksekliğini belirliyoruz.
    final double topPadding = MediaQuery.of(context).padding.top;
    final double collapsedHeight = kToolbarHeight + topPadding;
    const double expandedHeight = 350.0; // Efektler için daha geniş bir alan.

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.teal.shade800, // Çökme durumundaki arkaplan rengi
      elevation: 0,
      centerTitle: true,
      // AppBar çöktüğünde görünecek olan başlık.
      title: _buildCollapsedTitle(),
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            final double currentHeight = constraints.maxHeight;

            // Kaydırma ilerlemesini hesaplıyoruz: 1.0 tam açık, 0.0 tam kapalı.
            final double scrollProgress = ((currentHeight - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Katman 1: Sürekli hareket eden, estetik arkaplan.
                _CosmicBackground(scrollProgress: scrollProgress),

                // Katman 2: Parallax ve fade efektlerine sahip kullanıcı bilgileri.
                _buildUserInfo(scrollProgress),
              ],
            );
          },
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
      ),
    );
  }

  /// AppBar çöktüğünde görünecek olan başlık.
  Widget _buildCollapsedTitle() {
    return Text(
      widget.displayName,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: Colors.white),
    );
  }

  /// Avatar, kullanıcı adı ve e-posta gibi bilgileri içeren, kaydırmaya duyarlı bölüm.
  Widget _buildUserInfo(double scrollProgress) {
    // Kaydırma ilerlemesine göre değerleri enterpole ederek yumuşak geçişler sağlıyoruz.
    final avatarScale = lerpDouble(0.4, 1.0, scrollProgress)!;
    final contentOpacity = Curves.easeIn.transform(scrollProgress);
    final contentVerticalOffset = lerpDouble(0, 40, 1 - scrollProgress)!;

    return Opacity(
      opacity: contentOpacity,
      child: Transform.translate(
        offset: Offset(0, contentVerticalOffset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildAnimatedAvatar(avatarScale),
            const SizedBox(height: 16),
            Text(
              widget.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: TextStyle(
                // HATA 2 İÇİN ÇÖZÜM: withOpacity, withAlpha ile değiştirildi.
                color: Colors.white.withAlpha(217), // ~85% opacity
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Nefes alma" animasyonuna sahip avatar widget'ı.
  Widget _buildAnimatedAvatar(double scale) {
    return Transform.scale(
      scale: scale,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          // Sinüs fonksiyonu ile yumuşak bir parlama efekti yaratıyoruz.
          final glowValue = (1 + sin(_glowController.value * 2 * pi)) / 2;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // HATA 2 İÇİN ÇÖZÜM: withOpacity, withAlpha ile değiştirildi.
                  color: Colors.white.withAlpha((lerpDouble(25, 102, glowValue)!).round()), // 10% to 40% opacity
                  blurRadius: lerpDouble(15, 25, glowValue)!,
                  spreadRadius: lerpDouble(2, 5, glowValue)!,
                ),
              ],
            ),
            child: child,
          );
        },
        child: CircleAvatar(
          radius: 55,
          // HATA 2 İÇİN ÇÖZÜM: withOpacity, withAlpha ile değiştirildi.
          backgroundColor: Colors.white.withAlpha(230), // ~90% opacity
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.teal.shade100,
            child: widget.avatarUrl != null
                ? ClipOval(
              child: SvgPicture.network(
                widget.avatarUrl!,
                placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 2),
                width: 104,
                height: 104,
                fit: BoxFit.cover,
              ),
            )
                : Text(
              widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 52,
                color: Colors.teal.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arka planda yavaşça hareket eden ve kaydırmaya tepki veren estetik bir katman.
class _CosmicBackground extends StatelessWidget {
  final double scrollProgress;
  const _CosmicBackground({required this.scrollProgress});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.cyan.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Kaydırma ilerlemesine göre gradient'in renklerini ve konumunu değiştiriyoruz.
          stops: [0.0, lerpDouble(0.7, 1.0, scrollProgress)!],
        ),
      ),
      // Arka plana derinlik katmak için bir bulanıklık (blur) efekti ekliyoruz.
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: lerpDouble(0, 5, 1 - scrollProgress)!,
          sigmaY: lerpDouble(0, 5, 1 - scrollProgress)!,
        ),
        child: Container(
          // HATA 2 İÇİN ÇÖZÜM: withOpacity, withAlpha ile değiştirildi.
          decoration: BoxDecoration(color: Colors.black.withAlpha(26)), // 10% opacity
        ),
      ),
    );
  }
}