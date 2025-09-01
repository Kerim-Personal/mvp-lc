// lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/utils/password_strength.dart'; // Added: password strength helper

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
            content: Text('Your password was changed successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Your current password is incorrect.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The new password is too weak. Please choose a stronger one.';
      }
      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred.';
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
        const Text('Strength Criteria', style: TextStyle(fontWeight: FontWeight.w600)),
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
        title: const Text('Change Password'),
        centerTitle: true,
        // M3: Varsayılan renkler ve scrolledUnderElevation kullanılsın
        scrolledUnderElevation: 2,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: !_showCurrent,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showCurrent = !_showCurrent),
                        tooltip: _showCurrent ? 'Hide password' : 'Show password',
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your current password.'
                        : null,
                    onChanged: (_) => _recalcStrength(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNew,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showNew = !_showNew),
                        tooltip: _showNew ? 'Hide password' : 'Show password',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter a new password.';
                      final r = _strength ?? PasswordStrength.evaluate(value);
                      if (!r.allSatisfied) {
                        return 'Eksik: ${r.unmetCriteria.first}';
                      }
                      if (r.score < 70) {
                        return 'Password must be stronger (at least Strong).';
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
                                Text(
                                  s.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _strengthColor(s.score),
                                  ),
                                ),
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) _submit();
                    },
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        tooltip: _showConfirm ? 'Hide password' : 'Show password',
                      ),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.password_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Update Password',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
