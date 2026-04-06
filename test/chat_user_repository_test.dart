import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/repositories/chat_user_repository_impl.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/data/datasources/chat_user_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockChatUserRemoteDataSource extends Mock
    implements ChatUserRemoteDataSource {}

void main() {
  late MockChatUserRemoteDataSource mockDataSource;
  late ChatUserRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockChatUserRemoteDataSource();
    repository = ChatUserRepositoryImpl(mockDataSource);
  });

  group('ChatUserRepository', () {
    group('ensureChatUser', () {
      test('calls datasource with user id, displayName, photoUrl', () async {
        when(
          () => mockDataSource.ensureChatUser(
            id: any(named: 'id'),
            displayName: any(named: 'displayName'),
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenAnswer((_) async {});

        final user = UserEntity(
          id: 'u1',
          email: 'a@b.com',
          displayName: 'Alice',
          photoUrl: 'https://example.com/photo.jpg',
        );
        await repository.ensureChatUser(user);

        verify(
          () => mockDataSource.ensureChatUser(
            id: 'u1',
            displayName: 'Alice',
            photoUrl: 'https://example.com/photo.jpg',
          ),
        ).called(1);
      });
    });

    group('ensureChatUserById', () {
      test('calls datasource with userId', () async {
        when(
          () => mockDataSource.ensureChatUserById(any()),
        ).thenAnswer((_) async {});

        await repository.ensureChatUserById('user1');

        verify(() => mockDataSource.ensureChatUserById('user1')).called(1);
      });
    });
  });
}
