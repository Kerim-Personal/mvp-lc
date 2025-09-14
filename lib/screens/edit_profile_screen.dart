// lib/screens/edit_profile_screen.dart

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/services/translation_service.dart';

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
  String _initialDisplayName = '';
  String? _avatarUrl;
  DateTime? _selectedBirthDate;
  String? _selectedNativeLanguageCode; // yeni

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
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text('Select Native Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newDisplayName = _displayNameController.text.trim();
      Map<String, dynamic> updatedData = {
        'displayName': newDisplayName,
        'username_lowercase': newDisplayName.toLowerCase(),
        'birthDate': _selectedBirthDate != null ? Timestamp.fromDate(_selectedBirthDate!) : null,
        'nativeLanguage': _selectedNativeLanguageCode ?? 'en',
        'avatarUrl': _avatarUrl,
      };

      if (newDisplayName.toLowerCase() != _initialDisplayName.toLowerCase()) {
        final isAvailable = await _authService.isUsernameAvailable(newDisplayName);
        if (!isAvailable && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This username is already taken.'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDatePicker() {
    // Cupertino style date picker
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (picked) {
              if (picked != _selectedBirthDate) {
                setState(() {
                  _selectedBirthDate = picked;
                  _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            },
            initialDateTime: _selectedBirthDate ?? DateTime(2000),
            minimumYear: 1940,
            maximumYear: DateTime.now().year,
          ),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark; // eklendi
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Save',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildAvatarSection(isDark: isDark),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _displayNameController,
              label: 'Username',
              icon: Icons.person_outline,
              isDark: isDark,
              validator: (value) => (value == null || value.trim().length < 3)
                  ? 'Username must be at least 3 characters.'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _birthDateController,
              label: 'Birth Date',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              isDark: isDark,
              onTap: _showDatePicker,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nativeLanguageController,
              label: 'Native Language',
              icon: Icons.language_outlined,
              readOnly: true,
              isDark: isDark,
              onTap: _showLanguagePicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection({required bool isDark}) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isDark ? Colors.teal.withValues(alpha: 0.2) : Colors.teal.shade100,
            child: _avatarUrl != null
                ? ClipOval(
              child: SvgPicture.network(
                _avatarUrl!,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
                width: 90,
                height: 90,
              ),
            )
                : Text(
              _initialDisplayName.isNotEmpty ? _initialDisplayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 40,
                color: isDark ? Colors.teal.shade200 : Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _generateNewAvatar,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate Random Avatar'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.teal.shade200 : Colors.teal,
            ),
          )
        ],
      ),
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
    final fill = isDark ? Colors.grey.shade800 : Colors.grey.shade50;
    final labelStyle = TextStyle(color: isDark ? Colors.white70 : null);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        prefixIcon: Icon(icon, color: isDark ? Colors.teal.shade200 : null),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fill,
      ),
      cursorColor: Colors.teal,
    );
  }

}