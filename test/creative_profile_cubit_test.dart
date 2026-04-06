import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/review_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/review_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/creative_profile/creative_profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  const userId = 'creative-1';

  setUpAll(() {
    registerFallbackValue(const ProfileEntity(id: 'fb', userId: 'fb'));
    registerFallbackValue(const UserEntity(id: 'fb', email: 'fb@test.com'));
  });

  late MockProfileRepository profileRepo;
  late MockReviewRepository reviewRepo;
  late MockBookingRepository bookingRepo;
  late MockUserRepository userRepo;

  ProfileEntity baseProfile({String? photoUrl, String? displayName}) {
    return ProfileEntity(
      id: 'prof-1',
      userId: userId,
      username: 'c1',
      bio: 'bio',
      photoUrl: photoUrl,
      displayName: displayName,
    );
  }

  setUp(() {
    profileRepo = MockProfileRepository();
    reviewRepo = MockReviewRepository();
    bookingRepo = MockBookingRepository();
    userRepo = MockUserRepository();
  });

  group('CreativeProfileCubit', () {
    test('load succeeds with profile, reviews, and gigs', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile());
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.isLoading, false);
      expect(cubit.state.profile?.userId, userId);
      expect(cubit.state.totalGigs, 0);
      expect(cubit.state.error, isNull);
      await cubit.close();
    });

    test('load merges photo from user when profile photo empty', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile(photoUrl: ''));
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(
          id: userId,
          email: 'c@test.com',
          photoUrl: 'https://x/u.png',
        ),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.profile?.photoUrl, 'https://x/u.png');
      await cubit.close();
    });

    test('load merges display name from user when profile empty', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile(displayName: null));
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(
          id: userId,
          email: 'c@test.com',
          displayName: '  Alice  ',
        ),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.profile?.displayName, 'Alice');
      await cubit.close();
    });

    test('load loads review authors when reviews have reviewer ids', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile());
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(() => reviewRepo.getReviewsByRevieweeId(userId)).thenAnswer(
        (_) async => [
          const ReviewEntity(
            id: 'r1',
            reviewerId: 'rev-1',
            revieweeId: userId,
            rating: 5,
          ),
        ],
      );
      when(() => userRepo.getUsersByIds(['rev-1'])).thenAnswer(
        (_) async => {
          'rev-1': const UserEntity(
            id: 'rev-1',
            email: 'r@test.com',
            displayName: 'Reviewer',
          ),
        },
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.reviewAuthorsById['rev-1']?.displayName, 'Reviewer');
      await cubit.close();
    });

    test('load sets totalGigs from completed bookings', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile());
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer(
        (_) async => [
          const BookingEntity(
            id: 'b1',
            eventId: 'e1',
            creativeId: userId,
            plannerId: 'p1',
          ),
          const BookingEntity(
            id: 'b2',
            eventId: 'e2',
            creativeId: userId,
            plannerId: 'p1',
          ),
        ],
      );

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.totalGigs, 2);
      await cubit.close();
    });

    test('load emits error when repository throws', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenThrow(Exception('network'));

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });

    test('setters update profile fields after load', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile());
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      cubit
        ..setBio('new bio')
        ..setDisplayName('Name')
        ..setPriceRange('100-200')
        ..setProfessions(['DJ'])
        ..setLocation('Kigali')
        ..setAvailability(ProfileAvailability.openToWork)
        ..setPortfolioUrls(['https://a'])
        ..setPortfolioVideoUrls(['https://v'])
        ..setServices(['s'])
        ..setLanguages(['en']);

      expect(cubit.state.profile?.bio, 'new bio');
      expect(cubit.state.profile?.displayName, 'Name');
      expect(cubit.state.profile?.priceRange, '100-200');
      expect(cubit.state.profile?.professions, ['DJ']);
      expect(cubit.state.profile?.location, 'Kigali');
      expect(cubit.state.profile?.availability, ProfileAvailability.openToWork);
      expect(cubit.state.profile?.portfolioUrls, ['https://a']);
      expect(cubit.state.profile?.portfolioVideoUrls, ['https://v']);
      expect(cubit.state.profile?.services, ['s']);
      expect(cubit.state.profile?.languages, ['en']);

      await cubit.close();
    });

    test('setDisplayName with empty string clears display name', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile(displayName: 'X'));
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      cubit.setDisplayName('');
      expect(cubit.state.profile?.displayName, isNull);
      await cubit.close();
    });

    test('save upserts profile and user when firestore user exists', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile(displayName: 'Alice'));
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(
          id: userId,
          email: 'c@test.com',
          displayName: 'Old',
        ),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);
      when(() => profileRepo.upsertProfile(any())).thenAnswer((_) async {});
      when(() => userRepo.upsertUser(any())).thenAnswer((_) async {});

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.save();

      verify(() => profileRepo.upsertProfile(any())).called(1);
      verify(() => userRepo.getUser(userId)).called(2);
      verify(() => userRepo.upsertUser(any())).called(1);
      expect(cubit.state.isSaving, false);
      await cubit.close();
    });

    test(
      'save skips upsertUser when getUser returns null after upsert',
      () async {
        when(
          () => profileRepo.getProfileByUserId(userId),
        ).thenAnswer((_) async => baseProfile(displayName: 'Alice'));
        var getUserCalls = 0;
        when(() => userRepo.getUser(userId)).thenAnswer((_) async {
          getUserCalls++;
          if (getUserCalls == 1) {
            return const UserEntity(id: userId, email: 'c@test.com');
          }
          return null;
        });
        when(
          () => reviewRepo.getReviewsByRevieweeId(userId),
        ).thenAnswer((_) async => const []);
        when(
          () => bookingRepo.getCompletedBookingsByCreativeId(userId),
        ).thenAnswer((_) async => const []);
        when(() => profileRepo.upsertProfile(any())).thenAnswer((_) async {});

        final cubit = CreativeProfileCubit(
          profileRepo,
          reviewRepo,
          bookingRepo,
          userRepo,
          userId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));

        await cubit.save();

        verifyNever(() => userRepo.upsertUser(any()));
        await cubit.close();
      },
    );

    test('save emits error when upsertProfile throws', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile(displayName: 'Alice'));
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);
      when(() => profileRepo.upsertProfile(any())).thenThrow(Exception('fail'));

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.save();

      expect(cubit.state.isSaving, false);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });

    test('refresh calls load again', () async {
      when(
        () => profileRepo.getProfileByUserId(userId),
      ).thenAnswer((_) async => baseProfile());
      when(() => userRepo.getUser(userId)).thenAnswer(
        (_) async => const UserEntity(id: userId, email: 'c@test.com'),
      );
      when(
        () => reviewRepo.getReviewsByRevieweeId(userId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(userId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativeProfileCubit(
        profileRepo,
        reviewRepo,
        bookingRepo,
        userRepo,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await cubit.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      verify(() => profileRepo.getProfileByUserId(userId)).called(2);
      await cubit.close();
    });
  });
}
