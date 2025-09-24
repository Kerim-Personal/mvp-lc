// lib/screens/edit_profile_screen.dart

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:vocachat/services/auth_service.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Bayrak ve gruplama (diğer ekranlarla uyumlu)
const _flagMapEdit = <String,String>{
  'af':'za','sq':'al','ar':'sa','be':'by','bg':'bg','bn':'bd','ca':'ad','zh':'cn','hr':'hr','cs':'cz','da':'dk','nl':'nl','en':'gb','et':'ee','fi':'fi','fr':'fr','gl':'es','ka':'ge','de':'de','el':'gr','he':'il','hi':'in','hu':'hu','is':'is','id':'id','ga':'ie','it':'it','ja':'jp','ko':'kr','lv':'lv','lt':'lt','mk':'mk','ms':'my','mt':'mt','no':'no','fa':'ir','pl':'pl','pt':'pt','ro':'ro','ru':'ru','sk':'sk','sl':'si','es':'es','sw':'tz','sv':'se','tl':'ph','ta':'lk','th':'th','tr':'tr','uk':'ua','ur':'pk','vi':'vn','ht':'ht','gu':'in','kn':'in','te':'in','mr':'in'};
const _suppressFlagEdit = {'eo','cy'}; // sembolik bayraksız
const _indianGroupEdit = {'hi','gu','kn','te','mr'};
String? _countryGroupEdit(String code){
  if (_indianGroupEdit.contains(code)) return 'in';
  if (_flagMapEdit.containsKey(code)) return _flagMapEdit[code];
  return null;
}
Widget _flagChip(String code){
  if(!_flagMapEdit.containsKey(code) || _suppressFlagEdit.contains(code)){
    return Container(
      width: 28,height:28,
      decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(code.toUpperCase(), style: const TextStyle(fontSize:10,fontWeight: FontWeight.w600,color: Colors.black87)),
    );
  }
  return CircleFlag(_flagMapEdit[code]!, size: 28);
}

class EditProfileScreen extends StatefulWidget {
  final String userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _displayNameController;
  late TextEditingController _birthDateController;
  late TextEditingController _nativeLanguageController;

  bool _isLoading = true;
  bool _isSaving = false;
  String _initialDisplayName = '';
  String? _avatarUrl;
  DateTime? _selectedBirthDate;
  String? _selectedNativeLanguageCode;

  // Ortak stil değişkenleri
  static const _primaryColor = Colors.teal;
  static const _cardRadius = 18.0;
  static const _fieldRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _birthDateController = TextEditingController();
    _nativeLanguageController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _initialDisplayName = data['displayName'] ?? '';
        _displayNameController.text = _initialDisplayName;
        _avatarUrl = data['avatarUrl'];

        if (data['birthDate'] != null) {
          _selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
          _birthDateController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
        }

        final nl = data['nativeLanguage'];
        if (nl is String && nl.isNotEmpty) {
          _selectedNativeLanguageCode = nl;
        } else {
          _selectedNativeLanguageCode = 'en';
        }
        _nativeLanguageController.text = _languageLabelFor(_selectedNativeLanguageCode!);
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _languageLabelFor(String code) {
    return TranslationService.supportedLanguages.firstWhere(
      (m) => m['code'] == code,
      orElse: () => const {'code': 'en', 'label': 'English'},
    )['label']!;
  }

  void _generateNewAvatar() {
    final random = Random().nextInt(10000).toString();
    setState(() {
      _avatarUrl = 'https://api.dicebear.com/8.x/micah/svg?seed=$random';
    });
  }

  void _showLanguagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langs = List<Map<String,String>>.from(TranslationService.supportedLanguages);
    // Gruplu + alfabetik sıralama
    langs.sort((a,b){
      final ca = _countryGroupEdit(a['code']!);
      final cb = _countryGroupEdit(b['code']!);
      final gc = (ca ?? 'zzz').compareTo(cb ?? 'zzz');
      if (gc!=0) return gc;
      return a['label']!.toLowerCase().compareTo(b['label']!.toLowerCase());
    });

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx){
        String? prevGroup;
        final items = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20,16,20,8),
            child: Text('Select Native Language', style: TextStyle(fontSize:16,fontWeight: FontWeight.w700,color: isDark? Colors.white: Colors.grey.shade800)),
          ),
          Divider(height:1,color: isDark? Colors.grey.shade700: Colors.grey.shade200)
        ];
        for(final m in langs){
          final code = m['code']!;
          final label = m['label']!;
          final group = _countryGroupEdit(code) ?? code; // sembolik -> kendi kodu ayırıcı etkisi
          if(prevGroup!=null && group!=prevGroup){
            items.add(Divider(height: 6, thickness: 0.6, color: isDark? Colors.grey.shade700: Colors.grey.shade200));
          }
          prevGroup = group;
          final selected = code == _selectedNativeLanguageCode;
          items.add(ListTile(
            leading: _flagChip(code),
            title: Text(label, style: TextStyle(fontWeight: selected? FontWeight.w600: FontWeight.w500, color: selected? (isDark? Colors.white: _primaryColor.shade700):(isDark? Colors.white70: Colors.grey.shade800))),
            trailing: selected? Icon(Icons.check_circle, size:20, color: isDark? Colors.white: _primaryColor.shade600): null,
            onTap: (){
              setState(() {
                _selectedNativeLanguageCode = code;
                _nativeLanguageController.text = label;
              });
              Navigator.pop(ctx);
            },
          ));
        }
        return SafeArea(child: SizedBox(
          height: MediaQuery.of(context).size.height*0.7,
          child: ListView(children: items),
        ));
      }
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newDisplayName = _displayNameController.text.trim();
      final usernameChanged = newDisplayName.toLowerCase() != _initialDisplayName.toLowerCase();

      // Önce kullanıcı adı değişecekse atomik sunucu çağrısı yap
      if (usernameChanged) {
        // İsteğe bağlı ön kontrol (kullanıcı dostu mesaj için)
        final isAvailable = await _authService.isUsernameAvailable(newDisplayName);
        if (!isAvailable && mounted) {
          _showError('This username is already taken.');
          setState(() => _isSaving = false);
          return;
        }
        // Eski usernames kaydını temizleyip yenisini set eden sunucu fonksiyonu
        try {
          final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
          final callable = functions.httpsCallable('changeUsername');
          await callable.call({'username': newDisplayName});
        } on FirebaseFunctionsException catch (e) {
          String msg = 'Username change failed.';
          if (e.code == 'already-exists') msg = 'This username is already taken.';
          if (e.code == 'invalid-argument') msg = 'Invalid username format.';
          if (mounted) {
            _showError(msg);
            setState(() => _isSaving = false);
          }
          return;
        } catch (_) {
          if (mounted) {
            _showError('Username change failed.');
            setState(() => _isSaving = false);
          }
          return;
        }
      }

      // Diğer profil alanlarını güncelle (kullanıcı adı alanlarını sunucu zaten güncelledi)
      final Map<String, dynamic> updatedData = {
        // 'displayName' ve 'username_lowercase' burada kasıtlı olarak yok
        'birthDate': _selectedBirthDate != null ? Timestamp.fromDate(_selectedBirthDate!) : null,
        'nativeLanguage': _selectedNativeLanguageCode ?? 'en',
        'avatarUrl': _avatarUrl,
      };

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updatedData);

      if (mounted) {
        _showSuccess('Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Profile update failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_cardRadius),
              topRight: Radius.circular(_cardRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 100 : 25),
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
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
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
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Select Birth Date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey.shade800,
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
                          color: isDark ? Colors.white : _primaryColor.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, height: 1),
              // Date picker
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    primaryColor: isDark ? Colors.white : Colors.teal,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  child: Container(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _birthDateController.dispose();
    _nativeLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                : [_primaryColor.shade600, _primaryColor.shade400, Colors.cyan.shade300],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isDark ? Colors.white : Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildContent(isDark),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
                    : [Colors.white, Colors.white.withAlpha(230)]
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(100)
                      : Colors.white.withAlpha(75),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: isDark ? Colors.white : _primaryColor.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white : _primaryColor.shade600,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(100)
                : Colors.black.withAlpha(25),
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
            _buildAvatarSection(isDark),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _displayNameController,
              label: 'Username',
              icon: Icons.person_outline,
              isDark: isDark,
              validator: (value) => (value == null || value.trim().length < 3)
                  ? 'Username must be at least 3 characters.'
                  : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _birthDateController,
              label: 'Birth Date',
              icon: Icons.calendar_today_outlined,
              isDark: isDark,
              readOnly: true,
              onTap: _showDatePicker,
              // 18+ doğrulaması
              validator: (_) {
                if (_selectedBirthDate == null) return 'Birth Date is required.';
                final now = DateTime.now();
                final adultThreshold = DateTime(now.year - 18, now.month, now.day);
                if (_selectedBirthDate!.isAfter(adultThreshold)) {
                  return 'You must be at least 18 years old.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nativeLanguageController,
              label: 'Native Language',
              icon: Icons.translate_outlined,
              isDark: isDark,
              readOnly: true,
              onTap: _showLanguagePicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF3C3C3C), const Color(0xFF2C2C2C)]
                  : [_primaryColor.shade200, _primaryColor.shade400],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(150)
                    : _primaryColor.shade200.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _avatarUrl != null
              ? ClipOval(
                  child: SvgPicture.network(
                    _avatarUrl!,
                    placeholderBuilder: (context) => CircularProgressIndicator(
                      color: isDark ? Colors.white : _primaryColor.shade600,
                      strokeWidth: 2,
                    ),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    _initialDisplayName.isNotEmpty ? _initialDisplayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : _primaryColor.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDark ? const Color(0xFF3C3C3C) : _primaryColor.shade200
            ),
          ),
          child: TextButton.icon(
            onPressed: _generateNewAvatar,
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : _primaryColor.shade600,
              size: 18
            ),
            label: Text(
              'Generate New Avatar',
              style: TextStyle(
                color: isDark ? Colors.white : _primaryColor.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    final isLanguage = label == 'Native Language';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 13
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3C3C3C) : _primaryColor.shade50,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: isLanguage && _selectedNativeLanguageCode != null
                  ? Center(child: _flagChip(_selectedNativeLanguageCode!))
                  : Icon(icon, color: isDark ? Colors.white : _primaryColor.shade600, size: 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade200,
                  width: 1.5
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_fieldRadius),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : _primaryColor.shade600,
                  width: 2
                ),
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
              fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            cursorColor: isDark ? Colors.white : _primaryColor.shade600,
          ),
      ],
    );
  }

}
