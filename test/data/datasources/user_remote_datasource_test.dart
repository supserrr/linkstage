import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/user_remote_datasource.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';

void main() {
  group('UserRemoteDataSource', () {
    test('getUsersByIds chunks and returns existing users', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('u1').set({'email': 'u1@test.com'});
      await fake.collection('users').doc('u2').set({'email': 'u2@test.com'});

      final ids = List<String>.generate(35, (i) => 'u${i + 1}');
      final map = await ds.getUsersByIds(ids);

      expect(map.keys, containsAll(['u1', 'u2']));
      expect(map['u1']?.email, 'u1@test.com');
      expect(map['u2']?.email, 'u2@test.com');
    });

    test('checkUsernameAvailable honors excludeUserId', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('profiles').doc('taken').set({'userId': 'u1'});

      final availableOther = await ds.checkUsernameAvailable('taken');
      final availableSame = await ds.checkUsernameAvailable(
        'taken',
        excludeUserId: 'u1',
      );

      expect(availableOther, isFalse);
      expect(availableSame, isTrue);
    });

    test(
      'changeUsernameAtomic throws when username taken by different user',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = UserRemoteDataSource(firestore: fake);

        await fake.collection('profiles').doc('newname').set({
          'userId': 'other',
        });
        await fake.collection('users').doc('u1').set({'email': 'u1@test.com'});

        final profile = ProfileEntity(
          id: 'newname',
          userId: 'u1',
          username: 'newname',
          displayName: 'U1',
        );

        expect(
          () => ds.changeUsernameAtomic(
            'u1',
            'newname',
            'oldname',
            profile,
            DateTime.utc(2026, 1, 1),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('markNotificationAsRead creates notification_reads doc', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await ds.markNotificationAsRead('u1', 'n1');

      final doc = await fake
          .collection('users')
          .doc('u1')
          .collection('notification_reads')
          .doc('n1')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data(), contains('readAt'));
    });

    test('getUser returns null when missing', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);
      expect(await ds.getUser('none'), isNull);
    });

    test('getUser maps document', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('u99').set({
        'email': 'u99@test.com',
        'username': 'user99',
        'role': 'creativeProfessional',
      });

      final u = await ds.getUser('u99');
      expect(u?.email, 'u99@test.com');
      expect(u?.username, 'user99');
    });

    test('upsertUser merge writes user doc', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await ds.upsertUser(
        UserEntity(id: 'ux', email: 'ux@test.com', role: UserRole.eventPlanner),
      );

      final doc = await fake.collection('users').doc('ux').get();
      expect(doc.data()?['email'], 'ux@test.com');
    });

    test('updateUsername updates fields', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('uu').set({'email': 'a@b.com'});
      await ds.updateUsername('uu', 'NewName', DateTime.utc(2026, 4, 1));

      final doc = await fake.collection('users').doc('uu').get();
      expect(doc.data()?['username'], 'newname');
    });

    test('updateRole writes role key', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('ur').set({'email': 'a@b.com'});
      await ds.updateRole('ur', UserRole.eventPlanner);

      final doc = await fake.collection('users').doc('ur').get();
      expect(doc.data()?['role'], isNotNull);
    });

    test('updatePrivacySettings applies partial updates', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('up').set({'email': 'a@b.com'});
      await ds.updatePrivacySettings(
        'up',
        profileVisibility: ProfileVisibility.onlyMe,
        whoCanMessage: WhoCanMessage.workedWith,
        showOnlineStatus: false,
      );

      final doc = await fake.collection('users').doc('up').get();
      final data = doc.data();
      expect(data?['profileVisibility'], isNotNull);
      expect(data?['whoCanMessage'], isNotNull);
      expect(data?['showOnlineStatus'], false);
    });

    test('updatePrivacySettings no-op when empty', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('up2').set({'email': 'a@b.com'});
      await ds.updatePrivacySettings('up2');
      final doc = await fake.collection('users').doc('up2').get();
      expect(doc.data()?.length, 1);
    });

    test('updateLastSeen sets lastSeen', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('ls').set({'email': 'a@b.com'});
      await ds.updateLastSeen('ls');
      final doc = await fake.collection('users').doc('ls').get();
      expect(doc.data()?.containsKey('lastSeen'), isTrue);
    });

    test('watchUser emits mapped user', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('w1').set({'email': 'w@test.com'});

      final first = await ds.watchUser('w1').first;
      expect(first?.email, 'w@test.com');
    });

    test('markAllNotificationsAsRead batch writes', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await ds.markAllNotificationsAsRead('u1', ['a', 'b']);

      final a = await fake
          .collection('users')
          .doc('u1')
          .collection('notification_reads')
          .doc('a')
          .get();
      expect(a.exists, isTrue);
    });

    test('markAllNotificationsAsRead empty is no-op', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);
      await ds.markAllNotificationsAsRead('u1', []);
    });

    test('watchNotificationReadIds maps doc ids', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake
          .collection('users')
          .doc('r1')
          .collection('notification_reads')
          .doc('nid')
          .set({'readAt': FieldValue.serverTimestamp()});

      final ids = await ds.watchNotificationReadIds('r1').first;
      expect(ids, contains('nid'));
    });

    test('setFcmToken and removeFcmToken', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      const token = 'fcm-token-abc';
      await ds.setFcmToken('u-fcm', token);
      final col = fake
          .collection('users')
          .doc('u-fcm')
          .collection('device_tokens');
      final snaps = await col.get();
      expect(snaps.docs, isNotEmpty);

      await ds.removeFcmToken('u-fcm', token);
      final snaps2 = await col.get();
      expect(snaps2.docs, isEmpty);
    });

    test('changeUsernameAtomic succeeds when new doc is free', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake.collection('users').doc('owner').set({'email': 'o@test.com'});
      await fake.collection('profiles').doc('oldname').set({'userId': 'owner'});

      final profile = ProfileEntity(
        id: 'newname',
        userId: 'owner',
        username: 'newname',
        displayName: 'Owner',
      );

      await ds.changeUsernameAtomic(
        'owner',
        'newname',
        'oldname',
        profile,
        DateTime.utc(2026, 4, 1),
      );

      final newDoc = await fake.collection('profiles').doc('newname').get();
      expect(newDoc.exists, isTrue);
      expect(
        (await fake.collection('profiles').doc('oldname').get()).exists,
        isFalse,
      );
    });

    test('watchPlannerNewEventNotifications maps docs with id', () async {
      final fake = FakeFirebaseFirestore();
      final ds = UserRemoteDataSource(firestore: fake);

      await fake
          .collection('users')
          .doc('cr')
          .collection('planner_new_event_notifications')
          .doc('doc1')
          .set({
            'eventId': 'ev1',
            'plannerName': 'P',
            'eventTitle': 'E',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
          });

      final first = await ds.watchPlannerNewEventNotifications('cr').first;
      expect(first, hasLength(1));
      expect(first.single['id'], 'doc1');
      expect(first.single['eventId'], 'ev1');
    });
  });
}
