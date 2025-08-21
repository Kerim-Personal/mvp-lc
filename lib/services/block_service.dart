// lib/services/block_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mevcut kullanıcının hedef kullanıcıyı engellemesini sağlar.
  Future<void> blockUser({required String currentUserId, required String targetUserId}) async {
    if (currentUserId == targetUserId) return;
    final userRef = _firestore.collection('users').doc(currentUserId);
    await userRef.update({
      'blockedUsers': FieldValue.arrayUnion([targetUserId])
    });
  }

  /// Mevcut kullanıcının hedef kullanıcının engelini kaldırmasını sağlar.
  Future<void> unblockUser({required String currentUserId, required String targetUserId}) async {
    final userRef = _firestore.collection('users').doc(currentUserId);
    await userRef.update({
      'blockedUsers': FieldValue.arrayRemove([targetUserId])
    });
  }

  /// İki kullanıcı arasında etkileşime izin verilip verilmediğini döner.
  /// currentUser hedefi engellediyse veya hedef currentUser'ı engellediyse false döner.
  Future<bool> isInteractionAllowed(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return true;
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final targetUserDoc = await _firestore.collection('users').doc(targetUserId).get();

    final List<dynamic> myBlocked = (currentUserDoc.data()?['blockedUsers'] as List<dynamic>?) ?? const [];
    final List<dynamic> theirBlocked = (targetUserDoc.data()?['blockedUsers'] as List<dynamic>?) ?? const [];

    final blockedByMe = myBlocked.contains(targetUserId);
    final blockedMe = theirBlocked.contains(currentUserId);
    return !(blockedByMe || blockedMe);
  }
}

