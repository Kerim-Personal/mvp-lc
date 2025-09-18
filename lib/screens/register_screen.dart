// lib/screens/register_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/verification_screen.dart';
import 'package:lingua_chat/services/translation_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _nativeLanguageController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedNativeLanguageCode;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Multi-step state
  int _currentStep = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  // Ortak stil değişkenleri
  static const _primaryColor = Colors.teal;
  static const _cardRadius = 18.0;
  static const _fieldRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _nativeLanguageController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    DateTime? tempPickedDate = _selectedBirthDate ?? DateTime(2000);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_cardRadius),
              topRight: Radius.circular(_cardRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Select Birth Date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBirthDate = tempPickedDate;
                          _birthDateController.text =
                              DateFormat('dd/MM/yyyy').format(tempPickedDate!);
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: _primaryColor.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade200, height: 1),
              // Date picker
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                    primaryColor: Colors.teal,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      onDateTimeChanged: (picked) {
                        tempPickedDate = picked;
                      },
                      initialDateTime: tempPickedDate,
                      minimumYear: 1940,
                      maximumYear: DateTime.now().year,
                      backgroundColor: Colors.white,
                    ),
                  ),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_cardRadius),
            topRight: Radius.circular(_cardRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Native Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            // Language list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: TranslationService.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final item = TranslationService.supportedLanguages[index];
                  final code = item['code']!;
                  final label = item['label']!;
                  final selected = code == _selectedNativeLanguageCode;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? _primaryColor.shade50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: selected ? _primaryColor.shade700 : Colors.grey.shade800,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      trailing: selected
                        ? Icon(Icons.check_circle, color: _primaryColor.shade600, size: 20)
                        : null,
                      onTap: () {
                        setState(() {
                          _selectedNativeLanguageCode = code;
                          _nativeLanguageController.text = label;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKeys[_currentStep].currentState!.validate()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _register();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _register() async {
    if (!_formKeys[2].currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _selectedBirthDate!,
        _selectedNativeLanguageCode!,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(email: _emailController.text.trim()),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _handleAuthError(e);
    } catch (e) {
      if (!mounted) return;
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = 'Registration failed. Please try again.';
    if (e.code == 'email-already-in-use') {
      message = 'This email is already registered. Please use a different email.';
    } else if (e.code == 'weak-password') {
      message = 'Password is too weak. Please choose a stronger password.';
    } else if (e.code == 'invalid-email') {
      message = 'Please enter a valid email address.';
    }
    _showError(message);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryColor.shade600, _primaryColor.shade400, Colors.cyan.shade300],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical - keyboardHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: isKeyboardOpen ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    if (isKeyboardOpen)
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02)
                    else ...[
                      _buildLogo(),
                      const SizedBox(height: 1),
                    ],
                    _buildStepIndicator(),
                    const SizedBox(height: 16),
                    _buildRegisterCard(isKeyboardOpen),
                    if (!isKeyboardOpen) ...[
                      const SizedBox(height: 18),
                      _buildLoginLink(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/splash.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                    ? Colors.white
                    : isActive
                      ? Colors.white
                      : Colors.transparent,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isCompleted
                  ? Icon(Icons.check, size: 14, color: _primaryColor.shade600)
                  : Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? _primaryColor.shade600 : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
              ),
              if (index < 2) ...[
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 2,
                  color: index < _currentStep ? Colors.white : Colors.white.withAlpha(100),
                ),
                const SizedBox(width: 8),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRegisterCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle(),
          SizedBox(height: isCompact ? 12 : 16),
          SizedBox(
            height: isCompact ? 220 : 260,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepTitle() {
    final titles = [
      'Account Information',
      'Personal Details',
      'Language Preference'
    ];

    return Text(
      titles[_currentStep],
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeys[0],
      child: Column(
        children: [
          _buildTextField('Username', _usernameController, TextInputType.text, Icons.person_outline),
          const SizedBox(height: 12),
          _buildTextField('Email Address', _emailController, TextInputType.emailAddress, Icons.email_outlined),
          const SizedBox(height: 12),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeys[1],
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.person_pin,
            size: 48,
            color: _primaryColor.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeys[2],
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.translate,
            size: 48,
            color: _primaryColor.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'What\'s your native language?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildLanguageField(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) => _validateField(value, label),
          decoration: _inputDecoration('Enter your ${label.toLowerCase()}', icon),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) => _validateField(value, 'Password'),
          decoration: _inputDecoration('Enter your password', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey.shade500,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _birthDateController,
          readOnly: true,
          onTap: _showDatePicker,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) => _validateField(value, 'Birth Date'),
          decoration: _inputDecoration('Select your birth date', Icons.calendar_today_outlined),
        ),
      ],
    );
  }

  Widget _buildLanguageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Native Language',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _nativeLanguageController,
          readOnly: true,
          onTap: _showLanguagePicker,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) => _validateField(value, 'Native Language'),
          decoration: _inputDecoration('Select your native language', Icons.translate_outlined),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryColor.shade50,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: _primaryColor.shade600, size: 16),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: _primaryColor.shade600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (fieldName == 'Email Address' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    if (fieldName == 'Password' && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (fieldName == 'Username' && value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(_fieldRadius),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          flex: _currentStep > 0 ? 1 : 2,
          child: Container(
            height: 44,
            margin: EdgeInsets.only(left: _currentStep > 0 ? 8 : 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryColor.shade600, _primaryColor.shade500]),
              borderRadius: BorderRadius.circular(_fieldRadius),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.shade600.withAlpha(75),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentStep < 2 ? 'Next' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.white.withAlpha(230),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
