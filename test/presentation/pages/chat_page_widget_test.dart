import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/domain/entities/message_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/chat_user_repository.dart';
import 'package:linkstage/domain/repositories/conversation_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/pages/chat_page.dart';
import 'package:linkstage/presentation/widgets/molecules/chat_input_bar.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockChatUserRepository extends Mock implements ChatUserRepository {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.creativeProfessional);
    registerFallbackValue(
      const UserEntity(
        id: 'fb',
        email: 'fb@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> registerChatSl({
    required UserEntity? currentUser,
    Future<String> Function(String currentUserId, String otherUserId)?
    getOrCreateChat,
    Stream<List<MessageEntity>> Function(String chatId)? watchMessages,
  }) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();
    final userRepo = MockUserRepository();

    when(() => authRepo.currentUser).thenReturn(currentUser);
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => Stream<UserEntity?>.value(currentUser));
    when(() => chatUserRepo.ensureChatUser(any())).thenAnswer((_) async {});
    when(() => chatUserRepo.ensureChatUserById(any())).thenAnswer((_) async {});

    when(() => convoRepo.markChatAsRead(any(), any())).thenAnswer((_) async {});
    when(
      () => convoRepo.getOtherParticipant(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => convoRepo.getOrCreateOneToOneChat(any(), any())).thenAnswer(
      (inv) async => (getOrCreateChat != null)
          ? await getOrCreateChat(
              inv.positionalArguments[0] as String,
              inv.positionalArguments[1] as String,
            )
          : 'chat-1',
    );
    when(() => convoRepo.watchMessages(any())).thenAnswer(
      (inv) => (watchMessages != null)
          ? watchMessages(inv.positionalArguments[0] as String)
          : Stream<List<MessageEntity>>.value(const []),
    );
    when(
      () => convoRepo.sendMessage(any(), any(), any()),
    ).thenAnswer((_) async {});

    when(() => userRepo.getUser(any())).thenAnswer((_) async => null);

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo)
      ..registerSingleton<UserRepository>(userRepo);
  }

  testWidgets('shows error when not signed in', (tester) async {
    await registerChatSl(currentUser: null);

    await tester.pumpWidget(
      const MaterialApp(home: ChatPage(otherUserId: 'u2')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Unable to open chat'), findsOneWidget);
  });

  testWidgets('shows error when missing chat and user params', (tester) async {
    await registerChatSl(
      currentUser: const UserEntity(id: 'u1', email: 'u1@test.com'),
    );

    await tester.pumpWidget(const MaterialApp(home: ChatPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Unable to open chat'), findsOneWidget);
  });

  testWidgets('shows connecting skeleton before chat id resolves', (
    tester,
  ) async {
    await registerChatSl(
      currentUser: const UserEntity(id: 'u1', email: 'u1@test.com'),
      getOrCreateChat: (_, __) => Completer<String>().future,
    );

    await tester.pumpWidget(
      const MaterialApp(home: ChatPage(otherUserId: 'u2')),
    );
    await tester.pump();

    expect(find.byType(ChatInputBar), findsOneWidget);
    expect(find.text('Connecting...'), findsOneWidget);

    // Chat page uses flutter_animate in its message list; advance timers.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('send button calls ConversationRepository.sendMessage', (
    tester,
  ) async {
    await registerChatSl(
      currentUser: const UserEntity(id: 'u1', email: 'u1@test.com'),
      watchMessages: (_) => Stream<List<MessageEntity>>.value(const []),
    );

    final convoRepo =
        sl<ConversationRepository>() as MockConversationRepository;

    await tester.pumpWidget(
      const MaterialApp(home: ChatPage(otherUserId: 'u2')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'Test message');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(milliseconds: 50));

    verify(
      () => convoRepo.sendMessage('chat-1', 'u1', 'Test message'),
    ).called(1);
  });
}
