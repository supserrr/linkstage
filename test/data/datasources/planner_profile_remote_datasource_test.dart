import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/planner_profile_remote_datasource.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';

void main() {
  test('getPlannerProfile returns null when missing', () async {
    final fake = FakeFirebaseFirestore();
    final ds = PlannerProfileRemoteDataSource(firestore: fake);
    expect(await ds.getPlannerProfile('none'), isNull);
  });

  test('getPlannerProfile maps document', () async {
    final fake = FakeFirebaseFirestore();
    final ds = PlannerProfileRemoteDataSource(firestore: fake);

    await fake.collection('planner_profiles').doc('u1').set({
      'userId': 'u1',
      'bio': 'Hello',
      'location': 'Here',
      'eventTypes': <String>[],
      'languages': <String>[],
      'portfolioUrls': <String>[],
    });

    final p = await ds.getPlannerProfile('u1');
    expect(p?.bio, 'Hello');
  });

  test('getPlannerProfiles respects excludeUserId', () async {
    final fake = FakeFirebaseFirestore();
    final ds = PlannerProfileRemoteDataSource(firestore: fake);

    await fake.collection('planner_profiles').doc('a').set({
      'userId': 'a',
      'bio': '',
      'location': '',
      'eventTypes': <String>[],
      'languages': <String>[],
      'portfolioUrls': <String>[],
    });
    await fake.collection('planner_profiles').doc('b').set({
      'userId': 'b',
      'bio': '',
      'location': '',
      'eventTypes': <String>[],
      'languages': <String>[],
      'portfolioUrls': <String>[],
    });

    final list = await ds.getPlannerProfiles(limit: 10, excludeUserId: 'a');
    expect(list.every((e) => e.userId != 'a'), isTrue);
  });

  test('upsertPlannerProfile writes merge', () async {
    final fake = FakeFirebaseFirestore();
    final ds = PlannerProfileRemoteDataSource(firestore: fake);

    await ds.upsertPlannerProfile(
      PlannerProfileEntity(
        userId: 'ux',
        bio: 'B',
        location: 'L',
        eventTypes: const ['x'],
        languages: const ['en'],
        portfolioUrls: const [],
      ),
    );

    final snap = await fake.collection('planner_profiles').doc('ux').get();
    expect(snap.data()?['bio'], 'B');
  });
}
