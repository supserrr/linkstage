import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/event_remote_datasource.dart';
import 'package:linkstage/domain/entities/event_entity.dart';

void main() {
  group('EventRemoteDataSource (FakeFirestore)', () {
    test('getEventById returns entity when document exists', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('e-1').set({
        'plannerId': 'p-1',
        'title': 'Gala',
        'status': 'open',
        'location': 'Kigali',
      });

      final event = await ds.getEventById('e-1');

      expect(event, isNotNull);
      expect(event!.id, 'e-1');
      expect(event.title, 'Gala');
      expect(event.plannerId, 'p-1');
      expect(event.status, EventStatus.open);
    });

    test('getEventById returns null when missing', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      final event = await ds.getEventById('missing');

      expect(event, isNull);
    });

    test('fetchEventsByPlannerId returns ordered list', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('old').set({
        'plannerId': 'pl-1',
        'title': 'Old',
        'status': 'draft',
        'date': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });
      await fake.collection('events').doc('new').set({
        'plannerId': 'pl-1',
        'title': 'New',
        'status': 'open',
        'date': Timestamp.fromDate(DateTime.utc(2026, 6, 1)),
      });

      final list = await ds.fetchEventsByPlannerId('pl-1');
      expect(list, hasLength(2));
      expect(list.first.title, 'New');
    });

    test('getEventsByPlannerId stream emits mapped events', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('s1').set({
        'plannerId': 'pl-s',
        'title': 'Stream',
        'status': 'open',
        'date': Timestamp.fromDate(DateTime.utc(2026, 3, 1)),
      });

      final first = await ds.getEventsByPlannerId('pl-s').first;
      expect(first, hasLength(1));
      expect(first.single.title, 'Stream');
    });

    test('fetchOpenEvents sorts null dates last', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('a').set({
        'plannerId': 'p',
        'title': 'No date',
        'status': 'open',
      });
      await fake.collection('events').doc('b').set({
        'plannerId': 'p',
        'title': 'With date',
        'status': 'open',
        'date': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
      });

      final list = await ds.fetchOpenEvents(limit: 10);
      expect(list.first.title, 'With date');
      expect(list.last.title, 'No date');
    });

    test('fetchDiscoverableEvents includes open and booked', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('o').set({
        'plannerId': 'p',
        'title': 'Open',
        'status': 'open',
      });
      await fake.collection('events').doc('bk').set({
        'plannerId': 'p',
        'title': 'Booked',
        'status': 'booked',
        'date': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      final list = await ds.fetchDiscoverableEvents(limit: 20);
      final titles = list.map((e) => e.title).toSet();
      expect(titles, containsAll(['Open', 'Booked']));
    });

    test('createEvent adds document and returns entity', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      final created = await ds.createEvent(
        plannerId: 'pl-new',
        title: 'Created',
        status: EventStatus.draft,
      );

      expect(created.id, isNotEmpty);
      expect(created.title, 'Created');
      final snap = await fake.collection('events').doc(created.id).get();
      expect(snap.data()?['title'], 'Created');
    });

    test('updateEvent writes Firestore', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('e-up').set({
        'plannerId': 'pl-1',
        'title': 'Before',
        'status': 'draft',
      });

      final entity = EventEntity(
        id: 'e-up',
        plannerId: 'pl-1',
        title: 'After',
        status: EventStatus.open,
      );
      final out = await ds.updateEvent(entity);
      expect(out.title, 'After');
      final snap = await fake.collection('events').doc('e-up').get();
      expect(snap.data()?['title'], 'After');
    });

    test('getEventsByIds chunks and skips missing', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('ex1').set({
        'plannerId': 'p',
        'title': 'One',
        'status': 'open',
      });

      final list = await ds.getEventsByIds(['', 'ex1', 'missing']);
      expect(list, hasLength(1));
      expect(list.single.id, 'ex1');
    });

    test('getEventsByIds empty returns empty', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);
      expect(await ds.getEventsByIds([]), isEmpty);
    });

    test('updateEventStatus writes status key', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('e-st').set({
        'plannerId': 'p',
        'title': 'T',
        'status': 'draft',
      });

      await ds.updateEventStatus('e-st', EventStatus.completed);
      final snap = await fake.collection('events').doc('e-st').get();
      expect(snap.data()?['status'], 'completed');
    });

    test('deleteEvent removes bookings and event', () async {
      final fake = FakeFirebaseFirestore();
      final ds = EventRemoteDataSource(firestore: fake);

      await fake.collection('events').doc('e-del').set({
        'plannerId': 'p',
        'title': 'Del',
        'status': 'draft',
      });
      await fake.collection('bookings').doc('b1').set({
        'eventId': 'e-del',
        'creativeId': 'c1',
        'plannerId': 'p',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      await ds.deleteEvent('e-del');

      expect(
        (await fake.collection('bookings').doc('b1').get()).exists,
        isFalse,
      );
      expect(
        (await fake.collection('events').doc('e-del').get()).exists,
        isFalse,
      );
    });
  });
}
