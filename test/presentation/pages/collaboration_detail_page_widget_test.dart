import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/core/services/push_notification_service.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/presentation/pages/collaboration/collaboration_detail_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(CollaborationStatus.pending);
    registerFallbackValue(UserRole.creativeProfessional);
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('CollaborationDetailPage builds for completed collaboration', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    final reviewRepo = MockReviewRepository();
    final push = MockPushNotificationService();

    when(
      () => auth.user,
    ).thenReturn(const UserEntity(id: 'u1', email: 'u@test.com'));
    when(
      () => reviewRepo.getReviewByCollaborationAndReviewer(any(), any()),
    ).thenAnswer((_) async => null);

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<PushNotificationService>(push);

    final collab = CollaborationEntity(
      id: 'col-1',
      requesterId: 'p1',
      targetUserId: 'c1',
      description: 'Test collaboration description for widget test.',
      status: CollaborationStatus.completed,
      title: 'Gig',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CollaborationDetailPage(
          collaboration: collab,
          otherPersonName: 'Pat',
          otherPersonId: 'p1',
          viewerIsCreative: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Collaboration Details'), findsOneWidget);
    expect(find.textContaining('Test collaboration'), findsOneWidget);
  });

  testWidgets('pending collaboration: tap Accept calls updateStatus + notify', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    final reviewRepo = MockReviewRepository();
    final collabRepo = MockCollaborationRepository();
    final push = MockPushNotificationService();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'viewer-1',
        email: 'viewer@test.com',
        displayName: 'Viewer',
      ),
    );
    when(
      () => reviewRepo.getReviewByCollaborationAndReviewer(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => collabRepo.updateStatus(
        any(),
        any(),
        confirmingIsPlanner: any(named: 'confirmingIsPlanner'),
      ),
    ).thenAnswer((_) async {});
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
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<PushNotificationService>(push);

    final collab = CollaborationEntity(
      id: 'col-pending',
      requesterId: 'planner-1',
      targetUserId: 'creative-1',
      description: 'Pending proposal',
      status: CollaborationStatus.pending,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CollaborationDetailPage(
          collaboration: collab,
          otherPersonName: 'Pat',
          otherPersonId: 'planner-1',
          viewerIsCreative: true,
          otherPersonRole: UserRole.eventPlanner,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(
      () =>
          collabRepo.updateStatus('col-pending', CollaborationStatus.accepted),
    ).called(1);
    verify(
      () => push.notifyUser(
        targetUserId: 'planner-1',
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).called(1);
  });

  testWidgets('completed collaboration: creative confirms completion', (
    tester,
  ) async {
    final auth = MockAuthRedirectNotifier();
    final reviewRepo = MockReviewRepository();
    final collabRepo = MockCollaborationRepository();
    final push = MockPushNotificationService();

    when(() => auth.user).thenReturn(
      const UserEntity(
        id: 'creative-1',
        email: 'c@test.com',
        displayName: 'Creative',
      ),
    );
    when(
      () => reviewRepo.getReviewByCollaborationAndReviewer(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => collabRepo.confirmCompletionByCreative(any()),
    ).thenAnswer((_) async {});

    sl
      ..registerSingleton<AuthRedirectNotifier>(auth)
      ..registerSingleton<ReviewRepository>(reviewRepo)
      ..registerSingleton<CollaborationRepository>(collabRepo)
      ..registerSingleton<PushNotificationService>(push);

    final collab = CollaborationEntity(
      id: 'col-acc',
      requesterId: 'planner-1',
      targetUserId: 'creative-1',
      description: 'Accepted',
      status: CollaborationStatus.completed,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CollaborationDetailPage(
          collaboration: collab,
          otherPersonName: 'Pat',
          otherPersonId: 'planner-1',
          viewerIsCreative: true,
          otherPersonRole: UserRole.eventPlanner,
        ),
      ),
    );
    await tester.pump();

    final confirm = find.widgetWithText(
      OutlinedButton,
      'Confirm I completed my work',
    );
    expect(confirm, findsOneWidget);
    final btn = tester.widget<OutlinedButton>(confirm);
    expect(btn.onPressed, isNotNull);

    await tester.ensureVisible(confirm);
    await tester.pump();
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(() => collabRepo.confirmCompletionByCreative('col-acc')).called(1);
  });
}
