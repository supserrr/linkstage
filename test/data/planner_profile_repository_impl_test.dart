import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/planner_profile_remote_datasource.dart';
import 'package:linkstage/data/repositories/planner_profile_repository_impl.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPlannerProfileRemoteDataSource extends Mock
    implements PlannerProfileRemoteDataSource {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('PlannerProfileRepositoryImpl', () {
    late MockPlannerProfileRemoteDataSource remote;
    late MockUserRepository userRepository;
    late PlannerProfileRepositoryImpl repo;

    setUp(() {
      remote = MockPlannerProfileRemoteDataSource();
      userRepository = MockUserRepository();
      repo = PlannerProfileRepositoryImpl(remote, userRepository);
    });

    test('getPlannerProfile merges user photoUrl', () async {
      when(
        () => remote.getPlannerProfile('p1'),
      ).thenAnswer((_) async => const PlannerProfileEntity(userId: 'p1'));
      when(() => userRepository.getUser('p1')).thenAnswer(
        (_) async =>
            const UserEntity(id: 'p1', email: 'p1@x.com', photoUrl: 'u-photo'),
      );

      final profile = await repo.getPlannerProfile('p1');
      expect(profile, isNotNull);
      expect(profile!.photoUrl, 'u-photo');
    });

    test(
      'getPlannerProfiles filters out onlyMe and respects connectionsOnly',
      () async {
        when(
          () => remote.getPlannerProfiles(
            limit: any(named: 'limit'),
            excludeUserId: any(named: 'excludeUserId'),
          ),
        ).thenAnswer(
          (_) async => const [
            PlannerProfileEntity(
              userId: 'u1',
              profileVisibility: ProfileVisibility.onlyMe,
            ),
            PlannerProfileEntity(
              userId: 'u2',
              profileVisibility: ProfileVisibility.connectionsOnly,
            ),
            PlannerProfileEntity(
              userId: 'u3',
              profileVisibility: ProfileVisibility.everyone,
            ),
          ],
        );
        when(() => userRepository.getUsersByIds(any())).thenAnswer(
          (_) async => {
            'u1': const UserEntity(id: 'u1', email: 'u1@x.com'),
            'u2': const UserEntity(id: 'u2', email: 'u2@x.com'),
            'u3': const UserEntity(id: 'u3', email: 'u3@x.com'),
          },
        );
        when(
          () => userRepository.hasWorkedWith('viewer', 'u2'),
        ).thenAnswer((_) async => false);

        final list = await repo.getPlannerProfiles(excludeUserId: 'viewer');
        expect(list.map((p) => p.userId), ['u3']);
        verify(() => userRepository.hasWorkedWith('viewer', 'u2')).called(1);
      },
    );
  });
}
