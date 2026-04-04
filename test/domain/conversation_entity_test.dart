import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/conversation_entity.dart';

void main() {
  test('props', () {
    final a = DateTime.utc(2024);
    final c = ConversationEntity(
      id: '1',
      otherUserId: 'u',
      otherUserDisplayName: 'N',
      otherUserPhotoUrl: 'http://p',
      lastMessageText: 'hi',
      lastMessageAt: a,
      createdAt: a,
      hasUnread: true,
      unreadCount: 2,
    );
    expect(
      c,
      ConversationEntity(
        id: '1',
        otherUserId: 'u',
        otherUserDisplayName: 'N',
        otherUserPhotoUrl: 'http://p',
        lastMessageText: 'hi',
        lastMessageAt: a,
        createdAt: a,
        hasUnread: true,
        unreadCount: 2,
      ),
    );
  });
}
