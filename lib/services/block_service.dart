// lib/services/block_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mevcut kullanıcının hedef kullanıcıyı engellemesini sağlar.
  Future<void> blockUser({required String currentUserId, required String targetUserId}) async {
    if (currentUserId == targetUserId) return;
    final docRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(targetUserId);
    await docRef.set({
      'blockedAt': FieldValue.serverTimestamp(),
      'targetUserId': targetUserId,
    }, SetOptions(merge: true));
  }

  /// Mevcut kullanıcının hedef kullanıcının engelini kaldırmasını sağlar.
  Future<void> unblockUser({required String currentUserId, required String targetUserId}) async {
    final docRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(targetUserId);
    await docRef.delete();
  }

  /// İki kullanıcı arasında etkileşime izin verilip verilmediğini döner.
  /// currentUser hedefi engellediyse veya hedef currentUser'ı engellediyse false döner.
  Future<bool> isInteractionAllowed(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return true;

    final myBlockDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(targetUserId)
        .get();

    final theirBlockDoc = await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('blockedUsers')
        .doc(currentUserId)
        .get();

    final blockedByMe = myBlockDoc.exists;
    final blockedMe = theirBlockDoc.exists;
    return !(blockedByMe || blockedMe);
  }
}
