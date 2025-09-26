// filepath: lib/widgets/profile_screen/delete_account_sheet.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:vocachat/utils/restart_app.dart';

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
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _acknowledged = false;
  String? _error;

  @override
  void dispose() {
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

      // Server: permanently delete user & related data (privileged function)
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('deleteUserAccount');
      await callable.call();

      // Client: sign out (ignore errors)
      try { await FirebaseAuth.instance.signOut(); } catch (_) {}

      // Sheet'i kapat ve ardından uygulamayı yeniden başlat
      if (mounted) {
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        final rootContext = rootNavigator.context; // restart ve snackbar için
        rootNavigator.pop(); // bottom sheet'i kapat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          RestartWidget.restartApp(rootContext);
          Future.delayed(const Duration(milliseconds: 80), () {
            final messenger = ScaffoldMessenger.maybeOf(rootContext);
            messenger?.showSnackBar(const SnackBar(
              content: Text('Your account has been deleted successfully.'),
              backgroundColor: Colors.green,
            ));
          });
        });
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Delete Account',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. Your account and all data will be permanently deleted.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),

              // Confirmation code field
              TextFormField(
                controller: _confirmController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Type "DELETE" to confirm',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.delete_forever, color: colorScheme.error),
                ),
                validator: (v) => (v == null || v.trim().toUpperCase() != 'DELETE')
                    ? 'You must type DELETE to proceed.'
                    : null,
              ),
              const SizedBox(height: 16),

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
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

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
