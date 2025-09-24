import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Bayrak eşleme ve bastırma setleri tek yerde tanımlandı
const _flagMap = <String,String>{
  'af':'za','sq':'al','ar':'sa','be':'by','bg':'bg','bn':'bd','ca':'ad','zh':'cn','hr':'hr','cs':'cz','da':'dk','nl':'nl','en':'gb','et':'ee','fi':'fi','fr':'fr','gl':'es','ka':'ge','de':'de','el':'gr','he':'il','hi':'in','hu':'hu','is':'is','id':'id','ga':'ie','it':'it','ja':'jp','ko':'kr','lv':'lv','lt':'lt','mk':'mk','ms':'my','mt':'mt','no':'no','fa':'ir','pl':'pl','pt':'pt','ro':'ro','ru':'ru','sk':'sk','sl':'si','es':'es','sw':'tz','sv':'se','tl':'ph','ta':'lk','th':'th','tr':'tr','uk':'ua','ur':'pk','vi':'vn','ht':'ht','gu':'in','kn':'in','te':'in','mr':'in'};
// Sadece bayrağı olmayan/sembolik diller
const _suppressFlag = {'eo','cy'};
// Hindistan grubu (aynı bayrak gösterilecek)
const _indianGroup = {'hi','gu','kn','te','mr'};

String? _countryGroup(String code){
  if (_indianGroup.contains(code)) return 'in';
  if (_flagMap.containsKey(code)) return _flagMap[code];
  return null; // sembolik ya da özel
}

class ProfileCompletionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileCompletionScreen({super.key, required this.userData});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _nativeLanguageCode;
  DateTime? _birthDate;
  bool _saving = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _cardRadius = 24.0;
  static const _primaryColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userData['displayName'] ?? '';
    _nativeLanguageCode = widget.userData['nativeLanguage'];
    final ts = widget.userData['birthDate'];
    if (ts is Timestamp) {
      _birthDate = ts.toDate();
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(_birthDate!);
    }

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _birthDateController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    // 18+ için maksimum tarih: bugünden 18 yıl öncesi
    final now = DateTime.now();
    final adultThresholdDate = DateTime(now.year - 18, now.month, now.day);

    DateTime? tempPickedDate = _birthDate ?? DateTime(2000);
    if (tempPickedDate.isAfter(adultThresholdDate)) {
      tempPickedDate = adultThresholdDate;
    }

    // Cupertino tarzı alt sayfa tarih seçici
    await showModalBottomSheet(
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
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
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
                          _birthDate = tempPickedDate;
                          _birthDateController.text =
                              DateFormat('dd/MM/yyyy').format(tempPickedDate!);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: _primaryColor,
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
                    primaryColor: _primaryColor,
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

  void _selectLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        // Kopya ve sıralama
        final langs = List<Map<String,String>>.from(TranslationService.supportedLanguages);
        langs.sort((a,b){
          final ca = _countryGroup(a['code']!);
          final cb = _countryGroup(b['code']!);
          final gc = (ca ?? 'zzz').compareTo(cb ?? 'zzz'); // null'lar sona
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
                fontSize: 20,
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
          final group = _countryGroup(code) ?? code; // sembolikler kendi koduyla ayırıcı
          if (prevGroup != null && group != prevGroup){
            tiles.add(const Divider(height: 4, thickness: 0.5));
          }
          prevGroup = group;
          final selected = code == _nativeLanguageCode;

          tiles.add(
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? _primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _Flag(code: code),
                title: Text(
                  label,
                  style: TextStyle(
                    color: selected ? _primaryColor : Colors.grey.shade800,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: _primaryColor, size: 24)
                    : null,
                onTap: () {
                  setState(() => _nativeLanguageCode = code);
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
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _birthDate == null || _nativeLanguageCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 18+ güvenlik doğrulaması
    final now = DateTime.now();
    final adultThresholdDate = DateTime(now.year - 18, now.month, now.day);
    if (_birthDate!.isAfter(adultThresholdDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be at least 18 years old.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _saving = true; });
    try {
      // 1) Display name’i boşluklardan arındır (Google’dan gelmiş olabilir)
      String desired = (_displayNameController.text).trim();
      final noSpace = desired.replaceAll(RegExp(r'\s+'), '');
      if (noSpace != desired) {
        desired = noSpace;
        _displayNameController.text = desired; // UI’yı da senkronla
      }

      // 2) Sunucuda kullanıcı adını güvenli şekilde değiştir (format + rezervasyon)
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final change = functions.httpsCallable('changeUsername');
      await change.call({'username': desired});

      // 3) Diğer profil alanlarını güncelle (displayName sunucuda güncellendi)
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await docRef.set({
        'birthDate': Timestamp.fromDate(_birthDate!),
        'nativeLanguage': _nativeLanguageCode,
        'profileCompleted': true,
        'lastActivityDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseFunctionsException catch (e) {
      String msg = 'Could not save profile.';
      if (e.code == 'already-exists') {
        msg = 'This username is already taken. Please choose another one.';
      } else if (e.code == 'invalid-argument') {
        msg = 'Invalid username format. Use only letters, numbers and _ (3-29).';
      } else if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        msg = 'Session expired. Please sign in again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.shade50,
              Colors.white,
              _primaryColor.shade50,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/appicon.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Just a few more details to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Display Name Field
                            _buildModernTextField(
                              controller: _displayNameController,
                              label: 'Display Name',
                              icon: Icons.person_outline,
                              maxLength: 29,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                                LengthLimitingTextInputFormatter(29),
                              ],
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.length < 3) return 'At least 3 characters';
                                if (t.length > 29) return 'At most 29 characters';
                                if (!RegExp(r'^[A-Za-z0-9_]{3,29}').hasMatch(t)) {
                                  return 'Use only letters, numbers and _';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Birth Date Field
                            _buildModernTextField(
                              controller: _birthDateController,
                              label: 'Date of Birth',
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                              onTap: _pickBirthDate,
                              validator: (v) => (v == null || v.isEmpty) ? 'Select your birth date' : null,
                            ),

                            const SizedBox(height: 20),

                            // Native Language Field
                            _buildLanguageSelector(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor.shade400, _primaryColor.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save and Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor.shade400),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        counterStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return InkWell(
      onTap: _selectLanguage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Native Language',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (_nativeLanguageCode != null) ...[
                        _Flag(code: _nativeLanguageCode!),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _nativeLanguageCode == null
                            ? 'Select your native language'
                            : (TranslationService.supportedLanguages.firstWhere(
                                (m) => m['code'] == _nativeLanguageCode,
                                orElse: () => {'label': _nativeLanguageCode!.toUpperCase()},
                              )['label'])!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _nativeLanguageCode == null
                              ? Colors.grey.shade500
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String code;
  final double size;

  const _Flag({required this.code, this.size = 28});

  @override
  Widget build(BuildContext context) {
    if (!_flagMap.containsKey(code) || _suppressFlag.contains(code)) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          code.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }
    return CircleFlag(_flagMap[code]!.toLowerCase(), size: size);
  }
}
