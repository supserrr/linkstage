import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/message_entity.dart';

/// Firestore model for a message in chats/{chatId}/messages.
class MessageModel {
  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String chatId,
  ) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'] as Timestamp?;
    return MessageModel(
      id: doc.id,
      chatId: chatId,
      senderId: (data['sentBy'] ?? data['senderId'] ?? '').toString(),
      text: (data['message'] ?? data['text'] ?? '').toString(),
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  MessageEntity toEntity() => MessageEntity(
    id: id,
    chatId: chatId,
    senderId: senderId,
    text: text,
    createdAt: createdAt,
  );

  static Map<String, dynamic> toFirestore(String senderId, String text) {
    return {
      'sentBy': senderId,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
