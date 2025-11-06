// lib/screens/register_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocachat/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocachat/screens/verification_screen.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

// Flag mapping and suppression sets are defined in one place
const _flagMap = <String,String>{
  'af':'za','sq':'al','ar':'sa','be':'by','bg':'bg','bn':'bd','ca':'ad','zh':'cn','hr':'hr','cs':'cz','da':'dk','nl':'nl','en':'gb','et':'ee','fi':'fi','fr':'fr','gl':'es','ka':'ge','de':'de','el':'gr','hi':'in','hu':'hu','is':'is','id':'id','ga':'ie','it':'it','ja':'jp','ko':'kr','lv':'lv','lt':'lt','mk':'mk','ms':'my','mt':'mt','no':'no','fa':'ir','pl':'pl','pt':'pt','ro':'ro','ru':'ru','sk':'sk','sl':'si','es':'es','sw':'tz','sv':'se','tl':'ph','ta':'lk','th':'th','tr':'tr','uk':'ua','ur':'pk','vi':'vn','ht':'ht','gu':'in','kn':'in','te':'in','mr':'in'};
// Languages without a flag/symbolic only
const _suppressFlag = {'eo','cy'};
// Indian group (will show the same flag)
const _indianGroup = {'hi','gu','kn','te','mr'};

String? _countryGroup(String code){
  if (_indianGroup.contains(code)) return 'in';
  if (_flagMap.containsKey(code)) return _flagMap[code];
  return null; // symbolic or special
}

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
  bool _acceptTerms = false; // Terms of service acceptance

  // Multi-step state
  int _currentStep = 0;

  // Common style variables
  static const _primaryColor = Colors.teal;
  static const _cardRadius = 18.0;
  static const _fieldRadius = 12.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _nativeLanguageController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    // 18+ için maksimum tarih: bugünden 18 yıl öncesi
    final now = DateTime.now();
    final adultThresholdDate = DateTime(now.year - 18, now.month, now.day);

    DateTime? tempPickedDate = _selectedBirthDate ?? DateTime(2000);
    if (tempPickedDate.isAfter(adultThresholdDate)) {
      tempPickedDate = adultThresholdDate;
    }

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
                      maximumYear: adultThresholdDate.year,
                      // 18 yaşından küçük tarihleri engelle
                      maximumDate: adultThresholdDate,
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
      builder: (ctx) {
        // Copy and sort
        final langs = List<Map<String,String>>.from(TranslationService.supportedLanguages);
        langs.sort((a,b){
          final ca = _countryGroup(a['code']!);
          final cb = _countryGroup(b['code']!);
          final gc = (ca ?? 'zzz').compareTo(cb ?? 'zzz'); // nulls go to the end
          if (gc != 0) return gc;
          return a['label']!.toLowerCase().compareTo(b['label']!.toLowerCase());
        });

        String? prevGroup;
        final tiles = <Widget>[
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
        ];

        for (final m in langs){
          final code = m['code']!;
          final label = m['label']!;
          final group = _countryGroup(code) ?? code; // symbolics use their own code as a separator
          if (prevGroup != null && group != prevGroup){
            tiles.add(const Divider(height: 4, thickness: 0.5));
          }
          prevGroup = group;
          final selected = code == _selectedNativeLanguageCode;

          tiles.add(
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? _primaryColor.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: _Flag(code: code),
                title: Text(
                  label,
                  style: TextStyle(
                    color: selected ? _primaryColor.shade700 : Colors.grey.shade800,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.teal, size: 20)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedNativeLanguageCode = code;
                    _nativeLanguageController.text = label;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          );
        }

        return Container(
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
              // Language list
              Expanded(
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: tiles,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _validateUsernameAndProceed() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return; // The existing validator will already warn
    setState(() { _isLoading = true; });
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('checkUsernameAvailable');
      final res = await callable.call({'username': username});
      final data = res.data;
      bool available = false;
      String? reason;
      if (data is Map) {
        available = data['available'] == true;
        reason = data['reason']?.toString();
      }
      if (!available) {
        String msg;
        switch (reason) {
          case 'invalid_format':
            msg = 'Username can only contain a-z, 0-9 and _ (3-29 characters).';
            break;
          case 'reserved':
            msg = 'This username is reserved. Please choose another one.';
            break;
          case 'taken':
          case 'taken_legacy':
            msg = 'This username is already taken. Try another one.';
            break;
          case 'rate_limited':
            msg = 'You have made too many attempts. Please try again later.';
            break;
          default:
            msg = 'Username could not be verified. Please try again.';
        }
        if (mounted) _showError(msg);
        return; // no progression
      }
      // Suitable -> proceed to the next step
      if (mounted) setState(() { _currentStep++; });
    } catch (e) {
      if (mounted) _showError('Username check failed: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _nextStep() {
    if (_isLoading) return;
    if (_currentStep == 0) {
      if (_formKeys[0].currentState!.validate()) {
        _validateUsernameAndProceed();
      }
      return;
    }
    if (_currentStep < 2) {
      if (_formKeys[_currentStep].currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      // Check if terms are accepted before proceeding to register
      if (!_acceptTerms) {
        _showError('Please accept the Terms of Service and Privacy Policy to continue.');
        return;
      }
      _register();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _register() async {
    if (!_formKeys[2].currentState!.validate()) return;

    // Check if terms are accepted before proceeding
    if (!_acceptTerms) {
      _showError('Please accept the Terms of Service and Privacy Policy to continue.');
      return;
    }

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
    } else if (e.code == 'username-taken') {
      message = 'This username is already taken. Please choose another one.';
    } else if (e.code == 'invalid-username') {
      message = 'Invalid username format.';
    } else if (e.code == 'username-reservation-failed') {
      message = 'Username could not be reserved. Please try again.';
    } else if (e.code == 'network-request-failed') {
      message = 'Network error. Check your internet connection.';
    } else if (e.code == 'too-many-requests') {
      message = 'Too many attempts. Please wait a moment and retry.';
    } else if (e.code == 'operation-not-allowed') {
      message = 'Email/password sign up is disabled. Contact support.';
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
          // Replaced fixed-height PageView with AnimatedSize + IndexedStack so the content determines the height, reducing overflow
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: IndexedStack(
              index: _currentStep,
              children: [
                // Each step is wrapped individually to be shown with its natural height
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
          const SizedBox(height: 24),
          _buildTermsCheckbox(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, IconData icon) {
    final isUsername = label == 'Username';
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
          textInputAction: TextInputAction.next,
          autocorrect: !isUsername,
          enableSuggestions: !isUsername,
          textCapitalization: TextCapitalization.none,
          inputFormatters: isUsername
              ? <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                  LengthLimitingTextInputFormatter(29),
                ]
              : null,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) => _validateField(value, label),
          decoration: isUsername
              ? _inputDecoration('Enter a username (A-Z, a-z, 0-9, _)', icon)
              : _inputDecoration('Enter your ${label.toLowerCase()}', icon),
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

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'I have read and agree to the ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    fontSize: 13,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () async {
                    final uri = Uri.parse('https://www.codenzi.com/vocachat-privacy.html');
                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open Privacy Policy')),
                        );
                      }
                    }
                  },
                ),
                TextSpan(
                  text: ' and ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    fontSize: 13,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () async {
                    final uri = Uri.parse('https://www.codenzi.com/vocachat-term.html');
                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open Terms of Service')),
                        );
                      }
                    }
                  },
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
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
    if (fieldName == 'Email Address' && !RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    if (fieldName == 'Password' && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (fieldName == 'Username' && value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    // 18+ kuralı: doğum tarihi zorunlu ve en az 18 yaş
    if (fieldName == 'Birth Date') {
      if (_selectedBirthDate == null) return 'Birth Date is required';
      final now = DateTime.now();
      final adultThreshold = DateTime(now.year - 18, now.month, now.day);
      if (_selectedBirthDate!.isAfter(adultThreshold)) {
        return 'You must be at least 18 years old';
      }
    }
    return null;
  }

  Widget _buildNavigationButtons() {
    // Check if we can proceed to next step or create account
    bool canProceed = true;
    if (_currentStep == 2) {
      // On the last step, check if terms are accepted
      canProceed = _acceptTerms;
    }

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
              gradient: canProceed
                  ? LinearGradient(colors: [_primaryColor.shade600, _primaryColor.shade500])
                  : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade400]),
              borderRadius: BorderRadius.circular(_fieldRadius),
              boxShadow: canProceed ? [
                BoxShadow(
                  color: _primaryColor.shade600.withAlpha(75),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : [],
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: canProceed ? Colors.white : Colors.grey.shade600,
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

class _Flag extends StatelessWidget {
  final String code;
  const _Flag({required this.code});
  @override
  Widget build(BuildContext context) {
    if (!_flagMap.containsKey(code) || _suppressFlag.contains(code)) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(code.toUpperCase(), style: const TextStyle(fontSize: 10,fontWeight: FontWeight.w600,color: Colors.black87)),
      );
    }
    return CircleFlag(_flagMap[code]!.toLowerCase(), size: 28);
  }
}
