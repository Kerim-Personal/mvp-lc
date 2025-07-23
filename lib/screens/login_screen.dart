// lib/screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/screens/home_screen.dart';
import 'package:lingua_chat/screens/register_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/screens/verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && mounted) {
        // Giriş başarılıysa ana ekrana yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;

      if (e.code == 'email-not-verified') {
        // Kullanıcıyı doğrulama ekranına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationScreen(email: _emailController.text.trim()),
          ),
        );
        // Hata mesajı göstermeden işlemi bitiriyoruz çünkü yeni bir ekrana yönlendirdik.
        //setState'in finally içinde çağrılması yeterli.
        return; // Yönlendirme sonrası başka işlem yapmaması için
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Invalid email or password.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          // Klavye açıldığında taşmayı önler
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'LinguaChat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 45.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 48.0),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                onPressed: _login,
                child: const Text('Log In',
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                child: const Text('Don\'t have an account? Register',
                    style: TextStyle(color: Colors.teal)),
                onPressed: () {
                  // Kayıt olma ekranına yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
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