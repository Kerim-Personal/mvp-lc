// lib/screens/register_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    DateTime? tempPickedDate = _selectedBirthDate ?? DateTime(2000);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).size.height / 2.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const Text('Date of Birth',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBirthDate = tempPickedDate;
                          _birthDateController.text =
                              DateFormat('dd/MM/yyyy').format(tempPickedDate!);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Done',
                          style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (picked) {
                    tempPickedDate = picked;
                  },
                  initialDateTime: tempPickedDate,
                  minimumYear: 1940,
                  maximumYear: DateTime.now().year,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate() || _selectedGender == null) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your gender.'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isAvailable =
      await _authService.isUsernameAvailable(_usernameController.text.trim());

      if (!mounted) return;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This username is already taken.'),
              backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userCredential = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
        _selectedBirthDate!,
        _selectedGender!,
      );

      if (userCredential != null) {
        // Kayıt başarılı, kullanıcıyı yeni doğrulama ekranına yönlendir.
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VerificationScreen(email: _emailController.text.trim()),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Registration Error: ${e.message ?? "An unknown error occurred"}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
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
      appBar: AppBar(
          title: const Text('Register'),
          backgroundColor: Colors.teal,
          elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 35.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.teal)),
                const SizedBox(height: 40.0),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(32.0)))),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address.';
                    }
                    final bool emailValid = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value);
                    if (!emailValid) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(32.0)))),
                  validator: (value) =>
                  (value == null || value.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(32.0)))),
                  validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter a username'
                      : null,
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0))),
                  ),
                  onTap: _showDatePicker,
                  validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please select your date of birth'
                      : null,
                ),
                const SizedBox(height: 20.0),
                const Text('Select Gender',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GenderSelectionBox(
                        icon: Icons.female,
                        label: 'Female',
                        isSelected: _selectedGender == 'Female',
                        onTap: () => setState(() => _selectedGender = 'Female')),
                    GenderSelectionBox(
                        icon: Icons.male,
                        label: 'Male',
                        isSelected: _selectedGender == 'Male',
                        onTap: () => setState(() => _selectedGender = 'Male')),
                  ],
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding:
                      const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0))),
                  onPressed: _register,
                  child: const Text('Register',
                      style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  child: const Text('Already have an account? Log In',
                      style: TextStyle(color: Colors.teal)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GenderSelectionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderSelectionBox(
      {super.key,
        required this.icon,
        required this.label,
        required this.isSelected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
            color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey[300]!,
                width: 2.5)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: isSelected ? Colors.teal : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.teal : Colors.grey[800],
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}