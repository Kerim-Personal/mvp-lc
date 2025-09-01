// lib/widgets/profile_screen/account_management_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/edit_profile_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/screens/change_password_screen.dart'; // <-- YENİ: Bu satırı ekleyin
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lingua_chat/widgets/profile_screen/logout_confirmation_sheet.dart';
import 'package:lingua_chat/widgets/profile_screen/delete_account_sheet.dart';

class AccountManagementCard extends StatelessWidget {
  final DateTime? memberSince;
  final String userId;
  final AuthService authService;

  const AccountManagementCard({
    super.key,
    required this.memberSince,
    required this.userId,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = memberSince != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(memberSince!) : 'Bilinmiyor';
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cake_rounded, color: Colors.pink),
            title: const Text('Üyelik Tarihi', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(formattedDate),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userId: userId)),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // YENİ: Şifre Değiştirme Seçeneği Eklendi
          ListTile(
            leading: const Icon(Icons.password_rounded, color: Colors.deepPurple),
            title: const Text('Şifreyi Değiştir', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snap) {
              final hasGoogleLinked = snap.data?.providerData.any((p) => p.providerId == 'google.com') ?? false;
              return ListTile(
                leading: const Icon(Icons.link_rounded, color: Colors.green),
                title: const Text('Google\'ı Bağla', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: hasGoogleLinked ? const Text('Google hesabı bağlı') : null,
                trailing: hasGoogleLinked ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: hasGoogleLinked
                    ? null
                    : () async {
                        try {
                          final ok = await authService.linkCurrentUserWithGoogle();
                          if (!context.mounted) return;
                          if (ok) {
                            await FirebaseAuth.instance.currentUser?.reload();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google hesabı bağlandı'), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('İşlem iptal edildi'), backgroundColor: Colors.orange),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          if (!context.mounted) return;
                          final msg = e.code == 'credential-already-in-use'
                              ? 'Bu Google hesabı başka bir kullanıcıyla ilişkili.'
                              : (e.code == 'requires-recent-login'
                                  ? 'Güvenlik için lütfen tekrar giriş yapıp ardından bağlamayı deneyin.'
                                  : (e.message ?? 'Bağlama başarısız.'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: Colors.red),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Beklenmedik hata'), backgroundColor: Colors.red),
                          );
                        }
                      },
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.teal),
            title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              final confirmed = await showLogoutConfirmationSheet(context);

              if (confirmed == true) {
                await authService.signOut();
              }
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: const Text('Hesabı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () {
              showDeleteAccountSheet(context);
            },
          ),
        ],
      ),
    );
  }
}