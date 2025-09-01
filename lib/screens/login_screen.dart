// lib/screens/login_screen.dart

import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/register_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/screens/verification_screen.dart';
import 'package:lingua_chat/l10n/app_localizations.dart'; // <-- Lokalizasyon importu

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _entryAnimationController;
  late AnimationController _backgroundAnimationController;

  // Staggered Animations
  late Animation<double> _headerFade, _emailFade, _passwordFade, _buttonFade;
  late Animation<Offset> _headerSlide,
      _emailSlide,
      _passwordSlide,
      _buttonSlide;

  // Parallax effect
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Giriş animasyonları
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Arka plan animasyonu
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    // Staggered Animation Definitions
    _headerFade = _createFadeAnimation(begin: 0.0, end: 0.6);
    _headerSlide = _createSlideAnimation(begin: 0.0, end: 0.6);

    _emailFade = _createFadeAnimation(begin: 0.2, end: 0.8);
    _emailSlide = _createSlideAnimation(begin: 0.2, end: 0.8, xOffset: -0.5);

    _passwordFade = _createFadeAnimation(begin: 0.4, end: 1.0);
    _passwordSlide = _createSlideAnimation(begin: 0.4, end: 1.0, xOffset: 0.5);

    _buttonFade = _createFadeAnimation(begin: 0.6, end: 1.0);
    _buttonSlide = _createSlideAnimation(begin: 0.6, end: 1.0);

    _entryAnimationController.forward();
  }

  Animation<double> _createFadeAnimation(
      {required double begin, required double end}) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _entryAnimationController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    ));
  }

  Animation<Offset> _createSlideAnimation(
      {required double begin, required double end, double xOffset = 0}) {
    return Tween<Offset>(
        begin: Offset(xOffset, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entryAnimationController,
      curve: Interval(begin, end, curve: Curves.easeInOutCubic),
    ));
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;

      if (e.code == 'email-not-verified') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationScreen(email: _emailController.text.trim()),
          ),
        );
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Geçersiz e-posta veya şifre.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } else {
        errorMessage = 'Beklenmedik bir hata oluştu: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginGoogle() async {
    setState(() { _isLoading = true; });
    try {
      final cred = await _authService.signInWithGoogle();
       if (cred == null) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Google girişi iptal edildi'), backgroundColor: Colors.orange),
           );
         }
       }
     } on FirebaseAuthException catch (e) {
       if (!mounted) return;
       if (e.code == 'account-exists-with-different-credential' || e.code == 'credential-already-in-use') {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Bu e-posta başka bir yöntemle kayıtlı. Lütfen önce e-posta/şifre ile giriş yapın ve Profil > Hesap Yönetimi > Google\'ı Bağla üzerinden bağlayın.'),
             backgroundColor: Colors.orange,
           ),
         );
         return;
       }
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Google Giriş Hatası: ${e.message}'), backgroundColor: Colors.red),
       );
     } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Beklenmedik hata: $e'), backgroundColor: Colors.red),
       );
     } finally {
       if (mounted) setState(() { _isLoading = false; });
     }
   }

  // lib/screens/login_screen.dart dosyanıza ekleyin

  // lib/screens/login_screen.dart dosyanıza bu fonksiyonu ekleyin

  void _showPasswordResetDialog() {
    final resetEmailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        bool isSending = false;
        String? dialogError;

        // StatefulBuilder, sadece diyalog içindeki state'i yönetir,
        // böylece tüm ekran yeniden çizilmez.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                elevation: 0,
                // Kenar boşluklarını kendimiz yöneterek tam kontrol sağlıyoruz.
                insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                // contentPadding'i sıfırlayıp kendi padding'imizi SingleChildScrollView içine koyuyoruz.
                contentPadding: EdgeInsets.zero,
                content: SingleChildScrollView( // <-- HATA ÇÖZÜMÜ BURADA!
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: dialogFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open_rounded, color: Theme.of(context).primaryColor, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            "Şifreni Sıfırla",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Kayıtlı e-posta adresini gir, sana şifreni sıfırlaman için bir bağlantı gönderelim.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: resetEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "E-posta Adresi",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.05),
                            ),
                            validator: (value) {
                              if (value == null || !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Lütfen geçerli bir e-posta adresi girin.';
                              }
                              return null;
                            },
                          ),
                          if (dialogError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                dialogError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: [
                  // Butonları da Column içine alarak dikey simetriyi pekiştiriyoruz.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        onPressed: isSending ? null : () async {
                          if (dialogFormKey.currentState!.validate()) {
                            setDialogState(() {
                              isSending = true;
                              dialogError = null;
                            });
                            try {
                              await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Şifre sıfırlama linki e-postana gönderildi!"),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                dialogError = "Bir hata oluştu. Lütfen adresini kontrol et.";
                              });
                            } finally {
                              if (mounted) {
                                setDialogState(() => isSending = false);
                              }
                            }
                          }
                        },
                        child: isSending
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                            : const Text("Sıfırlama Linki Gönder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "İptal",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26A69A), Color(0xFF004D40)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MouseRegion(
          onHover: (event) {
            setState(() {
              _mousePosition = event.localPosition;
            });
          },
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _mousePosition = details.localPosition;
              });
            },
            child: Stack(
              children: [
                _buildAnimatedParallaxBackground(),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildAnimatedHeader(),
                        const SizedBox(height: 48.0),
                        _buildAnimatedTextField(
                          fadeAnimation: _emailFade,
                          slideAnimation: _emailSlide,
                          controller: _emailController,
                          hintText: AppLocalizations.of(context)!.emailAddress,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12.0),
                        _buildAnimatedTextField(
                          fadeAnimation: _passwordFade,
                          slideAnimation: _passwordSlide,
                          controller: _passwordController,
                          hintText: AppLocalizations.of(context)!.password,
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showPasswordResetDialog,
                              child: const Text(
                                "Şifremi Unuttum",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        _buildAnimatedLoginButton(),
                        _buildGoogleButton(),
                        _buildRegisterButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedParallaxBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final parallaxX = (_mousePosition.dx / size.width - 0.5) * 40;
        final parallaxY = (_mousePosition.dy / size.height - 0.5) * 40;

        return Stack(
          children: [
            Transform.translate(
              offset: Offset(parallaxX * 0.5, parallaxY * 0.5),
              child: Opacity(
                  opacity: 0.5, child: child!),
            ),
          ],
        );
      },
      child: const ParticleWidget(),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Column(
          children: [
            const Icon(Icons.language, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.appName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 45.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 20.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 5.0),
                  ),
                ],
              ),
            ),
            Text(
              AppLocalizations.of(context)!.appSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required Animation<double> fadeAnimation,
    required Animation<Offset> slideAnimation,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            prefixIcon: Icon(icon, color: Colors.white),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoginButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = _isLoading ? 56.0 : constraints.maxWidth;
            return AnimatedContainer(
              width: buttonWidth,
              height: 56,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_isLoading ? 28.0 : 16.0),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.5),
                ),
                onPressed: _isLoading ? null : _login,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.teal,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.login,
                          key: const ValueKey('loginText'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: TextButton(
          child: Text(
            AppLocalizations.of(context)!.dontHaveAnAccount,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                const RegisterScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: Padding(
          padding: const EdgeInsets.only(top:8.0),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 20,
              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
            ),
            label: const Text('Google ile Giriş'),
            onPressed: _isLoading ? null : _loginGoogle,
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Particles
class ParticleWidget extends StatefulWidget {
  const ParticleWidget({super.key});

  @override
  State<ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<ParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() {
        setState(() {});
      })
      ..repeat();

    for (int i = 0; i < 50; i++) {
      particles.add(Particle(random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles, random),
      child: Container(),
    );
  }
}

class Particle {
  late double x, y, radius, speed, angle;
  late Color color;

  Particle(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    radius = random.nextDouble() * 2 + 1;
    speed = random.nextDouble() * 0.001;
    angle = random.nextDouble() * 2 * pi;
    color = Colors.white.withValues(alpha: random.nextDouble() * 0.5);
  }

  update() {
    x += cos(angle) * speed;
    y += sin(angle) * speed;
    if (x < 0) x = 1.0;
    if (x > 1) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1) y = 0.0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Random random;

  ParticlePainter(this.particles, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.update();
      paint.color = particle.color;
      canvas.drawCircle(
          Offset(particle.x * size.width, particle.y * size.height),
          particle.radius,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
