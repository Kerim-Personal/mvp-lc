// lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/utils/password_strength.dart'; // <-- Yeni: Şifre gücü aracı

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  PasswordStrengthResult? _strength;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_recalcStrength);
  }

  void _recalcStrength() {
    final email = FirebaseAuth.instance.currentUser?.email;
    final local = email != null ? email.split('@').first : null;
    final pwd = _newPasswordController.text;
    final oldPwd = _currentPasswordController.text; // kullanıcı yazdıysa karşılaştır
    if (pwd.isEmpty) {
      setState(() { _strength = null; });
      return;
    }
    final result = PasswordStrength.evaluate(
      pwd,
      emailLocalPart: local,
      oldPassword: oldPwd.isNotEmpty ? oldPwd : null,
    );
    setState(() { _strength = result; });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla değiştirildi.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Mevcut şifreniz yanlış.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Yeni şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      }
      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = 'Beklenmedik bir hata oluştu.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _strengthColor(int score) {
    if (score < 30) return Colors.red;
    if (score < 50) return Colors.orange;
    if (score < 70) return Colors.amber;
    if (score < 85) return Colors.lightGreen;
    return Colors.green;
  }

  Widget _criteriaList(PasswordStrengthResult r) {
    // Tüm kriterleri gösterip karşılananları tik ile boyayalım.
    const all = [
      PasswordStrength.minLengthMsg,
      PasswordStrength.upperMsg,
      PasswordStrength.lowerMsg,
      PasswordStrength.digitMsg,
      PasswordStrength.specialMsg,
      PasswordStrength.noSpaceMsg,
      PasswordStrength.notCommonMsg,
      PasswordStrength.notSameAsOldMsg,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Güç Kriterleri', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...all.map((c) {
          final ok = !r.unmetCriteria.contains(c);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16, color: ok ? Colors.green : Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c,
                      style: TextStyle(
                        fontSize: 12,
                        color: ok ? Colors.green.shade700 : Colors.grey.shade600,
                      )),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifreyi Değiştir'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_showCurrent,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Lütfen mevcut şifrenizi girin.'
                  : null,
              onChanged: (_) => _recalcStrength(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Yeni şifre girin.';
                final r = _strength ?? PasswordStrength.evaluate(value);
                // Zorunlu kriterler: ilk 7 (eski şifre farklı olması kullanıcı opsiyonel olabilir ama yine de zorunlu kılalım)
                if (!r.allSatisfied) {
                  return 'Eksik: ${r.unmetCriteria.first}';
                }
                if (r.score < 70) {
                  return 'Şifre daha güçlü olmalı (en az Güçlü).';
                }
                return null;
              },
              onChanged: (_) => _recalcStrength(),
            ),
            if (_strength != null) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (ctx, cons) {
                  final s = _strength!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: s.score / 100,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation(_strengthColor(s.score)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(s.label, style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _strengthColor(s.score),
                          )),
                        ],
                      ),
                      _criteriaList(s),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Yeni Şifreyi Onayla',
                prefixIcon: const Icon(Icons.lock_person),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Şifreler eşleşmiyor.';
                }
                return null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : const Text('Şifreyi Güncelle',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
