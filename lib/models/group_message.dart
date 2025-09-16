// lib/models/group_message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final Timestamp? createdAt;
  final String? senderRole;
  final bool senderIsPremium;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.createdAt,
    required this.senderRole,
    required this.senderIsPremium,
  });

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Bilinmeyen',
      senderAvatarUrl: data['senderAvatarUrl'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'],
      senderRole: data['senderRole'] as String?,
      senderIsPremium: (data['senderIsPremium'] as bool?) ?? false,
    );
  }
}

