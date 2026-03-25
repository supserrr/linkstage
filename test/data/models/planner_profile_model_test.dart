import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/models/planner_profile_model.dart';
import 'package:linkstage/domain/entities/user_entity.dart'
    show ProfileVisibility;

void main() {
  test('fromFirestore maps fields and toFirestore round-trips', () async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('planner_profiles').doc('u1').set({
      'userId': 'u1',
      'bio': 'bio',
      'location': 'Kigali',
      'eventTypes': ['wedding'],
      'languages': ['en'],
      'portfolioUrls': ['https://x.com'],
      'displayName': 'P',
      'role': 'planner',
      'profileVisibility': 'only_me',
    });

    final doc = await fake.collection('planner_profiles').doc('u1').get();
    final model = PlannerProfileModel.fromFirestore(doc);
    expect(model.userId, 'u1');
    expect(model.bio, 'bio');
    expect(model.eventTypes, ['wedding']);
    expect(model.profileVisibility, ProfileVisibility.onlyMe);

    final map = model.toFirestore();
    expect(map['bio'], 'bio');

    final entity = model.toEntity();
    expect(entity.userId, 'u1');
  });
}
