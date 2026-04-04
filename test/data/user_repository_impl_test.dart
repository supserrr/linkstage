import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/user_remote_datasource.dart';
import 'package:linkstage/data/repositories/user_repository_impl.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/booking_repository.dart';
import 'package:linkstage/domain/repositories/collaboration_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockCollaborationRepository extends Mock
    implements CollaborationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(CollaborationStatus.pending);
  });

  group('UserRepositoryImpl', () {
    late MockUserRemoteDataSource remote;
    late MockBookingRepository bookingRepository;
    late MockCollaborationRepository collaborationRepository;
    late UserRepositoryImpl repo;

    setUp(() {
      remote = MockUserRemoteDataSource();
      bookingRepository = MockBookingRepository();
      collaborationRepository = MockCollaborationRepository();
      repo = UserRepositoryImpl(
        remote,
        bookingRepository,
        collaborationRepository,
      );
    });

    group('hasWorkedWith', () {
      test('returns false when either id is empty', () async {
        expect(await repo.hasWorkedWith('', 'u2'), false);
        expect(await repo.hasWorkedWith('u1', ''), false);
      });

      test(
        'returns true when user1 has completed booking with user2 as planner',
        () async {
          when(
            () => bookingRepository.getCompletedBookingsByCreativeId('u1'),
          ).thenAnswer(
            (_) async => const [
              BookingEntity(
                id: 'b1',
                eventId: 'e1',
                creativeId: 'u1',
                plannerId: 'u2',
                status: BookingStatus.completed,
              ),
            ],
          );
          when(
            () => bookingRepository.getCompletedBookingsByCreativeId('u2'),
          ).thenAnswer((_) async => const []);
          when(
            () => collaborationRepository.getCollaborationsByTargetUserId(
              any(),
              status: any(named: 'status'),
            ),
          ).thenAnswer((_) async => const []);
          when(
            () => collaborationRepository.getCollaborationsByRequesterId(
              any(),
              status: any(named: 'status'),
            ),
          ).thenAnswer((_) async => const []);

          expect(await repo.hasWorkedWith('u1', 'u2'), true);
        },
      );
    });

    group('canSendMessageTo', () {
      test('returns false when senderId or recipientId empty', () async {
        expect(await repo.canSendMessageTo('', 'u2'), false);
        expect(await repo.canSendMessageTo('u1', ''), false);
      });

      test('returns true when sender messages self', () async {
        expect(await repo.canSendMessageTo('u1', 'u1'), true);
      });

      test('returns false when recipient whoCanMessage is noOne', () async {
        when(() => remote.getUser('u2')).thenAnswer(
          (_) async => const UserEntity(
            id: 'u2',
            email: 'u2@x.com',
            whoCanMessage: WhoCanMessage.noOne,
          ),
        );

        expect(await repo.canSendMessageTo('u1', 'u2'), false);
      });

      test(
        'uses hasWorkedWith when recipient whoCanMessage is workedWith',
        () async {
          when(() => remote.getUser('u2')).thenAnswer(
            (_) async => const UserEntity(
              id: 'u2',
              email: 'u2@x.com',
              whoCanMessage: WhoCanMessage.workedWith,
            ),
          );
          when(
            () => bookingRepository.getCompletedBookingsByCreativeId(any()),
          ).thenAnswer((_) async => const []);
          when(
            () => collaborationRepository.getCollaborationsByTargetUserId(
              any(),
              status: any(named: 'status'),
            ),
          ).thenAnswer((_) async => const []);
          when(
            () => collaborationRepository.getCollaborationsByRequesterId(
              any(),
              status: any(named: 'status'),
            ),
          ).thenAnswer((_) async => const []);

          final allowed = await repo.canSendMessageTo('u1', 'u2');
          expect(allowed, false);
          verify(() => remote.getUser('u2')).called(1);
        },
      );
    });
  });
}
