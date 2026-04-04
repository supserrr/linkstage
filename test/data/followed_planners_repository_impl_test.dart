import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkstage/data/repositories/followed_planners_repository_impl.dart';
import 'package:linkstage/domain/repositories/planner_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPlannerProfileRepository extends Mock
    implements PlannerProfileRepository {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('FollowedPlannersRepositoryImpl', () {
    late MockPlannerProfileRepository plannerProfileRepository;
    late MockFirebaseFirestore firestore;
    late FollowedPlannersRepositoryImpl repo;

    setUp(() {
      plannerProfileRepository = MockPlannerProfileRepository();
      firestore = MockFirebaseFirestore();
      repo = FollowedPlannersRepositoryImpl(
        plannerProfileRepository,
        firestore: firestore,
      );
    });

    test('toggleFollow returns early when ids are empty', () async {
      await repo.toggleFollow('', 'p1');
      await repo.toggleFollow('c1', '');
      verifyNever(() => plannerProfileRepository.getPlannerProfile(any()));
    });

    test('addFollow returns early when ids are empty', () async {
      await repo.addFollow('', 'p1');
      await repo.addFollow('c1', '');
      verifyNever(() => plannerProfileRepository.getPlannerProfile(any()));
    });

    test(
      'watchFollowedPlannerIds returns empty set when creativeUserId empty',
      () async {
        final ids = await repo.watchFollowedPlannerIds('').first;
        expect(ids, <String>{});
      },
    );

    test(
      'getFollowedPlannerProfiles returns empty list when creativeUserId empty',
      () async {
        final profiles = await repo.getFollowedPlannerProfiles('');
        expect(profiles, isEmpty);
      },
    );
  });
}
