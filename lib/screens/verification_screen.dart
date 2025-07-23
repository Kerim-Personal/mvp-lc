// lib/screens/verification_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user is currently signed in. Please restart the app.");

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) throw Exception("User data not found in the database.");

      final data = docSnapshot.data() as Map<String, dynamic>;
      final storedCode = data['verificationCode'] as String?;
      final expiryTimestamp = data['verificationCodeExpiresAt'] as Timestamp?;

      if (storedCode == null || expiryTimestamp == null) {
        throw Exception("Verification code not found. Please request a new one.");
      }

      if (expiryTimestamp.toDate().isBefore(DateTime.now())) {
        throw Exception("Verification code has expired. Please request a new one.");
      }

      if (storedCode == _codeController.text.trim()) {
        await docRef.update({
          'emailVerified': true,
          'verificationCode': FieldValue.delete(),
          'verificationCodeExpiresAt': FieldValue.delete(),
        });

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }
      } else {
        throw Exception("The entered code is incorrect.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _resendCode() {
    // Bu fonksiyon, yeni kod göndermek için bir Cloud Function'ı tetiklemelidir.
    // Şimdilik sadece kullanıcıya bilgi veren bir SnackBar gösteriyoruz.
    // Gerçek bir implementasyon için backend kodu gerekir.
    print("Resend code requested for ${widget.email}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code has been requested. Please check your email in a few minutes.')),
    );
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.teal),
                const SizedBox(height: 24),
                Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'A 6-digit code has been sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: '123456',
                    hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 12),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Please enter the 6-digit code.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  const SizedBox(height: 32), // Hata mesajı yokken boşluk bırakmak için
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  onPressed: _verifyCode,
                  child: const Text('Verify and Continue'),
                ),
                TextButton(
                  onPressed: _resendCode,
                  child: const Text('Resend Code', style: TextStyle(color: Colors.teal)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}