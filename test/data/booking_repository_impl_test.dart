import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/booking_remote_datasource.dart';
import 'package:linkstage/data/repositories/booking_repository_impl.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingRemoteDataSource extends Mock
    implements BookingRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(BookingStatus.pending);
  });

  group('BookingRepositoryImpl', () {
    late MockBookingRemoteDataSource remote;
    late BookingRepositoryImpl repo;

    setUp(() {
      remote = MockBookingRemoteDataSource();
      repo = BookingRepositoryImpl(remote);
    });

    test(
      'completeAcceptedBookingsForEvent completes each accepted booking',
      () async {
        when(() => remote.getAcceptedBookingsByEventId(any())).thenAnswer(
          (_) async => const [
            BookingEntity(
              id: 'b1',
              eventId: 'e1',
              creativeId: 'c1',
              plannerId: 'p1',
              status: BookingStatus.accepted,
            ),
            BookingEntity(
              id: 'b2',
              eventId: 'e1',
              creativeId: 'c2',
              plannerId: 'p1',
              status: BookingStatus.accepted,
            ),
          ],
        );
        when(
          () => remote.updateBookingStatus(any(), any()),
        ).thenAnswer((_) async {});

        await repo.completeAcceptedBookingsForEvent('e1');

        verify(() => remote.getAcceptedBookingsByEventId('e1')).called(1);
        verify(
          () => remote.updateBookingStatus('b1', BookingStatus.completed),
        ).called(1);
        verify(
          () => remote.updateBookingStatus('b2', BookingStatus.completed),
        ).called(1);
      },
    );

    test('forwards every repository method to remote', () async {
      const empty = <BookingEntity>[];
      final sample = BookingEntity(
        id: 'b1',
        eventId: 'e1',
        creativeId: 'c1',
        plannerId: 'p1',
        status: BookingStatus.pending,
      );

      when(
        () => remote.getCompletedBookingsByCreativeId('c'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getCompletedBookingsByPlannerId('p'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getAcceptedOrCompletedBookingsByPlannerId('p'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getPendingBookingsByPlannerId('p'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getPendingBookingsByCreativeId('c'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getAcceptedBookingsByCreativeId('c'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getPendingBookingsCountByEventId('e'),
      ).thenAnswer((_) async => 0);
      when(
        () => remote.getPendingBookingsCountByEventIds(['e']),
      ).thenAnswer((_) async => {'e': 0});
      when(
        () => remote.getPendingBookingsByEventId('e'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getAcceptedBookingsByEventId('e'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getCompletedBookingsByEventId('e'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.createBooking(
          eventId: any(named: 'eventId'),
          creativeId: any(named: 'creativeId'),
          plannerId: any(named: 'plannerId'),
        ),
      ).thenAnswer((_) async => sample);
      when(
        () => remote.createInvitation(
          eventId: any(named: 'eventId'),
          creativeId: any(named: 'creativeId'),
          plannerId: any(named: 'plannerId'),
        ),
      ).thenAnswer((_) async => sample);
      when(
        () => remote.getInvitedBookingsByCreativeId('c'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getDeclinedBookingsByCreativeId('c'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.getInvitedBookingsByEventId('e'),
      ).thenAnswer((_) async => empty);
      when(
        () => remote.hasPendingBookingForEvent('e', 'c'),
      ).thenAnswer((_) async => false);
      when(
        () => remote.updateBookingStatus(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => remote.confirmCompletionByCreative('b1'),
      ).thenAnswer((_) async {});

      when(
        () => remote.watchPendingBookingsByPlannerId('p'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchCompletedBookingsByCreativeId('c'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchInvitedBookingsByCreativeId('c'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchAcceptedBookingsByCreativeId('c'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchDeclinedBookingsByCreativeId('c'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchAcceptedInvitationBookingsByPlannerId('p'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchDeclinedInvitationBookingsByPlannerId('p'),
      ).thenAnswer((_) => Stream.value(empty));
      when(
        () => remote.watchAcceptedApplicationBookingsByPlannerId('p'),
      ).thenAnswer((_) => Stream.value(empty));

      expect(await repo.getCompletedBookingsByCreativeId('c'), empty);
      expect(await repo.getCompletedBookingsByPlannerId('p'), empty);
      expect(await repo.getAcceptedOrCompletedBookingsByPlannerId('p'), empty);
      expect(await repo.getPendingBookingsByPlannerId('p'), empty);
      expect(await repo.getPendingBookingsByCreativeId('c'), empty);
      expect(await repo.getAcceptedBookingsByCreativeId('c'), empty);
      expect(await repo.getPendingBookingsCountByEventId('e'), 0);
      expect(await repo.getPendingBookingsCountByEventIds(['e']), {'e': 0});
      expect(await repo.getPendingBookingsByEventId('e'), empty);
      expect(await repo.getAcceptedBookingsByEventId('e'), empty);
      expect(await repo.getCompletedBookingsByEventId('e'), empty);

      await repo.createBooking(
        eventId: 'e1',
        creativeId: 'c1',
        plannerId: 'p1',
      );
      await repo.createInvitation(
        eventId: 'e1',
        creativeId: 'c1',
        plannerId: 'p1',
      );
      expect(await repo.getInvitedBookingsByCreativeId('c'), empty);
      expect(await repo.getDeclinedBookingsByCreativeId('c'), empty);
      expect(await repo.getInvitedBookingsByEventId('e'), empty);
      expect(await repo.hasPendingBookingForEvent('e', 'c'), isFalse);
      await repo.updateBookingStatus('b1', BookingStatus.accepted);
      await repo.confirmCompletionByCreative('b1');

      await repo.watchPendingBookingsByPlannerId('p').first;
      await repo.watchCompletedBookingsByCreativeId('c').first;
      await repo.watchInvitedBookingsByCreativeId('c').first;
      await repo.watchAcceptedBookingsByCreativeId('c').first;
      await repo.watchDeclinedBookingsByCreativeId('c').first;
      await repo.watchAcceptedInvitationBookingsByPlannerId('p').first;
      await repo.watchDeclinedInvitationBookingsByPlannerId('p').first;
      await repo.watchAcceptedApplicationBookingsByPlannerId('p').first;

      verify(() => remote.getCompletedBookingsByCreativeId('c')).called(1);
      verify(() => remote.getCompletedBookingsByPlannerId('p')).called(1);
      verify(
        () => remote.getAcceptedOrCompletedBookingsByPlannerId('p'),
      ).called(1);
      verify(() => remote.getPendingBookingsByPlannerId('p')).called(1);
      verify(() => remote.getPendingBookingsByCreativeId('c')).called(1);
      verify(() => remote.getAcceptedBookingsByCreativeId('c')).called(1);
      verify(() => remote.getPendingBookingsCountByEventId('e')).called(1);
      verify(() => remote.getPendingBookingsCountByEventIds(['e'])).called(1);
      verify(() => remote.getPendingBookingsByEventId('e')).called(1);
      verify(() => remote.getAcceptedBookingsByEventId('e')).called(1);
      verify(() => remote.getCompletedBookingsByEventId('e')).called(1);
      verify(
        () => remote.createBooking(
          eventId: 'e1',
          creativeId: 'c1',
          plannerId: 'p1',
        ),
      ).called(1);
      verify(
        () => remote.createInvitation(
          eventId: 'e1',
          creativeId: 'c1',
          plannerId: 'p1',
        ),
      ).called(1);
      verify(() => remote.getInvitedBookingsByCreativeId('c')).called(1);
      verify(() => remote.getDeclinedBookingsByCreativeId('c')).called(1);
      verify(() => remote.getInvitedBookingsByEventId('e')).called(1);
      verify(() => remote.hasPendingBookingForEvent('e', 'c')).called(1);
      verify(
        () => remote.updateBookingStatus('b1', BookingStatus.accepted),
      ).called(1);
      verify(() => remote.confirmCompletionByCreative('b1')).called(1);
      verify(() => remote.watchPendingBookingsByPlannerId('p')).called(1);
      verify(() => remote.watchCompletedBookingsByCreativeId('c')).called(1);
      verify(() => remote.watchInvitedBookingsByCreativeId('c')).called(1);
      verify(() => remote.watchAcceptedBookingsByCreativeId('c')).called(1);
      verify(() => remote.watchDeclinedBookingsByCreativeId('c')).called(1);
      verify(
        () => remote.watchAcceptedInvitationBookingsByPlannerId('p'),
      ).called(1);
      verify(
        () => remote.watchDeclinedInvitationBookingsByPlannerId('p'),
      ).called(1);
      verify(
        () => remote.watchAcceptedApplicationBookingsByPlannerId('p'),
      ).called(1);
    });
  });
}
