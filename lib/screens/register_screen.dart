// lib/screens/register_screen.dart

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/verification_screen.dart';
import 'package:lingua_chat/l10n/app_localizations.dart'; // <-- Lokalizasyon importu
import 'package:lingua_chat/services/translation_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _nativeLanguageController = TextEditingController(); // yeni

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String? _selectedNativeLanguageCode; // yeni
  bool _isLoading = false;

  late AnimationController _entryAnimationController;
  late AnimationController _backgroundAnimationController;

  // Staggered Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Parallax effect
  Offset _mousePosition = Offset.zero;

  // Multi-step wizard state
  int _currentStep = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryAnimationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryAnimationController,
                curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic)));

    _pageController = PageController(initialPage: 0, keepPage: true);
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _nativeLanguageController.dispose(); // yeni
    _pageController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    DateTime? tempPickedDate = _selectedBirthDate ?? DateTime(2000);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).size.height / 2.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const Text('Doğum Tarihi',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBirthDate = tempPickedDate;
                          _birthDateController.text =
                              DateFormat('dd/MM/yyyy').format(tempPickedDate!);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Tamam',
                          style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (picked) {
                    tempPickedDate = picked;
                  },
                  initialDateTime: tempPickedDate,
                  minimumYear: 1940,
                  maximumYear: DateTime.now().year,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('Anadil Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: TranslationService.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final item = TranslationService.supportedLanguages[index];
                    final code = item['code']!;
                    final label = item['label']!;
                    final selected = code == _selectedNativeLanguageCode;
                    return ListTile(
                      title: Text(label),
                      trailing: selected ? const Icon(Icons.check, color: Colors.teal) : null,
                      onTap: () {
                        setState(() {
                          _selectedNativeLanguageCode = code;
                          _nativeLanguageController.text = label;
                        });
                        // Kayıtta model indirme yapılmayacak (UX için kaldırıldı)
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Step navigation helpers
  void _goToStep(int step) {
    final clamped = step.clamp(0, 2).toInt();
    if (clamped == _currentStep) return;
    setState(() => _currentStep = clamped);
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool _isValidEmail(String v) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v);
  }

  bool _validateCurrentStep() {
    // Adım bazlı temel kontroller (final doğrulama _register içinde yapılacak)
    switch (_currentStep) {
      case 0: // hesap bilgileri
        final email = _emailController.text.trim();
        final pass = _passwordController.text;
        if (email.isEmpty || !_isValidEmail(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geçerli bir e-posta girin.'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (pass.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifre en az 6 karakter olmalı.'), backgroundColor: Colors.red),
          );
          return false;
        }
        return true;
      case 1: // profil bilgileri
        final username = _usernameController.text.trim();
        final birth = _birthDateController.text.trim();
        if (username.isEmpty || username.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geçerli bir kullanıcı adı girin.'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (birth.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen doğum tarihinizi seçin.'), backgroundColor: Colors.red),
          );
          return false;
        }
        return true;
      case 2: // tercihler
        if (_selectedNativeLanguageCode == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen anadilinizi seçin.'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (_selectedGender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lütfen cinsiyetinizi seçin.'), backgroundColor: Colors.red),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _handleNext() {
    if (_validateCurrentStep()) {
      _goToStep(_currentStep + 1);
    }
  }

  void _handleBack() {
    _goToStep(_currentStep - 1);
  }

  void _register() async {
    if (!_formKey.currentState!.validate() || _selectedGender == null || _selectedNativeLanguageCode == null) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lütfen cinsiyetinizi seçin.'),
              backgroundColor: Colors.red),
        );
      }
      if (_selectedNativeLanguageCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lütfen anadilinizi seçin.'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isAvailable =
      await _authService.isUsernameAvailable(_usernameController.text.trim());

      if (!mounted) return;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bu kullanıcı adı zaten alınmış.'),
              backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userCredential = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _selectedBirthDate!,
        _selectedGender!,
        _selectedNativeLanguageCode!, // yeni
      );

      if (userCredential != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VerificationScreen(email: _emailController.text.trim()),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'username-taken') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kullanıcı adı artık alınmış. Lütfen başka bir ad deneyin.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Kayıt Hatası: ${e.message ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beklenmedik bir hata oluştu: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: MouseRegion(
          onHover: (event) => setState(() => _mousePosition = event.localPosition),
          child: GestureDetector(
            onPanUpdate: (details) =>
                setState(() => _mousePosition = details.localPosition),
            child: Stack(
              children: [
                _buildAnimatedParallaxBackground(),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildHeader(),
                              const SizedBox(height: 20.0),
                              _buildStepIndicator(),
                              const SizedBox(height: 16.0),
                              _buildStepsPager(),
                              const SizedBox(height: 16.0),
                              _buildStepperNav(),
                            ],
                          ),
                        ),
                      ),
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

  // Step indicator (3 adım)
  Widget _buildStepIndicator() {
    final steps = 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 28 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : (isDone ? Colors.white70 : Colors.white30),
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }

  // Pages container
  Widget _buildStepsPager() {
    final height = MediaQuery.of(context).size.height;
    final pagerHeight = height.clamp(520, 760) - 360; // responsive yaklaşık yükseklik
    return SizedBox(
      height: pagerHeight.toDouble(),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentStep = i),
        children: [
          _buildStepAccountInfo(),
          _buildStepProfileInfo(),
          _buildStepPreferences(),
        ],
      ),
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStepAccountInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle('Hesap Bilgileri', 'E-posta ve şifreni belirle'),
        _buildTextField(
          controller: _emailController,
          hintText: AppLocalizations.of(context)!.emailAddress,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen bir e-posta adresi girin.';
            }
            if (!_isValidEmail(value)) {
              return 'Lütfen geçerli bir e-posta adresi girin.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12.0),
        _buildTextField(
          controller: _passwordController,
          hintText: AppLocalizations.of(context)!.password,
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) =>
              (value == null || value.length < 6)
                  ? 'Şifre en az 6 karakter olmalı'
                  : null,
        ),
      ],
    );
  }

  Widget _buildStepProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle('Profil Bilgileri', 'Kullanıcı adın ve doğum tarihin'),
        _buildTextField(
          controller: _usernameController,
          hintText: AppLocalizations.of(context)!.username,
          icon: Icons.person_outline,
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return 'Lütfen bir kullanıcı adı girin';
            if (v.length < 3) return 'Kullanıcı adı en az 3 karakter olmalı';
            if (v.length > 29) return 'Kullanıcı adı en fazla 29 karakter olmalı';
            return null;
          },
        ),
        const SizedBox(height: 12.0),
        _buildTextField(
          controller: _birthDateController,
          readOnly: true,
          hintText: AppLocalizations.of(context)!.birthDate,
          icon: Icons.calendar_today_outlined,
          onTap: _showDatePicker,
          validator: (value) =>
              (value == null || value.isEmpty)
                  ? 'Lütfen doğum tarihinizi seçin'
                  : null,
        ),
      ],
    );
  }

  Widget _buildStepPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepTitle('Tercihler', 'Anadilini ve cinsiyetini seç'),
        _buildTextField(
          controller: _nativeLanguageController,
          readOnly: true,
          hintText: 'Anadil',
          icon: Icons.language_outlined,
          onTap: _showLanguagePicker,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Lütfen anadilinizi seçin'
              : null,
        ),
        const SizedBox(height: 20.0),
        Text(
          AppLocalizations.of(context)!.selectYourGender,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GenderSelectionBox(
              icon: Icons.female,
              label: AppLocalizations.of(context)!.female,
              isSelected: _selectedGender == 'Female',
              onTap: () => setState(() => _selectedGender = 'Female'),
            ),
            GenderSelectionBox(
              icon: Icons.male,
              label: AppLocalizations.of(context)!.male,
              isSelected: _selectedGender == 'Male',
              onTap: () => setState(() => _selectedGender = 'Male'),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
      ],
    );
  }

  Widget _buildStepperNav() {
    final isLast = _currentStep == 2;
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: _isLoading ? null : _handleBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Geri'),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: isLast
              ? _buildRegisterButton()
              : ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.teal.shade700,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.5),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text(
                    'İleri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.createAccount, // <-- GÜNCELLENDİ
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 38.0,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 15.0,
                color: Colors.black38,
                offset: Offset(2.0, 4.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.joinTheAdventure, // <-- GÜNCELLENDİ
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedParallaxBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        // final animationValue = _backgroundAnimationController.value; // kaldırıldı (kullanılmıyordu)
        final size = MediaQuery.of(context).size;
        final parallaxX = (_mousePosition.dx / size.width - 0.5) * 40;
        final parallaxY = (_mousePosition.dy / size.height - 0.5) * 40;

        return Stack(
          children: [
            Transform.translate(
              offset: Offset(parallaxX * 0.5, parallaxY * 0.5),
              child: Opacity(opacity: 0.5, child: child!),
            ),
          ],
        );
      },
      child: const ParticleWidget(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      ),
      validator: validator,
      onTap: onTap,
    );
  }

  Widget _buildRegisterButton() {
    return LayoutBuilder(builder: (context, constraints) {
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
          onPressed: _isLoading ? null : _register,
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
              AppLocalizations.of(context)!.register, // <-- GÜNCELLENDİ
              key: const ValueKey('registerText'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    });
  }
}

class GenderSelectionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderSelectionBox({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 130,
        height: 110,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Parçacık Efekti için Yardımcı Widget'lar
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
