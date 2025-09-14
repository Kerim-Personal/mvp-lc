import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/services/translation_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileCompletionScreen({super.key, required this.userData});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _nativeLanguageCode; // ISO code
  DateTime? _birthDate;
  bool _saving = false;

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
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _selectLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Anadil Seç')),
            ...TranslationService.supportedLanguages.map((m) {
              final code = m['code']!;
              final label = m['label']!;
              final selected = code == _nativeLanguageCode;
              return ListTile(
                title: Text(label),
                trailing: selected ? const Icon(Icons.check, color: Colors.teal) : null,
                onTap: () {
                  setState(() { _nativeLanguageCode = code; });
                  Navigator.pop(context);
                },
              );
            })
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _birthDate == null || _nativeLanguageCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _saving = true; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final displayName = _displayNameController.text.trim();
      await docRef.update({
        'displayName': displayName,
        'username_lowercase': displayName.toLowerCase(),
        'birthDate': Timestamp.fromDate(_birthDate!),
        'nativeLanguage': _nativeLanguageCode,
        'profileCompleted': true,
        'lastActivityDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilemedi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilini Tamamla'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Hoş geldin! Devam etmeden önce birkaç bilgi:'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _displayNameController,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: 'Görünen Ad'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 3) return 'En az 3 karakter';
                    if (t.length > 29) return 'En fazla 29 karakter';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Doğum Tarihi'),
                  onTap: _pickBirthDate,
                  validator: (v) => (v==null||v.isEmpty)?'Seçiniz':null,
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _selectLanguage,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Anadil'),
                    child: Text(
                      _nativeLanguageCode == null
                        ? 'Seçiniz'
                        : TranslationService.supportedLanguages.firstWhere((m)=>m['code']==_nativeLanguageCode)['label']!,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saving? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(color: Colors.white,strokeWidth:2)) : const Text('Kaydet ve Devam Et'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

