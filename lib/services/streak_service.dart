// lib/services/streak_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StreakService {
  /// Günlük aktivite gerçekleştiğinde çağrılır.
  /// Mantık:
  /// - lastActivityDate bugünse: streak aynı kalır.
  /// - dünse: streak +1.
  /// - daha eskiyse veya yoksa: streak = 1.
  /// Ardından highestStreak güncellenir ve lastActivityDate serverTimestamp ile ayarlanır.
  static Future<void> updateStreakOnActivity({required String uid}) async {
    final users = FirebaseFirestore.instance.collection('users');
    final docRef = users.doc(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};

      final ts = data['lastActivityDate'];
      DateTime? last;
      if (ts is Timestamp) {
        last = ts.toDate();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final int oldStreak = (data['streak'] is int) ? data['streak'] as int : 0;
      final int oldHighest = (data['highestStreak'] is int)
          ? data['highestStreak'] as int
          : (oldStreak > 0 ? oldStreak : 0);

      int newStreak;
      if (last == null) {
        newStreak = 1;
      } else {
        final lastDay = DateTime(last.year, last.month, last.day);
        final dayDiff = today.difference(lastDay).inDays;
        if (dayDiff == 0) {
          newStreak = oldStreak > 0 ? oldStreak : 1;
        } else if (dayDiff == 1) {
          newStreak = (oldStreak > 0 ? oldStreak : 0) + 1;
        } else {
          newStreak = 1;
        }
      }

      final int newHighest = newStreak > oldHighest ? newStreak : oldHighest;

      tx.update(docRef, {
        'streak': newStreak,
        'highestStreak': newHighest,
        'lastActivityDate': FieldValue.serverTimestamp(),
      });
    });
  }
}

