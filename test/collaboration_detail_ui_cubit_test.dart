import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/presentation/bloc/collaboration_detail/collaboration_detail_ui_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late MockAuthRedirectNotifier auth;
  late MockReviewRepository reviewRepo;

  final pendingCollab = CollaborationEntity(
    id: 'col-1',
    requesterId: 'p1',
    targetUserId: 'c1',
    description: 'd',
    status: CollaborationStatus.pending,
  );

  final completedCollab = CollaborationEntity(
    id: 'col-2',
    requesterId: 'p1',
    targetUserId: 'c1',
    description: 'd',
    status: CollaborationStatus.completed,
  );

  setUp(() async {
    await sl.reset();
    auth = MockAuthRedirectNotifier();
    reviewRepo = MockReviewRepository();
    sl.registerSingleton<AuthRedirectNotifier>(auth);
    sl.registerSingleton<ReviewRepository>(reviewRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  test('pending collaboration skips review fetch', () async {
    when(
      () => auth.user,
    ).thenReturn(const UserEntity(id: 'u1', email: 'u@test.com'));

    final cubit = CollaborationDetailUiCubit(pendingCollab);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.hasReviewed, isFalse);
    verifyNever(
      () => reviewRepo.getReviewByCollaborationAndReviewer(any(), any()),
    );
    await cubit.close();
  });

  test('completed collaboration loads hasReviewed from repository', () async {
    when(
      () => auth.user,
    ).thenReturn(const UserEntity(id: 'u1', email: 'u@test.com'));
    when(
      () => reviewRepo.getReviewByCollaborationAndReviewer('col-2', 'u1'),
    ).thenAnswer((_) async => null);

    final cubit = CollaborationDetailUiCubit(completedCollab);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.hasReviewed, isFalse);
    verify(
      () => reviewRepo.getReviewByCollaborationAndReviewer('col-2', 'u1'),
    ).called(1);
    await cubit.close();
  });

  test('getReview throws yields hasReviewed false', () async {
    when(
      () => auth.user,
    ).thenReturn(const UserEntity(id: 'u1', email: 'u@test.com'));
    when(
      () => reviewRepo.getReviewByCollaborationAndReviewer(any(), any()),
    ).thenThrow(Exception('x'));

    final cubit = CollaborationDetailUiCubit(completedCollab);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.hasReviewed, isFalse);
    await cubit.close();
  });

  test('setHasReviewed and applyMarkAsDone', () async {
    when(() => auth.user).thenReturn(null);

    final cubit = CollaborationDetailUiCubit(pendingCollab);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    cubit.setHasReviewed(true);
    expect(cubit.state.hasReviewed, isTrue);

    cubit.setConfirmingCompletion(true);
    expect(cubit.state.isConfirmingCompletion, isTrue);

    cubit.applyCreativeConfirmedNow();
    expect(cubit.state.isConfirmingCompletion, isFalse);
    expect(cubit.state.overrideCreativeConfirmedAt, isNotNull);

    cubit.applyMarkAsDone(viewerIsCreative: true);
    expect(cubit.state.overrideStatus, CollaborationStatus.completed);

    await cubit.close();
  });
}
