// filepath: lib/widgets/profile_screen/delete_account_sheet.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:vocachat/screens/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> showDeleteAccountSheet(BuildContext context) async {
  final theme = Theme.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: theme.colorScheme.surface,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _acknowledged = false;
  String? _error;

  bool _isGoogleProvider = false;
  bool _isPasswordProvider = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isGoogleProvider = user.providerData.any((p) => p.providerId == 'google.com');
      _isPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || !_acknowledged || _confirmController.text.trim().toUpperCase() != 'DELETE') {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not found.');
      }

      // 1) Re-authenticate depending on provider
      if (_isPasswordProvider && _passwordController.text.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text,
        );
        await user.reauthenticateWithCredential(cred);
      } else if (_isGoogleProvider) {
        final googleSignIn = GoogleSignIn();
        var gAccount = await googleSignIn.signInSilently();
        gAccount ??= await googleSignIn.signIn();
        if (gAccount == null) {
          setState(() => _error = 'Google re-authentication cancelled.');
          return;
        }
        final gAuth = await gAccount.authentication;
        final gCred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );
        await user.reauthenticateWithCredential(gCred);
      } else {
        setState(() => _error = 'No suitable authentication method available to complete this action.');
        return;
      }

      // 2) Server: permanently delete user & related data (privileged function)
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('deleteUserAccount');
      await callable.call();

      // 3) Client: sign out (ignore errors)
      try { await FirebaseAuth.instance.signOut(); } catch (_) {}

      // 4) Navigation: clear stack and go to Login (sheet closes automatically)
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _error = 'Incorrect password.');
      } else if (e.code == 'requires-recent-login') {
        setState(() => _error = 'Please reauthenticate and try again.');
      } else if (e.code == 'user-mismatch') {
        setState(() => _error = 'Selected Google account does not match current session. Please use the same account.');
      } else {
        setState(() => _error = 'Authentication error: ${e.message}');
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = 'Server error: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Warning icon badge
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Permanently delete account',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. Your account and associated data will be permanently deleted.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),

              // Password field (only if password provider)
              if (_isPasswordProvider)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Password (email/password accounts only)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => null,
                ),

              if (_isPasswordProvider) const SizedBox(height: 12),

              // Google provider info
              if (_isGoogleProvider)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_user_rounded, color: Colors.teal),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will be asked to verify with your Google account.',
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isGoogleProvider) const SizedBox(height: 12),

              // Confirmation code field
              TextFormField(
                controller: _confirmController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Type "DELETE" to confirm',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().toUpperCase() != 'DELETE')
                    ? 'You must type DELETE to proceed.'
                    : null,
              ),
              const SizedBox(height: 8),

              // Acknowledge checkbox
              Row(
                children: [
                  Checkbox(
                    value: _acknowledged,
                    onChanged: (val) => setState(() => _acknowledged = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I understand this action cannot be undone.',
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: TextStyle(color: colorScheme.error)),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_isLoading)
                          ? null
                          : () {
                        final ok = _formKey.currentState?.validate() ?? false;
                        if (ok && _acknowledged && _confirmController.text.trim().toUpperCase() == 'DELETE') {
                          _deleteAccount();
                        } else {
                          _formKey.currentState?.validate();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
