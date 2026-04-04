import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/chat_user_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockChatUserFirestoreWriter extends Mock
    implements ChatUserFirestoreWriter {}

void main() {
  late MockChatUserFirestoreWriter mockWriter;
  late ChatUserRemoteDataSource datasource;

  setUp(() {
    mockWriter = MockChatUserFirestoreWriter();
    datasource = ChatUserRemoteDataSource(writer: mockWriter);
  });

  group('ChatUserRemoteDataSource', () {
    group('ensureChatUser', () {
      test('calls writer setChatUser with id, displayName, photoUrl', () async {
        when(
          () => mockWriter.setChatUser(any(), any()),
        ).thenAnswer((_) async {});

        await datasource.ensureChatUser(
          id: 'u1',
          displayName: 'Alice',
          photoUrl: 'https://example.com/photo.jpg',
        );

        verify(
          () => mockWriter.setChatUser('u1', {
            'id': 'u1',
            'displayName': 'Alice',
            'photoUrl': 'https://example.com/photo.jpg',
          }),
        ).called(1);
      });
    });

    group('ensureChatUserById', () {
      test('does not call writer when userId is empty', () async {
        await datasource.ensureChatUserById('');

        verifyNever(() => mockWriter.setChatUser(any(), any()));
      });

      test(
        'calls writer setChatUser with id only when userId provided',
        () async {
          when(
            () => mockWriter.setChatUser(any(), any()),
          ).thenAnswer((_) async {});

          await datasource.ensureChatUserById('user1');

          verify(
            () => mockWriter.setChatUser('user1', {'id': 'user1'}),
          ).called(1);
        },
      );
    });
  });
}
