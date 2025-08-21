// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'user';
    }

  Future<String?> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['role'] as String?) ?? 'user';
  }

  Future<bool> canBanUser(String targetUserId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUserId) return false;

    final currentRole = await getCurrentUserRole() ?? 'user';
    if (currentRole == 'admin') return true;
    if (currentRole != 'moderator') return false;

    final targetRole = await getUserRole(targetUserId) ?? 'user';
    // Moderator yalnızca normal kullanıcıları banlayabilir
    return targetRole != 'admin' && targetRole != 'moderator';
  }

  Future<void> banUser(String targetUserId, {required String reason, String? details}) async {
    final allowed = await canBanUser(targetUserId);
    if (!allowed) {
      throw Exception('Ban yetkiniz yok.');
    }
    await _firestore.collection('users').doc(targetUserId).update({
      'status': 'banned',
      'bannedReason': reason,
      'bannedDetails': details,
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': _auth.currentUser?.uid,
    });
  }
}
