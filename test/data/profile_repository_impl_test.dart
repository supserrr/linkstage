import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/profile_remote_datasource.dart';
import 'package:linkstage/data/repositories/profile_repository_impl.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ProfileCategory.dj);
  });

  group('ProfileRepositoryImpl', () {
    late MockProfileRemoteDataSource remote;
    late MockUserRepository userRepository;
    late ProfileRepositoryImpl repo;

    setUp(() {
      remote = MockProfileRemoteDataSource();
      userRepository = MockUserRepository();
      repo = ProfileRepositoryImpl(remote, userRepository);
    });

    test('getProfiles merges photoUrl from user documents', () async {
      final controller = StreamController<List<ProfileEntity>>();
      when(
        () => remote.getProfiles(
          category: any(named: 'category'),
          location: any(named: 'location'),
          limit: any(named: 'limit'),
          excludeUserId: any(named: 'excludeUserId'),
        ),
      ).thenAnswer((_) => controller.stream);

      when(() => userRepository.getUsersByIds(any())).thenAnswer(
        (_) async => {
          'u1': const UserEntity(id: 'u1', email: 'u1@x.com', photoUrl: 'p1'),
        },
      );
      when(
        () => userRepository.hasWorkedWith(any(), any()),
      ).thenAnswer((_) async => true);

      final results = <List<ProfileEntity>>[];
      final sub = repo.getProfiles().listen(results.add);

      controller.add(const [
        ProfileEntity(id: 'p1', userId: 'u1', username: 'u1'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(results, hasLength(1));
      expect(results.single.single.photoUrl, 'p1');

      await sub.cancel();
      await controller.close();
    });

    test(
      'getProfiles filters to creative accounts when onlyCreativeAccounts=true',
      () async {
        when(
          () => remote.getProfiles(
            category: any(named: 'category'),
            location: any(named: 'location'),
            limit: any(named: 'limit'),
            excludeUserId: any(named: 'excludeUserId'),
          ),
        ).thenAnswer(
          (_) => Stream.value(const [
            ProfileEntity(id: 'p1', userId: 'u1', username: 'u1'),
            ProfileEntity(id: 'p2', userId: 'u2', username: 'u2'),
          ]),
        );
        when(() => userRepository.getUsersByIds(any())).thenAnswer(
          (_) async => {
            'u1': const UserEntity(
              id: 'u1',
              email: 'u1@x.com',
              role: UserRole.creativeProfessional,
            ),
            'u2': const UserEntity(
              id: 'u2',
              email: 'u2@x.com',
              role: UserRole.eventPlanner,
            ),
          },
        );
        when(
          () => userRepository.hasWorkedWith(any(), any()),
        ).thenAnswer((_) async => true);

        final list = await repo.getProfiles(onlyCreativeAccounts: true).first;
        expect(list.map((p) => p.userId), ['u1']);
      },
    );

    test(
      'getProfiles enforces connectionsOnly visibility when excludeUserId set',
      () async {
        when(
          () => remote.getProfiles(
            category: any(named: 'category'),
            location: any(named: 'location'),
            limit: any(named: 'limit'),
            excludeUserId: any(named: 'excludeUserId'),
          ),
        ).thenAnswer(
          (_) => Stream.value(const [
            ProfileEntity(
              id: 'p1',
              userId: 'u1',
              username: 'u1',
              profileVisibility: ProfileVisibility.connectionsOnly,
            ),
            ProfileEntity(
              id: 'p2',
              userId: 'u2',
              username: 'u2',
              profileVisibility: ProfileVisibility.everyone,
            ),
          ]),
        );
        when(() => userRepository.getUsersByIds(any())).thenAnswer(
          (_) async => {
            'u1': const UserEntity(id: 'u1', email: 'u1@x.com'),
            'u2': const UserEntity(id: 'u2', email: 'u2@x.com'),
          },
        );
        when(
          () => userRepository.hasWorkedWith('viewer', 'u1'),
        ).thenAnswer((_) async => false);

        final list = await repo.getProfiles(excludeUserId: 'viewer').first;
        expect(list.map((p) => p.userId), ['u2']);
        verify(() => userRepository.hasWorkedWith('viewer', 'u1')).called(1);
      },
    );
  });
}
