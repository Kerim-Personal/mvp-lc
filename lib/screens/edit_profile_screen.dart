// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoading = false;
  String _initialDisplayName = '';

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (userDoc.exists) {
      final displayName = userDoc.data()?['displayName'] ?? '';
      setState(() {
        _initialDisplayName = displayName;
        _displayNameController.text = displayName;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newDisplayName = _displayNameController.text.trim();

      if (newDisplayName.toLowerCase() != _initialDisplayName.toLowerCase()) {
        final isAvailable = await _authService.isUsernameAvailable(newDisplayName);
        if (!isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu kullanıcı adı zaten alınmış.'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'displayName': newDisplayName,
        'username_lowercase': newDisplayName.toLowerCase(),
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if(mounted) {
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

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Kullanıcı adı en az 3 karakter olmalı.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}