import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/followed_planners_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/saved_creatives_repository.dart';
import 'package:linkstage/presentation/bloc/creative_dashboard/creative_dashboard_cubit.dart';
import 'package:linkstage/presentation/bloc/creative_dashboard/creative_dashboard_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockSavedCreativesRepository extends Mock
    implements SavedCreativesRepository {}

class MockFollowedPlannersRepository extends Mock
    implements FollowedPlannersRepository {}

void main() {
  const userId = 'creative-1';

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CreativeDashboardCubit', () {
    late MockProfileRepository profileRepo;
    late MockEventRepository eventRepo;
    late MockBookingRepository bookingRepo;
    late MockCollaborationRepository collabRepo;
    late MockSavedCreativesRepository savedCreativesRepo;
    late MockFollowedPlannersRepository followedRepo;
    late SharedPreferences prefs;

    Future<void> registerStubs() async {
      when(
        () => profileRepo.getProfileByUserId(any()),
      ).thenAnswer((_) async => const ProfileEntity(id: 'p1', userId: userId));
      when(
        () => eventRepo.fetchOpenEvents(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () => followedRepo.watchFollowedPlannerIds(any()),
      ).thenAnswer((_) => Stream.value(<String>{}));
      when(
        () => bookingRepo.getPendingBookingsByCreativeId(any()),
      ).thenAnswer((_) async => []);
      when(
        () => bookingRepo.getAcceptedBookingsByCreativeId(any()),
      ).thenAnswer((_) async => []);
      when(
        () => bookingRepo.getInvitedBookingsByCreativeId(any()),
      ).thenAnswer((_) async => []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          any(),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => <CollaborationEntity>[]);
      when(
        () => bookingRepo.getCompletedBookingsByCreativeId(any()),
      ).thenAnswer((_) async => []);
      when(
        () => savedCreativesRepo.watchSavedCreativeIds(any()),
      ).thenAnswer((_) => Stream.value(<String>{}));
      when(
        () => savedCreativesRepo.getSavedProfiles(any()),
      ).thenAnswer((_) async => <ProfileEntity>[]);
      when(
        () => profileRepo.getProfiles(
          limit: any(named: 'limit'),
          excludeUserId: any(named: 'excludeUserId'),
          onlyCreativeAccounts: any(named: 'onlyCreativeAccounts'),
        ),
      ).thenAnswer((_) => Stream.value(<ProfileEntity>[]));
      when(
        () => bookingRepo.getPendingBookingsCountByEventIds(any()),
      ).thenAnswer((_) async => <String, int>{});
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      profileRepo = MockProfileRepository();
      eventRepo = MockEventRepository();
      bookingRepo = MockBookingRepository();
      collabRepo = MockCollaborationRepository();
      savedCreativesRepo = MockSavedCreativesRepository();
      followedRepo = MockFollowedPlannersRepository();
      await registerStubs();
    });

    test('load completes with profile and empty lists', () async {
      final cubit = CreativeDashboardCubit(
        profileRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        savedCreativesRepo,
        followedRepo,
        prefs,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, isNull);
      expect(cubit.state.profile?.userId, userId);
      expect(cubit.state.openEvents, isEmpty);
      await cubit.close();
    });

    test('setFilter updates homeFilter', () async {
      final cubit = CreativeDashboardCubit(
        profileRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        savedCreativesRepo,
        followedRepo,
        prefs,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      cubit.setFilter(CreativeHomeFilter.creatives);
      expect(cubit.state.homeFilter, CreativeHomeFilter.creatives);
      await cubit.close();
    });

    test('load emits error when profile fetch throws', () async {
      when(
        () => profileRepo.getProfileByUserId(any()),
      ).thenThrow(Exception('offline'));

      final cubit = CreativeDashboardCubit(
        profileRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        savedCreativesRepo,
        followedRepo,
        prefs,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });

    test('toggleSavedCreative refreshes saved lists', () async {
      when(() => savedCreativesRepo.toggleSaved(any(), any())).thenAnswer(
        (_) async {},
      );
      when(() => savedCreativesRepo.watchSavedCreativeIds(any())).thenAnswer(
        (_) => Stream.value(<String>{'other-1'}),
      );
      when(() => savedCreativesRepo.getSavedProfiles(any())).thenAnswer(
        (_) async => [
          const ProfileEntity(
            id: 'p2',
            userId: 'other-1',
            username: 'x',
          ),
        ],
      );

      final cubit = CreativeDashboardCubit(
        profileRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        savedCreativesRepo,
        followedRepo,
        prefs,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.toggleSavedCreative('other-1');

      expect(cubit.state.savedCreativeIds, contains('other-1'));
      expect(cubit.state.savedCreatives.length, 1);
      await cubit.close();
    });

    test('toggleSavedEvent updates savedEventIds in memory', () async {
      final cubit = CreativeDashboardCubit(
        profileRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        savedCreativesRepo,
        followedRepo,
        prefs,
        userId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      cubit.toggleSavedEvent('evt-1');
      expect(cubit.state.savedEventIds, contains('evt-1'));
      cubit.toggleSavedEvent('evt-1');
      expect(cubit.state.savedEventIds, isNot(contains('evt-1')));
      await cubit.close();
    });
  });
}
