import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/review_remote_datasource.dart';
import 'package:linkstage/data/repositories/review_repository_impl.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/review_entity.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRemoteDataSource extends Mock
    implements ReviewRemoteDataSource {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ReviewRepositoryImpl', () {
    late MockReviewRemoteDataSource remote;
    late MockProfileRepository profileRepository;
    late ReviewRepositoryImpl repo;

    setUp(() {
      remote = MockReviewRemoteDataSource();
      profileRepository = MockProfileRepository();
      repo = ReviewRepositoryImpl(remote, profileRepository);
    });

    test(
      'createReview updates profile rating stats when reviewee has a profile',
      () async {
        when(
          () => remote.createReview(
            bookingId: any(named: 'bookingId'),
            reviewerId: any(named: 'reviewerId'),
            revieweeId: any(named: 'revieweeId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          ),
        ).thenAnswer(
          (_) async => const ReviewEntity(
            id: 'r1',
            bookingId: 'b1',
            reviewerId: 'u1',
            revieweeId: 'u2',
            rating: 5,
            comment: 'Great',
          ),
        );
        when(() => profileRepository.getProfileByUserId('u2')).thenAnswer(
          (_) async =>
              const ProfileEntity(id: 'p-u2', userId: 'u2', username: 'u2'),
        );
        when(() => remote.getReviewsByRevieweeId('u2')).thenAnswer(
          (_) async => const [
            ReviewEntity(
              id: 'r1',
              bookingId: 'b1',
              reviewerId: 'u1',
              revieweeId: 'u2',
              rating: 5,
              comment: 'Great',
            ),
            ReviewEntity(
              id: 'r2',
              bookingId: 'b2',
              reviewerId: 'u3',
              revieweeId: 'u2',
              rating: 4,
              comment: 'Good',
            ),
          ],
        );
        when(
          () => profileRepository.updateProfileRatingStats(any(), any(), any()),
        ).thenAnswer((_) async {});

        final review = await repo.createReview(
          bookingId: 'b1',
          reviewerId: 'u1',
          revieweeId: 'u2',
          rating: 5,
          comment: 'Great',
        );

        expect(review.id, 'r1');
        verify(
          () => profileRepository.updateProfileRatingStats('p-u2', 4.5, 2),
        ).called(1);
      },
    );

    test(
      'createReview does not update rating stats when no profile exists',
      () async {
        when(
          () => remote.createReview(
            bookingId: any(named: 'bookingId'),
            reviewerId: any(named: 'reviewerId'),
            revieweeId: any(named: 'revieweeId'),
            rating: any(named: 'rating'),
            comment: any(named: 'comment'),
          ),
        ).thenAnswer(
          (_) async => const ReviewEntity(
            id: 'r1',
            bookingId: 'b1',
            reviewerId: 'u1',
            revieweeId: 'uX',
            rating: 5,
            comment: 'Great',
          ),
        );
        when(
          () => profileRepository.getProfileByUserId('uX'),
        ).thenAnswer((_) async => null);

        await repo.createReview(
          bookingId: 'b1',
          reviewerId: 'u1',
          revieweeId: 'uX',
          rating: 5,
          comment: 'Great',
        );

        verifyNever(() => remote.getReviewsByRevieweeId(any()));
        verifyNever(
          () => profileRepository.updateProfileRatingStats(any(), any(), any()),
        );
      },
    );
  });
}
