import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/repositories/conversation_repository_impl.dart';
import 'package:linkstage/data/datasources/conversation_remote_datasource.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockConversationRemoteDataSource extends Mock
    implements ConversationRemoteDataSource {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockConversationRemoteDataSource mockDataSource;
  late MockUserRepository mockUserRepository;
  late ConversationRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockConversationRemoteDataSource();
    mockUserRepository = MockUserRepository();
    repository = ConversationRepositoryImpl(mockDataSource, mockUserRepository);
    when(
      () => mockUserRepository.canSendMessageTo(any(), any()),
    ).thenAnswer((_) async => true);
  });

  group('ConversationRepository', () {
    group('getOrCreateOneToOneChat', () {
      test('returns chatId from datasource', () async {
        when(
          () => mockDataSource.getOrCreateOneToOneChat(any(), any()),
        ).thenAnswer((_) async => 'chat-123');

        final result = await repository.getOrCreateOneToOneChat(
          'current',
          'other',
        );

        expect(result, 'chat-123');
        verify(
          () => mockUserRepository.canSendMessageTo('current', 'other'),
        ).called(1);
        verify(
          () => mockDataSource.getOrCreateOneToOneChat('current', 'other'),
        ).called(1);
      });
    });

    group('sendMessage', () {
      test('calls datasource sendMessage', () async {
        when(
          () => mockDataSource.sendMessage(any(), any(), any()),
        ).thenAnswer((_) async {});

        await repository.sendMessage('chat-1', 'sender-1', 'Hello');

        verify(
          () => mockDataSource.sendMessage('chat-1', 'sender-1', 'Hello'),
        ).called(1);
      });
    });

    group('getOtherParticipant', () {
      test('returns other participant from datasource', () async {
        when(() => mockDataSource.getOtherParticipant(any(), any())).thenAnswer(
          (_) async => (otherUserId: 'other-1', displayName: 'Alice'),
        );

        final result = await repository.getOtherParticipant(
          'chat-1',
          'current',
        );

        expect(result, isNotNull);
        expect(result!.otherUserId, 'other-1');
        expect(result.displayName, 'Alice');
        verify(
          () => mockDataSource.getOtherParticipant('chat-1', 'current'),
        ).called(1);
      });

      test('returns null when datasource returns null', () async {
        when(
          () => mockDataSource.getOtherParticipant(any(), any()),
        ).thenAnswer((_) async => null);

        final result = await repository.getOtherParticipant(
          'chat-1',
          'current',
        );

        expect(result, isNull);
      });
    });
  });
}
