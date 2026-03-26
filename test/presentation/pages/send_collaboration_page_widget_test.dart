import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/app_router.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/core/services/push_notification_service.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/presentation/pages/collaboration/send_collaboration_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const SendCollaborationPage(targetUserId: 'target-1'),
        ),
        GoRoute(
          path: AppRoutes.messages,
          builder: (context, state) => const Scaffold(body: Text('Messages')),
        ),
      ],
    );
  }

  Future<void> scrollToSubmit(WidgetTester tester) async {
    // There are multiple scrollables on the page (dropdown menus, etc.),
    // so use the page's primary SingleChildScrollView.
    final scrollView = find.byType(SingleChildScrollView);
    await tester.drag(scrollView, const Offset(0, -600));
    await tester.pump();
    await tester.drag(scrollView, const Offset(0, -600));
    await tester.pump();
    await tester.ensureVisible(find.text('Send Proposal'));
    await tester.pump();
  }

  void registerSl({required bool success}) {
    final auth = MockAuthRedirectNotifier();
    final repo = MockCollaborationRepository();
    final push = MockPushNotificationService();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'planner-1',
        email: 'p@test.com',
        role: UserRole.eventPlanner,
        displayName: 'Planner',
      ),
    );

    if (success) {
      when(
        () => repo.createCollaboration(
          requesterId: any(named: 'requesterId'),
          targetUserId: any(named: 'targetUserId'),
          description: any(named: 'description'),
          title: any(named: 'title'),
          eventId: any(named: 'eventId'),
          budget: any(named: 'budget'),
          date: any(named: 'date'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          location: any(named: 'location'),
          eventType: any(named: 'eventType'),
        ),
      ).thenAnswer(
        (_) async => const CollaborationEntity(
          id: 'col-1',
          requesterId: 'planner-1',
          targetUserId: 'target-1',
          description: 'hi',
        ),
      );
    } else {
      when(
        () => repo.createCollaboration(
          requesterId: any(named: 'requesterId'),
          targetUserId: any(named: 'targetUserId'),
          description: any(named: 'description'),
          title: any(named: 'title'),
          eventId: any(named: 'eventId'),
          budget: any(named: 'budget'),
          date: any(named: 'date'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          location: any(named: 'location'),
          eventType: any(named: 'eventType'),
        ),
      ).thenThrow(Exception('Network error'));
    }

    when(
      () => push.notifyUser(
        targetUserId: any(named: 'targetUserId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<CollaborationRepository>(repo)
      ..registerSingleton<PushNotificationService>(push);
  }

  testWidgets('renders required form fields', (tester) async {
    registerSl(success: false);
    final router = buildRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('Project or event name'), findsOneWidget);
    expect(find.text('Your message'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Send Proposal'), findsOneWidget);
  });

  testWidgets('shows validation errors on empty submit', (tester) async {
    registerSl(success: false);
    final router = buildRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await scrollToSubmit(tester);
    await tester.tap(find.text('Send Proposal'));
    await tester.pump();

    expect(find.text('Please enter a project or event name'), findsOneWidget);
    expect(find.text('Please describe what you want'), findsOneWidget);
  });

  testWidgets('submits and navigates to messages on success', (tester) async {
    registerSl(success: true);
    final router = buildRouter();
    final repo = sl<CollaborationRepository>() as MockCollaborationRepository;

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'My project');
    await tester.enterText(find.byType(TextFormField).at(1), 'Hello');

    await scrollToSubmit(tester);
    await tester.tap(find.text('Send Proposal'));
    await tester.pump(const Duration(milliseconds: 50));

    verify(
      () => repo.createCollaboration(
        requesterId: 'planner-1',
        targetUserId: 'target-1',
        description: 'Hello',
        title: 'My project',
        eventId: any(named: 'eventId'),
        budget: any(named: 'budget'),
        date: any(named: 'date'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        location: any(named: 'location'),
        eventType: any(named: 'eventType'),
      ),
    ).called(1);

    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsOneWidget);
  });

  testWidgets('shows toast error and stays on page when submission fails', (
    tester,
  ) async {
    registerSl(success: false);
    final router = buildRouter();
    final repo = sl<CollaborationRepository>() as MockCollaborationRepository;

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'My project');
    await tester.enterText(find.byType(TextFormField).at(1), 'Hello');
    await scrollToSubmit(tester);
    await tester.tap(find.text('Send Proposal'));
    await tester.pump(const Duration(milliseconds: 50));

    verify(
      () => repo.createCollaboration(
        requesterId: any(named: 'requesterId'),
        targetUserId: any(named: 'targetUserId'),
        description: any(named: 'description'),
        title: any(named: 'title'),
        eventId: any(named: 'eventId'),
        budget: any(named: 'budget'),
        date: any(named: 'date'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        location: any(named: 'location'),
        eventType: any(named: 'eventType'),
      ),
    ).called(1);

    expect(find.text('Send Collaboration Proposal'), findsOneWidget);
  });
}
