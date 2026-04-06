import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/notification_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/notification_repository.dart';
import 'package:linkstage/l10n/app_localizations.dart';
import 'package:linkstage/presentation/pages/notifications_page.dart';
import 'package:linkstage/presentation/widgets/molecules/empty_state_illustrated.dart';
import 'package:linkstage/presentation/widgets/molecules/skeleton_loaders.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.creativeProfessional);
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets('signed out shows sign-in message', (tester) async {
    final auth = MockAuthRedirectNotifier();
    when(() => auth.user).thenReturn(null);
    sl.registerSingleton<AuthRedirectNotifier>(auth);

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(find.text('Sign in to view notifications'), findsOneWidget);
  });

  testWidgets('signed in shows skeleton before loaded', (tester) async {
    final auth = MockAuthRedirectNotifier();
    final repo = MockNotificationRepository();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'u1',
        email: 'u1@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    when(
      () => repo.watchNotifications('u1', UserRole.creativeProfessional),
    ).thenAnswer((_) => const Stream<List<NotificationEntity>>.empty());
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => const Stream<Set<String>>.empty());
    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<NotificationRepository>(repo);

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(find.byType(NotificationListSkeleton), findsOneWidget);
    // Allow any internal animation timers to advance.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('signed in with empty notifications shows empty state', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    final repo = MockNotificationRepository();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'u1',
        email: 'u1@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    when(
      () => repo.watchNotifications('u1', UserRole.creativeProfessional),
    ).thenAnswer((_) => Stream.value(const <NotificationEntity>[]));
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => Stream.value(<String>{}));
    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<NotificationRepository>(repo);

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(EmptyStateIllustrated), findsOneWidget);
  });

  testWidgets('signed in with a notification renders list', (tester) async {
    final auth = MockAuthRedirectNotifier();
    final repo = MockNotificationRepository();
    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'u1',
        email: 'u1@test.com',
        role: UserRole.creativeProfessional,
      ),
    );
    final n = NotificationEntity(
      id: 'n1',
      type: NotificationType.chatNewMessage,
      title: 'New message',
      subtitle: 'Hello',
      createdAt: DateTime.utc(2026, 1, 1),
      route: '/messages',
    );
    when(
      () => repo.watchNotifications('u1', UserRole.creativeProfessional),
    ).thenAnswer((_) => Stream.value([n]));
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => Stream.value(<String>{}));
    when(() => repo.markAsRead(any(), any())).thenAnswer((_) async {});
    when(() => repo.markAllAsRead(any(), any())).thenAnswer((_) async {});
    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<NotificationRepository>(repo);

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New message'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
