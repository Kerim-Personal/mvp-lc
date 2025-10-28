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
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == userId) {
      // Kendi rolü: users doc okunabilir
      final doc = await _firestore.collection('users').doc(userId).get();
      return (doc.data()?['role'] as String?) ?? 'user';
    }
    // Başka bir kullanıcı: publicUsers üzerinden oku
    final doc = await _firestore.collection('publicUsers').doc(userId).get();
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
    // publicUsers Cloud Function ile otomatik güncellenecek; istemciden yazılamaz.
  }

  Future<void> unbanUser(String userId) async {
    final currentRole = await getCurrentUserRole();
    if (currentRole != 'admin' && currentRole != 'moderator') {
      throw Exception('Yetkiniz yok.');
    }
    await _firestore.collection('users').doc(userId).update({
      'status': 'active',
      'unbannedAt': FieldValue.serverTimestamp(),
      'unbannedBy': _auth.currentUser?.uid,
      // Ban alanlarını temizleyelim (varsa)
      'bannedReason': FieldValue.delete(),
      'bannedDetails': FieldValue.delete(),
      'bannedAt': FieldValue.delete(),
      'bannedBy': FieldValue.delete(),
    });
  }

  Future<void> updateSupportStatus(String docId, String status) async {
    final role = await getCurrentUserRole();
    if (role != 'admin' && role != 'moderator') return;
    await _firestore.collection('support').doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final role = await getCurrentUserRole();
    if (role != 'admin' && role != 'moderator') return;
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _auth.currentUser?.uid,
    });
  }

  Future<void> addSupportMessage(String ticketId, {String? text, List<String>? attachments}) async {
    final role = await getCurrentUserRole();
    if (role != 'admin' && role != 'moderator') {
      throw Exception('Yetki yok');
    }
    if ((text == null || text.trim().isEmpty) && (attachments == null || attachments.isEmpty)) {
      throw Exception('Boş mesaj');
    }
    final Map<String, dynamic> data = {
      'senderId': _auth.currentUser?.uid,
      'senderRole': role,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (text != null && text.trim().isNotEmpty) {
      data['text'] = text.trim();
    }
    if (attachments != null && attachments.isNotEmpty) {
      data['attachments'] = attachments;
    } else {
      data['attachments'] = [];
    }
    await _firestore.collection('support').doc(ticketId).collection('messages').add(data);
    await _firestore.collection('support').doc(ticketId).set({
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastStaffReplyAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addUserSupportMessage(String ticketId, {String? text, List<String>? attachments}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Auth yok');
    if ((text == null || text.trim().isEmpty) && (attachments == null || attachments.isEmpty)) {
      throw Exception('Boş mesaj');
    }
    final Map<String, dynamic> data = {
      'senderId': uid,
      'senderRole': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (text != null && text.trim().isNotEmpty) {
      data['text'] = text.trim();
    }
    if (attachments != null && attachments.isNotEmpty) {
      data['attachments'] = attachments;
    } else {
      data['attachments'] = [];
    }
    await _firestore.collection('support').doc(ticketId).collection('messages').add(data);
    await _firestore.collection('support').doc(ticketId).set({
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastUserReplyAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
