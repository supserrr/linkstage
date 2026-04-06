import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/booking_remote_datasource.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';

void main() {
  group('BookingRemoteDataSource', () {
    test('getPendingBookingsByCreativeId maps documents', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-1').set({
        'eventId': 'evt-1',
        'creativeId': 'cr-1',
        'plannerId': 'pl-1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final list = await ds.getPendingBookingsByCreativeId('cr-1');

      expect(list, hasLength(1));
      expect(list.single.id, 'bk-1');
      expect(list.single.eventId, 'evt-1');
      expect(list.single.creativeId, 'cr-1');
      expect(list.single.plannerId, 'pl-1');
      expect(list.single.status, BookingStatus.pending);
    });

    test('getCompletedBookingsByCreativeId maps documents', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-2').set({
        'eventId': 'evt-2',
        'creativeId': 'cr-2',
        'plannerId': 'pl-2',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
      });

      final list = await ds.getCompletedBookingsByCreativeId('cr-2');

      expect(list, hasLength(1));
      expect(list.single.status, BookingStatus.completed);
    });

    test('getInvitedBookingsByCreativeId maps invited status', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-inv').set({
        'eventId': 'evt-i',
        'creativeId': 'cr-i',
        'plannerId': 'pl-i',
        'status': 'invited',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 3, 1)),
      });

      final list = await ds.getInvitedBookingsByCreativeId('cr-i');

      expect(list, hasLength(1));
      expect(list.single.status, BookingStatus.invited);
    });

    test('getAcceptedBookingsByCreativeId maps accepted status', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-acc').set({
        'eventId': 'evt-a',
        'creativeId': 'cr-a',
        'plannerId': 'pl-a',
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 4, 1)),
      });

      final list = await ds.getAcceptedBookingsByCreativeId('cr-a');

      expect(list, hasLength(1));
      expect(list.single.status, BookingStatus.accepted);
    });

    test('createBooking writes document; duplicate apply throws', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      final first = await ds.createBooking(
        eventId: 'ev-x',
        creativeId: 'cr-x',
        plannerId: 'pl-x',
      );
      expect(first.status, BookingStatus.pending);

      expect(
        () => ds.createBooking(
          eventId: 'ev-x',
          creativeId: 'cr-x',
          plannerId: 'pl-x',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'getAcceptedOrCompletedBookingsByPlannerId merges creatives',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('done-1').set({
          'eventId': 'e1',
          'creativeId': 'c1',
          'plannerId': 'pl-m',
          'status': 'completed',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });
        await fake.collection('bookings').doc('acc-1').set({
          'eventId': 'e2',
          'creativeId': 'c2',
          'plannerId': 'pl-m',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
        });

        final list = await ds.getAcceptedOrCompletedBookingsByPlannerId('pl-m');

        expect(list.map((b) => b.creativeId).toSet(), {'c1', 'c2'});
      },
    );

    test('updateBookingStatus sets completed and plannerConfirmedAt', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-up').set({
        'eventId': 'e1',
        'creativeId': 'c1',
        'plannerId': 'p1',
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      await ds.updateBookingStatus('bk-up', BookingStatus.completed);
      final snap = await fake.collection('bookings').doc('bk-up').get();
      expect(snap.data()?['status'], 'completed');
      expect(snap.data()?.containsKey('plannerConfirmedAt'), isTrue);
    });

    test('getDeclinedBookingsByCreativeId maps declined status', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-dec').set({
        'eventId': 'evt-d',
        'creativeId': 'cr-d',
        'plannerId': 'pl-d',
        'status': 'declined',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 5, 1)),
      });

      final list = await ds.getDeclinedBookingsByCreativeId('cr-d');

      expect(list, hasLength(1));
      expect(list.single.status, BookingStatus.declined);
    });

    test(
      'getPendingBookingsByEventId returns applications for event',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('bk-ev').set({
          'eventId': 'evt-e',
          'creativeId': 'cr-e',
          'plannerId': 'pl-e',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 1)),
        });

        final list = await ds.getPendingBookingsByEventId('evt-e');

        expect(list, hasLength(1));
        expect(list.single.eventId, 'evt-e');
      },
    );

    test('getInvitedBookingsByEventId returns invited for event', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-inv-ev').set({
        'eventId': 'evt-i',
        'creativeId': 'cr-i',
        'plannerId': 'pl-i',
        'status': 'invited',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 2)),
      });

      final list = await ds.getInvitedBookingsByEventId('evt-i');

      expect(list, hasLength(1));
      expect(list.single.status, BookingStatus.invited);
    });

    test('createInvitation writes invited; duplicate throws', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      final first = await ds.createInvitation(
        eventId: 'ev-inv',
        creativeId: 'cr-inv',
        plannerId: 'pl-inv',
      );
      expect(first.status, BookingStatus.invited);

      expect(
        () => ds.createInvitation(
          eventId: 'ev-inv',
          creativeId: 'cr-inv',
          plannerId: 'pl-inv',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('confirmCompletionByCreative sets creativeConfirmedAt', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-cc').set({
        'eventId': 'e1',
        'creativeId': 'c1',
        'plannerId': 'p1',
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      await ds.confirmCompletionByCreative('bk-cc');
      final snap = await fake.collection('bookings').doc('bk-cc').get();
      expect(snap.data()?.containsKey('creativeConfirmedAt'), isTrue);
    });

    test('hasPendingBookingForEvent is true when doc exists', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('bk-h').set({
        'eventId': 'ev-h',
        'creativeId': 'cr-h',
        'plannerId': 'pl-h',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      expect(await ds.hasPendingBookingForEvent('ev-h', 'cr-h'), isTrue);
      expect(await ds.hasPendingBookingForEvent('ev-other', 'cr-h'), isFalse);
    });

    test('getPendingBookingsCountByEventIds aggregates per event', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('a').set({
        'eventId': 'ev-c1',
        'creativeId': 'c1',
        'plannerId': 'p1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });
      await fake.collection('bookings').doc('b').set({
        'eventId': 'ev-c1',
        'creativeId': 'c2',
        'plannerId': 'p1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
      });
      await fake.collection('bookings').doc('c').set({
        'eventId': 'ev-c2',
        'creativeId': 'c3',
        'plannerId': 'p1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 3)),
      });

      final counts = await ds.getPendingBookingsCountByEventIds([
        'ev-c1',
        'ev-c2',
        'ev-missing',
      ]);

      expect(counts['ev-c1'], 2);
      expect(counts['ev-c2'], 1);
      expect(counts['ev-missing'], 0);
    });

    test('watchInvitedBookingsByCreativeId emits mapped list', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('w1').set({
        'eventId': 'e-w',
        'creativeId': 'cr-w',
        'plannerId': 'pl-w',
        'status': 'invited',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final first = await ds.watchInvitedBookingsByCreativeId('cr-w').first;

      expect(first, hasLength(1));
      expect(first.single.status, BookingStatus.invited);
    });

    test('getPendingBookingsByPlannerId orders by createdAt', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('a').set({
        'eventId': 'e1',
        'creativeId': 'c1',
        'plannerId': 'pl-x',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });
      await fake.collection('bookings').doc('b').set({
        'eventId': 'e2',
        'creativeId': 'c2',
        'plannerId': 'pl-x',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
      });

      final list = await ds.getPendingBookingsByPlannerId('pl-x');

      expect(list, hasLength(2));
      expect(list.first.createdAt!.isAfter(list.last.createdAt!), isTrue);
    });

    test('getCompletedBookingsByPlannerId maps completed rows', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('done').set({
        'eventId': 'e1',
        'creativeId': 'c1',
        'plannerId': 'pl-m',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final list = await ds.getCompletedBookingsByPlannerId('pl-m');
      expect(list, hasLength(1));
      expect(list.single.status, BookingStatus.completed);
    });

    test(
      'getAcceptedBookingsByEventId and getCompletedBookingsByEventId',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('acc').set({
          'eventId': 'ev-1',
          'creativeId': 'c1',
          'plannerId': 'p1',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });
        await fake.collection('bookings').doc('cmp').set({
          'eventId': 'ev-1',
          'creativeId': 'c2',
          'plannerId': 'p1',
          'status': 'completed',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
        });

        final accepted = await ds.getAcceptedBookingsByEventId('ev-1');
        final completed = await ds.getCompletedBookingsByEventId('ev-1');
        expect(accepted.map((b) => b.creativeId), contains('c1'));
        expect(completed.map((b) => b.creativeId), contains('c2'));
      },
    );

    test(
      'updateBookingStatus maps pending, invited, accepted, declined',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('bk-1').set({
          'eventId': 'e1',
          'creativeId': 'c1',
          'plannerId': 'p1',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });

        await ds.updateBookingStatus('bk-1', BookingStatus.pending);
        var snap = await fake.collection('bookings').doc('bk-1').get();
        expect(snap.data()?['status'], 'pending');

        await ds.updateBookingStatus('bk-1', BookingStatus.invited);
        snap = await fake.collection('bookings').doc('bk-1').get();
        expect(snap.data()?['status'], 'invited');

        await ds.updateBookingStatus('bk-1', BookingStatus.declined);
        snap = await fake.collection('bookings').doc('bk-1').get();
        expect(snap.data()?['status'], 'declined');

        await ds.updateBookingStatus('bk-1', BookingStatus.accepted);
        snap = await fake.collection('bookings').doc('bk-1').get();
        expect(snap.data()?['status'], 'accepted');
      },
    );

    test('watchPendingBookingsByPlannerId emits list', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('w-p').set({
        'eventId': 'e1',
        'creativeId': 'c1',
        'plannerId': 'pl-w',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final first = await ds.watchPendingBookingsByPlannerId('pl-w').first;
      expect(first, hasLength(1));
    });

    test('watchCompletedBookingsByCreativeId emits list', () async {
      final fake = FakeFirebaseFirestore();
      final ds = BookingRemoteDataSource(firestore: fake);

      await fake.collection('bookings').doc('w-c').set({
        'eventId': 'e1',
        'creativeId': 'cr-c',
        'plannerId': 'p1',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final first = await ds.watchCompletedBookingsByCreativeId('cr-c').first;
      expect(first.single.status, BookingStatus.completed);
    });

    test(
      'watchAcceptedBookingsByCreativeId and watchDeclinedBookingsByCreativeId',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('acc').set({
          'eventId': 'e1',
          'creativeId': 'cr-a',
          'plannerId': 'p1',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });
        await fake.collection('bookings').doc('dec').set({
          'eventId': 'e2',
          'creativeId': 'cr-d',
          'plannerId': 'p1',
          'status': 'declined',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
        });

        final acc = await ds.watchAcceptedBookingsByCreativeId('cr-a').first;
        final dec = await ds.watchDeclinedBookingsByCreativeId('cr-d').first;
        expect(acc.single.status, BookingStatus.accepted);
        expect(dec.single.status, BookingStatus.declined);
      },
    );

    test(
      'watchAcceptedInvitationBookingsByPlannerId filters wasInvitation',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('inv-acc').set({
          'eventId': 'e1',
          'creativeId': 'c1',
          'plannerId': 'pl-inv',
          'status': 'accepted',
          'wasInvitation': true,
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });

        final first = await ds
            .watchAcceptedInvitationBookingsByPlannerId('pl-inv')
            .first;
        expect(first, hasLength(1));
        expect(first.single.wasInvitation, isTrue);
      },
    );

    test(
      'watchDeclinedInvitationBookingsByPlannerId maps declined invites',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('inv-dec').set({
          'eventId': 'e1',
          'creativeId': 'c1',
          'plannerId': 'pl-d',
          'status': 'declined',
          'wasInvitation': true,
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });

        final first = await ds
            .watchDeclinedInvitationBookingsByPlannerId('pl-d')
            .first;
        expect(first.single.status, BookingStatus.declined);
      },
    );

    test(
      'watchAcceptedApplicationBookingsByPlannerId excludes invitations',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = BookingRemoteDataSource(firestore: fake);

        await fake.collection('bookings').doc('app').set({
          'eventId': 'e1',
          'creativeId': 'c1',
          'plannerId': 'pl-a',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });
        await fake.collection('bookings').doc('inv').set({
          'eventId': 'e2',
          'creativeId': 'c2',
          'plannerId': 'pl-a',
          'status': 'accepted',
          'wasInvitation': true,
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
        });

        final first = await ds
            .watchAcceptedApplicationBookingsByPlannerId('pl-a')
            .first;
        expect(first, hasLength(1));
        expect(first.single.creativeId, 'c1');
      },
    );
  });
}
