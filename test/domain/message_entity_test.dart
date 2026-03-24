import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/message_entity.dart';

void main() {
  test('props', () {
    final t = DateTime.utc(2025);
    final m = MessageEntity(
      id: '1',
      chatId: 'c',
      senderId: 's',
      text: 'hi',
      createdAt: t,
    );
    expect(
      m,
      MessageEntity(
        id: '1',
        chatId: 'c',
        senderId: 's',
        text: 'hi',
        createdAt: t,
      ),
    );
  });
}
