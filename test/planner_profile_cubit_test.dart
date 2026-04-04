import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:linkstage/domain/repositories/event_repository.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/presentation/bloc/planner_profile/planner_profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

void main() {
  const plannerId = 'planner-1';

  setUpAll(() {
    registerFallbackValue(const PlannerProfileEntity(userId: 'fb'));
    registerFallbackValue(const ProfileEntity(id: 'fb', userId: 'fb'));
    registerFallbackValue(const UserEntity(id: 'fb', email: 'fb@test.com'));
    registerFallbackValue(EventEntity(id: 'fb', plannerId: 'fb', title: 't'));
  });

  late MockUserRepository userRepo;
  late MockEventRepository eventRepo;
  late MockBookingRepository bookingRepo;
  late MockCollaborationRepository collabRepo;
  late MockProfileRepository profileRepo;
  late MockPlannerProfileRepository plannerProfileRepo;

  setUp(() {
    userRepo = MockUserRepository();
    eventRepo = MockEventRepository();
    bookingRepo = MockBookingRepository();
    collabRepo = MockCollaborationRepository();
    profileRepo = MockProfileRepository();
    plannerProfileRepo = MockPlannerProfileRepository();
  });

  group('PlannerProfileCubit', () {
    test(
      'load merges display name from user when planner profile empty',
      () async {
        when(() => userRepo.getUser(plannerId)).thenAnswer(
          (_) async => const UserEntity(
            id: plannerId,
            email: 'p@test.com',
            displayName: 'Pat Host',
          ),
        );
        when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
          (_) async => const PlannerProfileEntity(userId: plannerId),
        );
        when(
          () => eventRepo.fetchEventsByPlannerId(plannerId),
        ).thenAnswer((_) async => const []);
        when(
          () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
        ).thenAnswer((_) async => const []);
        when(
          () => collabRepo.getCollaborationsByTargetUserId(
            plannerId,
            status: CollaborationStatus.completed,
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => collabRepo.getCollaborationsByRequesterId(
            plannerId,
            status: CollaborationStatus.completed,
          ),
        ).thenAnswer((_) async => const []);

        final cubit = PlannerProfileCubit(
          userRepo,
          eventRepo,
          bookingRepo,
          collabRepo,
          profileRepo,
          plannerProfileRepo,
          plannerId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(cubit.state.plannerProfile?.displayName, 'Pat Host');
        expect(cubit.state.isLoading, false);
        await cubit.close();
      },
    );

    test(
      'load uses default planner entity when getPlannerProfile returns null',
      () async {
        when(() => userRepo.getUser(plannerId)).thenAnswer(
          (_) async => const UserEntity(
            id: plannerId,
            email: 'p@test.com',
            displayName: 'Fallback Name',
          ),
        );
        when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
          (_) async => null,
        );
        when(
          () => eventRepo.fetchEventsByPlannerId(plannerId),
        ).thenAnswer((_) async => const []);
        when(
          () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
        ).thenAnswer((_) async => const []);
        when(
          () => collabRepo.getCollaborationsByTargetUserId(
            plannerId,
            status: CollaborationStatus.completed,
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => collabRepo.getCollaborationsByRequesterId(
            plannerId,
            status: CollaborationStatus.completed,
          ),
        ).thenAnswer((_) async => const []);

        final cubit = PlannerProfileCubit(
          userRepo,
          eventRepo,
          bookingRepo,
          collabRepo,
          profileRepo,
          plannerProfileRepo,
          plannerId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(cubit.state.plannerProfile?.userId, plannerId);
        expect(cubit.state.plannerProfile?.displayName, 'Fallback Name');
        await cubit.close();
      },
    );

    test('load splits past and current events', () async {
      final past = DateTime.now().subtract(const Duration(days: 10));
      final future = DateTime.now().add(const Duration(days: 10));
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(
          id: plannerId,
          email: 'p@test.com',
          role: UserRole.eventPlanner,
        ),
      );
      when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
        (_) async =>
            const PlannerProfileEntity(userId: plannerId, displayName: 'P'),
      );
      when(() => eventRepo.fetchEventsByPlannerId(plannerId)).thenAnswer(
        (_) async => [
          EventEntity(
            id: 'e-past',
            plannerId: plannerId,
            title: 'Old',
            date: past,
            status: EventStatus.open,
          ),
          EventEntity(
            id: 'e-done',
            plannerId: plannerId,
            title: 'Done',
            status: EventStatus.completed,
          ),
          EventEntity(
            id: 'e-up',
            plannerId: plannerId,
            title: 'Up',
            date: future,
            status: EventStatus.open,
          ),
        ],
      );
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.events.length, 3);
      expect(cubit.state.pastEvents.length, 2);
      expect(cubit.state.currentEvents.length, 1);
      await cubit.close();
    });

    test('load loads recent creatives from bookings and collabs', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
      );
      when(
        () => plannerProfileRepo.getPlannerProfile(plannerId),
      ).thenAnswer((_) async => const PlannerProfileEntity(userId: plannerId));
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer(
        (_) async => [
          const BookingEntity(
            id: 'b1',
            eventId: 'e1',
            creativeId: 'cr-1',
            plannerId: plannerId,
          ),
        ],
      );
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer(
        (_) async => [
          CollaborationEntity(
            id: 'c1',
            requesterId: 'cr-2',
            targetUserId: plannerId,
            description: 'd',
          ),
        ],
      );
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer(
        (_) async => [
          CollaborationEntity(
            id: 'c2',
            requesterId: plannerId,
            targetUserId: 'cr-3',
            description: 'd2',
          ),
        ],
      );
      when(() => profileRepo.getProfileByUserId('cr-1')).thenAnswer(
        (_) async => const ProfileEntity(id: 'cr-1', userId: 'cr-1'),
      );
      when(() => profileRepo.getProfileByUserId('cr-2')).thenAnswer(
        (_) async => const ProfileEntity(id: 'cr-2', userId: 'cr-2'),
      );
      when(() => profileRepo.getProfileByUserId('cr-3')).thenAnswer(
        (_) async => const ProfileEntity(id: 'cr-3', userId: 'cr-3'),
      );

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(cubit.state.recentCreatives.length, 3);
      await cubit.close();
    });

    test(
      'load fills acceptedEventIdsForViewer when viewing another user',
      () async {
        const viewerId = 'viewer-1';
        when(() => userRepo.getUser(plannerId)).thenAnswer(
          (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
        );
        when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
          (_) async => const PlannerProfileEntity(userId: plannerId),
        );
        when(
          () => eventRepo.fetchEventsByPlannerId(plannerId),
        ).thenAnswer((_) async => const []);
        when(
          () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
        ).thenAnswer((_) async => const []);
        when(
          () => collabRepo.getCollaborationsByTargetUserId(
            plannerId,
            status: CollaborationStatus.completed,
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => collabRepo.getCollaborationsByRequesterId(
            plannerId,
            status: CollaborationStatus.completed,
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => bookingRepo.getAcceptedBookingsByCreativeId(viewerId),
        ).thenAnswer(
          (_) async => [
            const BookingEntity(
              id: 'b1',
              eventId: 'evt-1',
              creativeId: viewerId,
              plannerId: plannerId,
            ),
          ],
        );

        final cubit = PlannerProfileCubit(
          userRepo,
          eventRepo,
          bookingRepo,
          collabRepo,
          profileRepo,
          plannerProfileRepo,
          plannerId,
          viewingUserId: viewerId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(cubit.state.acceptedEventIdsForViewer, contains('evt-1'));
        await cubit.close();
      },
    );

    test('load emits error on failure', () async {
      when(() => userRepo.getUser(plannerId)).thenThrow(Exception('x'));

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.isLoading, false);
      await cubit.close();
    });

    test('setters update planner profile fields', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
      );
      when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
        (_) async =>
            const PlannerProfileEntity(userId: plannerId, displayName: 'N'),
      );
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      cubit
        ..setBio('bio')
        ..setDisplayName('D')
        ..setLocation('Loc')
        ..setEventTypes(['Wedding'])
        ..setLanguages(['en'])
        ..setPortfolioUrls(['https://p'])
        ..setRole(' Planner ');

      expect(cubit.state.plannerProfile?.bio, 'bio');
      expect(cubit.state.plannerProfile?.displayName, 'D');
      expect(cubit.state.plannerProfile?.location, 'Loc');
      expect(cubit.state.plannerProfile?.eventTypes, ['Wedding']);
      expect(cubit.state.plannerProfile?.languages, ['en']);
      expect(cubit.state.plannerProfile?.portfolioUrls, ['https://p']);
      expect(cubit.state.plannerProfile?.role, 'Planner');

      cubit.setDisplayName('');
      expect(cubit.state.plannerProfile?.displayName, isNull);

      cubit.setRole('');
      expect(cubit.state.plannerProfile?.role, isNull);

      await cubit.close();
    });

    test('save upserts planner profile and user', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(
          id: plannerId,
          email: 'p@test.com',
          displayName: 'Old',
        ),
      );
      when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
        (_) async =>
            const PlannerProfileEntity(userId: plannerId, displayName: 'Show'),
      );
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => plannerProfileRepo.upsertPlannerProfile(any()),
      ).thenAnswer((_) async {});
      when(() => userRepo.upsertUser(any())).thenAnswer((_) async {});

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.save();

      verify(() => plannerProfileRepo.upsertPlannerProfile(any())).called(1);
      verify(() => userRepo.upsertUser(any())).called(1);
      expect(cubit.state.isSaving, false);
      await cubit.close();
    });

    test('save emits error when upsert throws', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
      );
      when(() => plannerProfileRepo.getPlannerProfile(plannerId)).thenAnswer(
        (_) async =>
            const PlannerProfileEntity(userId: plannerId, displayName: 'X'),
      );
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => plannerProfileRepo.upsertPlannerProfile(any()),
      ).thenThrow(Exception('fail'));

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.save();

      expect(cubit.state.isSaving, false);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });

    test('setEventShowOnProfile updates event and reloads', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
      );
      when(
        () => plannerProfileRepo.getPlannerProfile(plannerId),
      ).thenAnswer((_) async => const PlannerProfileEntity(userId: plannerId));
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(() => eventRepo.updateEvent(any())).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as EventEntity,
      );

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final ev = EventEntity(
        id: 'e1',
        plannerId: plannerId,
        title: 'T',
        showOnProfile: false,
      );
      await cubit.setEventShowOnProfile(ev, true);

      verify(() => eventRepo.updateEvent(any())).called(1);
      await cubit.close();
    });

    test('setEventShowOnProfile emits error when update fails', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
      );
      when(
        () => plannerProfileRepo.getPlannerProfile(plannerId),
      ).thenAnswer((_) async => const PlannerProfileEntity(userId: plannerId));
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(() => eventRepo.updateEvent(any())).thenThrow(Exception('bad'));

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      await cubit.setEventShowOnProfile(
        EventEntity(id: 'e1', plannerId: plannerId, title: 'T'),
        true,
      );

      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });

    test('refresh calls load again', () async {
      when(() => userRepo.getUser(plannerId)).thenAnswer(
        (_) async => const UserEntity(id: plannerId, email: 'p@test.com'),
      );
      when(
        () => plannerProfileRepo.getPlannerProfile(plannerId),
      ).thenAnswer((_) async => const PlannerProfileEntity(userId: plannerId));
      when(
        () => eventRepo.fetchEventsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => bookingRepo.getCompletedBookingsByPlannerId(plannerId),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByTargetUserId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => collabRepo.getCollaborationsByRequesterId(
          plannerId,
          status: CollaborationStatus.completed,
        ),
      ).thenAnswer((_) async => const []);

      final cubit = PlannerProfileCubit(
        userRepo,
        eventRepo,
        bookingRepo,
        collabRepo,
        profileRepo,
        plannerProfileRepo,
        plannerId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await cubit.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      verify(() => userRepo.getUser(plannerId)).called(2);
      await cubit.close();
    });
  });
}
