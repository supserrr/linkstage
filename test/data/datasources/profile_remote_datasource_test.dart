import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/profile_remote_datasource.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';

void main() {
  group('ProfileRemoteDataSource', () {
    test('getProfileByUserId returns first match', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ProfileRemoteDataSource(firestore: fake);

      await fake.collection('profiles').doc('u1').set({
        'userId': 'user-1',
        'username': 'u1',
        'displayName': 'Name',
      });

      final p = await ds.getProfileByUserId('user-1');
      expect(p, isNotNull);
      expect(p!.userId, 'user-1');
    });

    test('getProfiles excludes userId when excludeUserId set', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ProfileRemoteDataSource(firestore: fake);

      await fake.collection('profiles').doc('a').set({
        'userId': 'u1',
        'username': 'a',
        'displayName': 'A',
      });
      await fake.collection('profiles').doc('b').set({
        'userId': 'u2',
        'username': 'b',
        'displayName': 'B',
      });

      final list = await ds.getProfiles(limit: 20, excludeUserId: 'u1').first;

      expect(list.any((p) => p.userId == 'u1'), isFalse);
      expect(list.any((p) => p.userId == 'u2'), isTrue);
    });

    test(
      'upsertProfile writes normalized doc id and getProfile reads it',
      () async {
        final fake = FakeFirebaseFirestore();
        final ds = ProfileRemoteDataSource(firestore: fake);

        await ds.upsertProfile(
          const ProfileEntity(
            id: 'UserName',
            userId: 'u1',
            username: 'UserName',
            displayName: 'Name',
          ),
        );

        final p = await ds.getProfile('USERNAME');
        expect(p, isNotNull);
        expect(p!.id, 'username');
        expect(p.username?.toLowerCase(), 'username');
      },
    );

    test('getProfilesByUserIds chunks and returns matches', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ProfileRemoteDataSource(firestore: fake);

      await fake.collection('profiles').doc('u1').set({
        'userId': 'u1',
        'username': 'u1',
        'displayName': 'U1',
      });
      await fake.collection('profiles').doc('u2').set({
        'userId': 'u2',
        'username': 'u2',
        'displayName': 'U2',
      });

      final ids = List<String>.generate(35, (i) => 'u${i + 1}');
      final list = await ds.getProfilesByUserIds(ids);

      expect(list.map((p) => p.userId), containsAll(['u1', 'u2']));
    });

    test('updateProfileRatingStats updates rating fields', () async {
      final fake = FakeFirebaseFirestore();
      final ds = ProfileRemoteDataSource(firestore: fake);

      await fake.collection('profiles').doc('u1').set({
        'userId': 'u1',
        'username': 'u1',
        'displayName': 'U1',
        'rating': 0.0,
        'reviewCount': 0,
      });

      await ds.updateProfileRatingStats('U1', 4.2, 10);

      final doc = await fake.collection('profiles').doc('u1').get();
      expect(doc.data()?['rating'], 4.2);
      expect(doc.data()?['reviewCount'], 10);
    });
  });
}
