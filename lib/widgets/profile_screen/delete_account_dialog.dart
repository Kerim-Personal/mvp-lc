// lib/widgets/profile_screen/delete_account_dialog.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:vocachat/screens/login_screen.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not found or email missing.");
      }

      // 1. Re-auth
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Call server function (deletes auth user + related data)
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteUserAccount');
      await callable.call();

      // 3. Extra safety: reload local user; if still present attempt client-side delete
      await user.reload();
      final still = FirebaseAuth.instance.currentUser;
      if (still != null) {
        try {
          await still.delete();
        } catch (_) {
          // Edge-case: ignore perms error (server may have already deleted the user)
        }
      }

      // 4. Sign out (cache/token cleanup)
      await FirebaseAuth.instance.signOut();

      // 5. Short delay + check methods to ensure email really cleared
      if (user.email != null) {
        try {
          await Future.delayed(const Duration(milliseconds: 400));
          final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(user.email!);
          if (methods.isNotEmpty) {
            // Replication delay: inform user to retry later
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Account deletion replication in progress, try again in a few seconds.'),
                backgroundColor: Colors.orange,
              ));
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _error = 'Incorrect password. Please try again.');
      } else if (e.code == 'requires-recent-login') {
        setState(() => _error = 'Please sign in again and retry.');
      } else {
        setState(() => _error = 'Auth error: ${e.message}');
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = 'Server error: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Permanently Delete Your Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action is irreversible. Please enter your password to continue.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  return null;
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Delete My Account'),
        ),
      ],
    );
  }
}