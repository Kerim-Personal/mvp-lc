// filepath: lib/widgets/profile_screen/logout_confirmation_sheet.dart
import 'package:flutter/material.dart';

/// Modern bir "Çıkış Yap" onay alt sayfası gösterir.
/// true -> Onaylandı, false/null -> İptal/dismiss
Future<bool?> showLogoutConfirmationSheet(BuildContext context) {
  final theme = Theme.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: false,
    showDragHandle: false,
    backgroundColor: theme.colorScheme.surface,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              // Icon badge
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
                    Icons.logout_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Çıkış yapılsın mı?',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu cihazdaki oturum kapanacak. Hesabınız silinmez.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Çıkış'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Alt boşluk için güvenli alan marjı
            ],
          ),
        ),
      );
    },
  );
}
