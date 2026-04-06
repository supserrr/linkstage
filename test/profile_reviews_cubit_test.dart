import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/review_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/profile_reviews/profile_reviews_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockReviewRepository reviewRepo;
  late MockUserRepository userRepo;

  setUp(() {
    reviewRepo = MockReviewRepository();
    userRepo = MockUserRepository();
  });

  test('load maps reviews and authors', () async {
    final reviews = [
      ReviewEntity(
        id: 'r1',
        reviewerId: 'rev1',
        revieweeId: 'target',
        rating: 5,
        comment: 'Great',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];
    when(
      () => reviewRepo.getReviewsByRevieweeId('target'),
    ).thenAnswer((_) async => reviews);
    when(() => userRepo.getUsersByIds(['rev1'])).thenAnswer(
      (_) async => {
        'rev1': UserEntity(
          id: 'rev1',
          email: 'r@test.com',
          role: UserRole.creativeProfessional,
        ),
      },
    );

    final cubit = ProfileReviewsCubit(reviewRepo, userRepo, 'target', 'viewer');

    await cubit.stream.firstWhere((s) => !s.isLoading);
    expect(cubit.state.reviews, hasLength(1));
    expect(cubit.state.reviewAuthorsById['rev1']?.id, 'rev1');
  });

  test('load empty reviewers skips getUsersByIds batch', () async {
    when(
      () => reviewRepo.getReviewsByRevieweeId('t2'),
    ).thenAnswer((_) async => []);
    when(() => userRepo.getUsersByIds(any())).thenAnswer((_) async => {});

    final cubit = ProfileReviewsCubit(reviewRepo, userRepo, 't2', 'viewer');
    await cubit.stream.firstWhere((s) => !s.isLoading);
    verifyNever(() => userRepo.getUsersByIds(any()));
  });

  test('load failure sets error', () async {
    when(
      () => reviewRepo.getReviewsByRevieweeId('t3'),
    ).thenAnswer((_) async => throw Exception('network'));

    final cubit = ProfileReviewsCubit(reviewRepo, userRepo, 't3', 'viewer');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.error, contains('network'));
  });

  test('addReply likeReview flagReview reload', () async {
    when(
      () => reviewRepo.getReviewsByRevieweeId('t4'),
    ).thenAnswer((_) async => []);
    when(() => reviewRepo.addReply('r1', 'thanks')).thenAnswer((_) async {});
    when(() => reviewRepo.likeReview('r1', 'viewer')).thenAnswer((_) async {});
    when(() => reviewRepo.flagReview('r1', 'viewer')).thenAnswer((_) async {});

    final cubit = ProfileReviewsCubit(reviewRepo, userRepo, 't4', 'viewer');
    await cubit.stream.firstWhere((s) => !s.isLoading);

    await cubit.addReply('r1', 'thanks');
    await cubit.likeReview('r1');
    await cubit.flagReview('r1');

    verify(() => reviewRepo.addReply('r1', 'thanks')).called(1);
    verify(() => reviewRepo.likeReview('r1', 'viewer')).called(1);
    verify(() => reviewRepo.flagReview('r1', 'viewer')).called(1);
    verify(
      () => reviewRepo.getReviewsByRevieweeId('t4'),
    ).called(greaterThan(1));
  });
}
