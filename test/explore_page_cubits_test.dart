import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/core/di/injection.dart';
import 'package:linkstage/core/router/auth_redirect.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/presentation/pages/explore_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('CreativeExploreCubit setters', () {
    test('setTab setSelectedCategory setSelectedEventType update state', () {
      final cubit = CreativeExploreCubit();
      cubit.setTab(ExploreTab.creatives);
      expect(cubit.state.tab, ExploreTab.creatives);
      cubit.setSelectedCategory(ProfileCategory.dj);
      expect(cubit.state.selectedCategory, ProfileCategory.dj);
      cubit.setSelectedEventType('Music');
      expect(cubit.state.selectedEventType, 'Music');
      cubit.close();
    });
  });

  group('CreativeExploreUiState.filteredEvents', () {
    test('filters by selected event type', () {
      final ev = EventEntity(
        id: '1',
        plannerId: 'p',
        title: 'Wedding show',
        eventType: 'Wedding',
        date: DateTime.now().add(const Duration(days: 7)),
      );
      final s = CreativeExploreUiState(
        events: [ev],
        selectedEventType: 'Wedding',
      );
      expect(s.filteredEvents.length, 1);

      final s2 = CreativeExploreUiState(
        events: [ev],
        selectedEventType: 'Music',
      );
      expect(s2.filteredEvents.length, 0);
    });
  });

  group('CreativeExploreCubit.loadEvents', () {
    test('success aggregates accepted ids', () async {
      final auth = MockAuthRedirectNotifier();
      final profileRepo = MockProfileRepository();
      final eventRepo = MockEventRepository();
      final bookingRepo = MockBookingRepository();

      when(() => auth.user).thenReturn(
        const UserEntity(
          id: 'u1',
          email: 'a@b.com',
          role: UserRole.creativeProfessional,
        ),
      );
      when(() => profileRepo.getProfileByUserId('u1')).thenAnswer(
        (_) async => const ProfileEntity(id: 'pr', userId: 'u1', username: 'x'),
      );
      when(() => eventRepo.fetchDiscoverableEvents(limit: any(named: 'limit')))
          .thenAnswer((_) async => [
                EventEntity(
                  id: 'e1',
                  plannerId: 'p',
                  title: 'Future',
                  eventType: 'Party',
                  date: DateTime.now().add(const Duration(days: 3)),
                ),
              ]);
      when(() => bookingRepo.getAcceptedBookingsByCreativeId('u1')).thenAnswer(
        (_) async => [
          BookingEntity(
            id: 'b1',
            eventId: 'e1',
            creativeId: 'u1',
            plannerId: 'p',
            status: BookingStatus.accepted,
          ),
        ],
      );

      sl
        ..registerSingleton<AuthRedirectNotifier>(auth)
        ..registerSingleton<ProfileRepository>(profileRepo)
        ..registerSingleton<EventRepository>(eventRepo)
        ..registerSingleton<BookingRepository>(bookingRepo);

      final cubit = CreativeExploreCubit();
      await cubit.loadEvents();

      expect(cubit.state.eventsLoading, false);
      expect(cubit.state.acceptedEventIds, contains('e1'));
      await cubit.close();
    });

    test('emits error when fetch fails', () async {
      final auth = MockAuthRedirectNotifier();
      final profileRepo = MockProfileRepository();
      final eventRepo = MockEventRepository();
      final bookingRepo = MockBookingRepository();

      when(() => auth.user).thenReturn(null);
      when(() => eventRepo.fetchDiscoverableEvents(limit: any(named: 'limit')))
          .thenThrow(Exception('offline'));
      when(() => bookingRepo.getAcceptedBookingsByCreativeId(any()))
          .thenAnswer((_) async => []);

      sl
        ..registerSingleton<AuthRedirectNotifier>(auth)
        ..registerSingleton<ProfileRepository>(profileRepo)
        ..registerSingleton<EventRepository>(eventRepo)
        ..registerSingleton<BookingRepository>(bookingRepo);

      final cubit = CreativeExploreCubit();
      await cubit.loadEvents();

      expect(cubit.state.eventsError, isNotNull);
      expect(cubit.state.eventsLoading, false);
      await cubit.close();
    });
  });

  group('UnifiedExploreCubit', () {
    test('loadPlanners success', () async {
      final plannerRepo = MockPlannerProfileRepository();
      when(
        () => plannerRepo.getPlannerProfiles(
          limit: any(named: 'limit'),
          excludeUserId: any(named: 'excludeUserId'),
        ),
      ).thenAnswer((_) async => []);

      sl.registerSingleton<PlannerProfileRepository>(plannerRepo);

      final cubit = UnifiedExploreCubit('planner-self');
      await cubit.loadPlanners();

      expect(cubit.state.plannersLoading, false);
      expect(cubit.state.plannersError, isNull);
      await cubit.close();
    });

    test('loadPlanners maps error', () async {
      final plannerRepo = MockPlannerProfileRepository();
      when(
        () => plannerRepo.getPlannerProfiles(
          limit: any(named: 'limit'),
          excludeUserId: any(named: 'excludeUserId'),
        ),
      ).thenThrow(Exception('x'));

      sl.registerSingleton<PlannerProfileRepository>(plannerRepo);

      final cubit = UnifiedExploreCubit('id');
      await cubit.loadPlanners();

      expect(cubit.state.plannersError, isNotNull);
      await cubit.close();
    });

    test('setAccountTab triggers loadPlanners when switching to planners tab', () async {
      final plannerRepo = MockPlannerProfileRepository();
      when(
        () => plannerRepo.getPlannerProfiles(
          limit: 50,
          excludeUserId: 'u',
        ),
      ).thenAnswer((_) async => []);

      sl.registerSingleton<PlannerProfileRepository>(plannerRepo);

      final cubit = UnifiedExploreCubit('u');
      cubit.setAccountTab(ExploreAccountTab.eventPlanners);
      await cubit.stream.firstWhere((s) => !s.plannersLoading);

      verify(
        () => plannerRepo.getPlannerProfiles(limit: 50, excludeUserId: 'u'),
      ).called(1);
      await cubit.close();
    });

    test('applyFilters updates selection', () {
      final cubit = UnifiedExploreCubit(null);
      cubit.applyFilters(
        category: ProfileCategory.dj,
        location: 'Kigali',
      );
      expect(cubit.state.selectedCategory, ProfileCategory.dj);
      expect(cubit.state.selectedLocation, 'Kigali');
      cubit.close();
    });
  });
}
