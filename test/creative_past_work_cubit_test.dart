import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/creative_past_work_preferences_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/creative_past_work/creative_past_work_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockCreativePastWorkPreferencesRepository extends Mock
    implements CreativePastWorkPreferencesRepository {}

void main() {
  const profileUserId = 'creative-1';
  const viewerId = 'creative-1';

  late MockBookingRepository bookingRepo;
  late MockCollaborationRepository collabRepo;
  late MockEventRepository eventRepo;
  late MockUserRepository userRepo;
  late MockProfileRepository profileRepo;
  late MockCreativePastWorkPreferencesRepository prefsRepo;

  setUp(() {
    bookingRepo = MockBookingRepository();
    collabRepo = MockCollaborationRepository();
    eventRepo = MockEventRepository();
    userRepo = MockUserRepository();
    profileRepo = MockProfileRepository();
    prefsRepo = MockCreativePastWorkPreferencesRepository();
  });

  group('CreativePastWorkCubit', () {
    test('load succeeds with empty lists', () async {
      when(() => profileRepo.getProfileByUserId(profileUserId)).thenAnswer(
        (_) async => const ProfileEntity(
          id: 'p1',
          userId: profileUserId,
          displayName: 'C',
        ),
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.getHiddenIds(profileUserId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        viewerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.isLoading, false);
      expect(cubit.state.creativeName, 'C');
      expect(cubit.state.pastEvents, isEmpty);
      expect(cubit.state.pastCollaborations, isEmpty);
      await cubit.close();
    });

    test('load emits error when load throws', () async {
      when(
        () => profileRepo.getProfileByUserId(profileUserId),
      ).thenThrow(Exception('x'));

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        viewerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.isLoading, false);
      await cubit.close();
    });

    test('toggleConfigMode toggles when viewing own profile', () async {
      when(() => profileRepo.getProfileByUserId(profileUserId)).thenAnswer(
        (_) async => const ProfileEntity(id: 'p1', userId: profileUserId),
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.getHiddenIds(profileUserId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        viewerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.configMode, false);
      cubit.toggleConfigMode();
      expect(cubit.state.configMode, true);
      await cubit.close();
    });

    test('toggleConfigMode does nothing when viewing another user', () async {
      when(() => profileRepo.getProfileByUserId(profileUserId)).thenAnswer(
        (_) async => const ProfileEntity(id: 'p1', userId: profileUserId),
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.getHiddenIds(profileUserId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        'other-viewer',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      cubit.toggleConfigMode();
      expect(cubit.state.configMode, false);
      await cubit.close();
    });

    test('setItemVisibility updates hidden ids when viewing own', () async {
      when(() => profileRepo.getProfileByUserId(profileUserId)).thenAnswer(
        (_) async => const ProfileEntity(id: 'p1', userId: profileUserId),
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.getHiddenIds(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.setItemVisibility(profileUserId, 'item-1', false),
      ).thenAnswer((_) async {});

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        viewerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.setItemVisibility('item-1', false);

      expect(cubit.state.hiddenIds, contains('item-1'));
      verify(
        () => prefsRepo.setItemVisibility(profileUserId, 'item-1', false),
      ).called(1);
      await cubit.close();
    });

    test('setItemVisibility no-op when not viewing own', () async {
      when(() => profileRepo.getProfileByUserId(profileUserId)).thenAnswer(
        (_) async => const ProfileEntity(id: 'p1', userId: profileUserId),
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.getHiddenIds(profileUserId),
      ).thenAnswer((_) async => const []);

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        'other',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.setItemVisibility('item-1', false);

      verifyNever(() => prefsRepo.setItemVisibility(any(), any(), any()));
      await cubit.close();
    });

    test('setItemVisibility emits error when prefs throw', () async {
      when(() => profileRepo.getProfileByUserId(profileUserId)).thenAnswer(
        (_) async => const ProfileEntity(id: 'p1', userId: profileUserId),
      );
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          profileUserId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.getHiddenIds(profileUserId),
      ).thenAnswer((_) async => const []);
      when(
        () => prefsRepo.setItemVisibility(profileUserId, 'x', true),
      ).thenThrow(Exception('bad'));

      final cubit = CreativePastWorkCubit(
        bookingRepo,
        collabRepo,
        eventRepo,
        userRepo,
        profileRepo,
        prefsRepo,
        profileUserId,
        viewerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.setItemVisibility('x', true);

      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });
  });
}
