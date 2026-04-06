import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/collaboration_remote_datasource.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';

void main() {
  group('CollaborationRemoteDataSource', () {
    test('createCollaboration creates doc and returns entity', () async {
      final fake = FakeFirebaseFirestore();
      final ds = CollaborationRemoteDataSource(firestore: fake);

      final created = await ds.createCollaboration(
        requesterId: 'planner-1',
        targetUserId: 'creative-1',
        description: 'Test',
        title: 'Proposal',
      );

      expect(created.id, isNotEmpty);
      expect(created.requesterId, 'planner-1');
      expect(created.targetUserId, 'creative-1');
      expect(created.status, CollaborationStatus.pending);
    });

    test(
      'createCollaboration prevents duplicate active collaborations',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = CollaborationRemoteDataSource(firestore: fake);

        await ds.createCollaboration(
          requesterId: 'planner-1',
          targetUserId: 'creative-1',
          description: 'First',
        );

        expect(
          () => ds.createCollaboration(
            requesterId: 'planner-1',
            targetUserId: 'creative-1',
            description: 'Second',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('updateStatus writes status + confirmation timestamp', () async {
      final fake = FakeFirebaseFirestore();
      final ds = CollaborationRemoteDataSource(firestore: fake);

      final created = await ds.createCollaboration(
        requesterId: 'planner-1',
        targetUserId: 'creative-1',
        description: 'Test',
      );

      await ds.updateStatus(
        created.id,
        CollaborationStatus.completed,
        confirmingIsPlanner: true,
      );

      final doc = await fake.collection('collaborations').doc(created.id).get();
      expect(doc.data()?['status'], 'completed');
      expect(doc.data(), contains('plannerConfirmedAt'));
    });

    test(
      'hasActiveCollaborationBetween returns true for pending/accepted',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = CollaborationRemoteDataSource(firestore: fake);

        await ds.createCollaboration(
          requesterId: 'planner-1',
          targetUserId: 'creative-1',
          description: 'Test',
        );

        final exists = await ds.hasActiveCollaborationBetween(
          'planner-1',
          'creative-1',
        );
        expect(exists, isTrue);
      },
    );

    test(
      'getCollaborationsByTargetUserId with optional status filter',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = CollaborationRemoteDataSource(firestore: fake);

        await fake.collection('collaborations').doc('c1').set({
          'requesterId': 'p1',
          'targetUserId': 't1',
          'description': 'Hi',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });

        final all = await ds.getCollaborationsByTargetUserId('t1');
        expect(all, hasLength(1));

        final pendingOnly = await ds.getCollaborationsByTargetUserId(
          't1',
          status: CollaborationStatus.pending,
        );
        expect(pendingOnly, hasLength(1));

        final acceptedOnly = await ds.getCollaborationsByTargetUserId(
          't1',
          status: CollaborationStatus.accepted,
        );
        expect(acceptedOnly, isEmpty);
      },
    );

    test(
      'getCollaborationsByEventId and getCollaborationsByRequesterId',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = CollaborationRemoteDataSource(firestore: fake);

        await fake.collection('collaborations').doc('ev1').set({
          'requesterId': 'p1',
          'targetUserId': 't1',
          'description': 'For event',
          'eventId': 'event-99',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
        });

        final byEvent = await ds.getCollaborationsByEventId('event-99');
        expect(byEvent.single.eventId, 'event-99');

        final byReq = await ds.getCollaborationsByRequesterId('p1');
        expect(byReq.single.requesterId, 'p1');
      },
    );

    test(
      'watchCollaborationsByTargetUserId and watchCollaborationsByRequesterId',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = CollaborationRemoteDataSource(firestore: fake);

        await fake.collection('collaborations').doc('w1').set({
          'requesterId': 'pr',
          'targetUserId': 'tg',
          'description': 'W',
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        });

        final t = await ds.watchCollaborationsByTargetUserId('tg').first;
        expect(t, hasLength(1));

        final r = await ds.watchCollaborationsByRequesterId('pr').first;
        expect(r, hasLength(1));
      },
    );

    test(
      'updateStatus completed sets creativeConfirmedAt when planner false',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = CollaborationRemoteDataSource(firestore: fake);

        final created = await ds.createCollaboration(
          requesterId: 'p1',
          targetUserId: 'c1',
          description: 'D',
        );

        await ds.updateStatus(
          created.id,
          CollaborationStatus.completed,
          confirmingIsPlanner: false,
        );

        final doc = await fake
            .collection('collaborations')
            .doc(created.id)
            .get();
        expect(doc.data(), contains('creativeConfirmedAt'));
      },
    );

    test('confirmCompletionByCreative sets timestamp', () async {
      final fake = FakeFirebaseFirestore();
      final ds = CollaborationRemoteDataSource(firestore: fake);

      final created = await ds.createCollaboration(
        requesterId: 'p1',
        targetUserId: 'c1',
        description: 'D',
      );

      await ds.confirmCompletionByCreative(created.id);
      final doc = await fake.collection('collaborations').doc(created.id).get();
      expect(doc.data(), contains('creativeConfirmedAt'));
    });

    test('hasExistingCollaboration delegates to active check', () async {
      final fake = FakeFirebaseFirestore();
      final ds = CollaborationRemoteDataSource(firestore: fake);

      await ds.createCollaboration(
        requesterId: 'a',
        targetUserId: 'b',
        description: 'x',
      );

      expect(await ds.hasExistingCollaboration('a', 'b'), isTrue);
    });

    test('_hasActiveBetween detects reverse requester/target', () async {
      final fake = FakeFirebaseFirestore();
      final ds = CollaborationRemoteDataSource(firestore: fake);

      await fake.collection('collaborations').doc('rev').set({
        'requesterId': 'u2',
        'targetUserId': 'u1',
        'description': 'R',
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      });

      expect(await ds.hasActiveCollaborationBetween('u1', 'u2'), isTrue);
    });

    test('createCollaboration stores optional fields', () async {
      final fake = FakeFirebaseFirestore();
      final ds = CollaborationRemoteDataSource(firestore: fake);

      final created = await ds.createCollaboration(
        requesterId: 'p1',
        targetUserId: 'c1',
        description: 'Full',
        title: 'T',
        eventId: 'ev',
        budget: 99.5,
        date: DateTime.utc(2026, 6, 1),
        startTime: '10:00',
        endTime: '12:00',
        location: 'Here',
        eventType: 'Gala',
      );

      expect(created.title, 'T');
      expect(created.eventId, 'ev');
      expect(created.budget, 99.5);
      final snap = await fake
          .collection('collaborations')
          .doc(created.id)
          .get();
      expect(snap.data()?['eventType'], 'Gala');
    });
  });
}
