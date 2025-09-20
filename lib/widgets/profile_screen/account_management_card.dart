// lib/widgets/profile_screen/account_management_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocachat/screens/edit_profile_screen.dart';
import 'package:vocachat/services/auth_service.dart';
import 'package:vocachat/screens/change_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vocachat/widgets/profile_screen/logout_confirmation_sheet.dart';
import 'package:vocachat/widgets/profile_screen/delete_account_sheet.dart';

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
    final formattedDate = memberSince != null ? DateFormat('dd MMM yyyy', 'en_US').format(memberSince!) : 'Unknown';
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cake_rounded, color: Colors.pink),
            title: const Text('Member Since', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(formattedDate),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userId: userId)),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Added: Change Password option
          ListTile(
            leading: const Icon(Icons.password_rounded, color: Colors.deepPurple),
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
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
                title: const Text('Link Google', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: hasGoogleLinked ? const Text('Google account linked') : null,
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
                              const SnackBar(content: Text('Google account linked'), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Action cancelled'), backgroundColor: Colors.orange),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          if (!context.mounted) return;
                          final msg = e.code == 'credential-already-in-use'
                              ? 'This Google account is already linked to another user.'
                              : (e.code == 'requires-recent-login'
                                  ? 'For security, please re‑login and then try linking again.'
                                  : (e.message ?? 'Linking failed.'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: Colors.red),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unexpected error'), backgroundColor: Colors.red),
                          );
                        }
                      },
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.teal),
            title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
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
            title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () {
              showDeleteAccountSheet(context);
            },
          ),
        ],
      ),
    );
  }
}