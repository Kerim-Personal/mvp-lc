// lib/widgets/profile_screen/delete_account_dialog.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lingua_chat/screens/login_screen.dart';

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
        throw Exception("Kullanıcı bulunamadı veya e-posta adresi yok.");
      }

      // 1. Re-auth
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Sunucu fonksiyonunu çağır (hesabı auth + verileri siler)
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteUserAccount');
      await callable.call();

      // 3. Ek güvenlik: local oturumdaki user objesini yeniden yükle ve hala varsa silmeyi dene
      await user.reload();
      final still = FirebaseAuth.instance.currentUser;
      if (still != null) {
        try {
          await still.delete();
        } catch (_) {
          // Bazı edge-case: yetki hatası varsa göz ardı et (sunucu zaten silmiş olabilir)
        }
      }

      // 4. Oturumu kapat (özellikle cache temizliği için)
      await FirebaseAuth.instance.signOut();

      // 5. E-postanın gerçekten boşaldığından emin olmak için kısa gecikme + kontrol
      if (user.email != null) {
        try {
          await Future.delayed(const Duration(milliseconds: 400));
          final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(user.email!);
          if (methods.isNotEmpty) {
            // Kullanıcı yeniden oluşturma hemen başarısız olabilir, kullanıcıya uyarı verelim
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Hesap silme çoğaltması sürüyor, birkaç saniye sonra tekrar deneyin.'),
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
            content: Text('Hesabınız başarıyla silindi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _error = 'Girilen şifre yanlış. Lütfen tekrar deneyin.');
      } else if (e.code == 'requires-recent-login') {
        setState(() => _error = 'Lütfen tekrar giriş yapıp yeniden deneyin.');
      } else {
        setState(() => _error = 'Auth hatası: ${e.message}');
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = 'Sunucu hatası: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Beklenmedik bir hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hesabınızı Kalıcı Olarak Silin'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bu işlem geri alınamaz. Devam etmek için lütfen şifrenizi girin.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi girin.';
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
          child: const Text('İptal'),
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
              : const Text('Hesabımı Sil'),
        ),
      ],
    );
  }
}