// lib/screens/verification_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/login_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isSending = false;
  String? _errorMessage;
  bool _checking = false; // yeni: doğrulama kontrol state

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Verification email sent to ${widget.email}'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception("No user is currently signed in.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to send verification email. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _checkIfVerified() async {
    setState(() { _checking = true; });
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        // Kök route'a dön (AuthWrapper yeniden değerlendirilir ve RootScreen açılır)
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Henüz doğrulanmamış. Lütfen e-postayı kontrol edin.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kontrol sırasında hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                'Check Your Email',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a confirmation link to\n${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isSending
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: _resendVerificationEmail,
                icon: const Icon(Icons.send),
                label: const Text('Resend Verification Link'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _checking ? null : _checkIfVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: _checking
                    ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2))
                    : const Text('E-postayı Doğruladım'),
              ),
              TextButton(
                child: const Text('Back to Login',
                    style: TextStyle(color: Colors.teal)),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}