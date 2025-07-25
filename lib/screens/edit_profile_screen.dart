// lib/screens/edit_profile_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/services/auth_service.dart';

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
  DateTime? _selectedBirthDate;
  String? _selectedGender;

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

        if (data['birthDate'] != null) {
          _selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
          _birthDateController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
        }

        _selectedGender = data['gender'];
        _nativeLanguageController.text = data['nativeLanguage'] ?? '';
      }
    } catch (e) {
      // Hata yönetimi
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        'gender': _selectedGender,
        'nativeLanguage': _nativeLanguageController.text.trim(),
      };

      if (newDisplayName.toLowerCase() != _initialDisplayName.toLowerCase()) {
        final isAvailable = await _authService.isUsernameAvailable(newDisplayName);
        if (!isAvailable && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu kullanıcı adı zaten alınmış.'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenemedi: $e'), backgroundColor: Colors.red),
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
    // Cupertino stili tarih seçici
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Kaydet',
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
            _buildAvatarSection(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _displayNameController,
              label: 'Kullanıcı Adı',
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.trim().length < 3)
                  ? 'Kullanıcı adı en az 3 karakter olmalı.'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _birthDateController,
              label: 'Doğum Tarihi',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: _showDatePicker,
            ),
            const SizedBox(height: 24),
            _buildGenderSelection(), // <-- DEĞİŞİKLİK BURADA
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nativeLanguageController,
              label: 'Anadil',
              icon: Icons.language_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal.shade100,
            child: Text(
              _initialDisplayName.isNotEmpty ? _initialDisplayName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.teal),
                onPressed: () {
                  // TODO: Profil fotoğrafı yükleme fonksiyonu
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  // YENİ: Cinsiyet seçimi için daha modern bir arayüz
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cinsiyet',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GenderSelectionBox(
                icon: Icons.female,
                label: 'Kadın',
                isSelected: _selectedGender == 'Female',
                onTap: () => setState(() => _selectedGender = 'Female'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GenderSelectionBox(
                icon: Icons.male,
                label: 'Erkek',
                isSelected: _selectedGender == 'Male',
                onTap: () => setState(() => _selectedGender = 'Male'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// YENİ: Cinsiyet seçim kutucuğu widget'ı
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.teal : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.teal.shade800 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}