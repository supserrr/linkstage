import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/domain/entities/conversation_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/chat_user_repository.dart';
import 'package:linkstage/domain/repositories/conversation_repository.dart';
import 'package:linkstage/presentation/pages/messages_page.dart';
import 'package:linkstage/presentation/widgets/molecules/connection_error_overlay.dart';
import 'package:linkstage/presentation/widgets/molecules/empty_state_illustrated.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockChatUserRepository extends Mock implements ChatUserRepository {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows sign-in message when signed out', (tester) async {
    final authRepo = MockAuthRepository();
    when(() => authRepo.currentUser).thenReturn(null);
    sl.registerSingleton<AuthRepository>(authRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();

    expect(find.text('Sign in to view conversations'), findsOneWidget);
  });

  testWidgets('shows skeleton list while stream has no data yet', (
    tester,
  ) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => const Stream<List<ConversationEntity>>.empty());

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ConversationItemSkeleton), findsWidgets);
  });

  testWidgets('shows empty state when there are no conversations', (
    tester,
  ) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => Stream.value(const <ConversationEntity>[]));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EmptyStateIllustrated), findsOneWidget);
    expect(
      find.textContaining('No conversations yet', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('search query filters list and clear button resets', (
    tester,
  ) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});

    final conversations = [
      ConversationEntity(
        id: 'c-1',
        otherUserId: 'x',
        otherUserDisplayName: 'Alice',
        unreadCount: 0,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      ConversationEntity(
        id: 'c-2',
        otherUserId: 'y',
        otherUserDisplayName: 'Bob',
        unreadCount: 0,
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    ];
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => Stream.value(conversations));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('new conversation button navigates to /explore', (tester) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => Stream.value(const <ConversationEntity>[]));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    final router = GoRouter(
      initialLocation: '/messages',
      routes: [
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesPage(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const Scaffold(body: Text('Explore')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
  });

  testWidgets('tapping a conversation navigates to chat route', (tester) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});

    final conversations = [
      ConversationEntity(
        id: 'chat-99',
        otherUserId: 'x',
        otherUserDisplayName: 'TapMe',
        unreadCount: 0,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => Stream.value(conversations));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    final router = GoRouter(
      initialLocation: '/messages',
      routes: [
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesPage(),
        ),
        GoRoute(
          path: '/messages/chat/:id',
          builder: (context, state) => Scaffold(
            body: Text('Chat:${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('TapMe'));
    await tester.pumpAndSettle();

    expect(find.text('Chat:chat-99'), findsOneWidget);
  });

  testWidgets('search with no matches shows no-results state', (tester) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer(
      (_) => Stream.value([
        ConversationEntity(
          id: 'c-1',
          otherUserId: 'x',
          otherUserDisplayName: 'Alice',
          unreadCount: 0,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ]),
    );

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'nomatch');
    await tester.pump();

    expect(
      find.text('No conversations match your search'),
      findsOneWidget,
    );
  });

  testWidgets('conversation stream error shows connection overlay', (
    tester,
  ) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => Stream<List<ConversationEntity>>.error(Exception('x')));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    final router = GoRouter(
      initialLocation: '/messages',
      routes: [
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ConnectionErrorOverlay), findsOneWidget);
  });

  testWidgets('Unread filter hides zero-unread conversations', (tester) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer(
      (_) => Stream.value([
        ConversationEntity(
          id: 'c-1',
          otherUserId: 'a',
          otherUserDisplayName: 'HasUnread',
          unreadCount: 2,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        ConversationEntity(
          id: 'c-2',
          otherUserId: 'b',
          otherUserDisplayName: 'NoUnread',
          unreadCount: 0,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ]),
    );

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('HasUnread'), findsOneWidget);
    expect(find.text('NoUnread'), findsOneWidget);

    await tester.tap(find.text('Unread'));
    await tester.pump();

    expect(find.text('HasUnread'), findsOneWidget);
    expect(find.text('NoUnread'), findsNothing);
  });

  testWidgets('Favorites filter chip can be selected', (tester) async {
    final authRepo = MockAuthRepository();
    final chatUserRepo = MockChatUserRepository();
    final convoRepo = MockConversationRepository();

    const user = UserEntity(
      id: 'u-1',
      email: 'u@test.com',
      role: UserRole.creativeProfessional,
    );
    when(() => authRepo.currentUser).thenReturn(user);
    when(() => chatUserRepo.ensureChatUser(user)).thenAnswer((_) async {});
    when(
      () => convoRepo.watchConversations(user.id),
    ).thenAnswer((_) => Stream.value(const <ConversationEntity>[]));

    sl
      ..registerSingleton<AuthRepository>(authRepo)
      ..registerSingleton<ChatUserRepository>(chatUserRepo)
      ..registerSingleton<ConversationRepository>(convoRepo);

    await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Favorites'));
    await tester.pump();

    await tester.tap(find.text('All'));
    await tester.pump();
  });
}
