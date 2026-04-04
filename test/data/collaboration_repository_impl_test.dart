import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/collaboration_remote_datasource.dart';
import 'package:linkstage/data/repositories/collaboration_repository_impl.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockCollaborationRemoteDataSource extends Mock
    implements CollaborationRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(CollaborationStatus.pending);
  });

  group('CollaborationRepositoryImpl', () {
    late MockCollaborationRemoteDataSource remote;
    late CollaborationRepositoryImpl repo;

    setUp(() {
      remote = MockCollaborationRemoteDataSource();
      repo = CollaborationRepositoryImpl(remote);
    });

    test(
      'completeAcceptedCollaborationsForEvent completes each accepted collab',
      () async {
        when(
          () => remote.getCollaborationsByEventId(
            any(),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => const [
            CollaborationEntity(
              id: 'c1',
              requesterId: 'r1',
              targetUserId: 't1',
              description: 'd',
              status: CollaborationStatus.accepted,
            ),
            CollaborationEntity(
              id: 'c2',
              requesterId: 'r1',
              targetUserId: 't2',
              description: 'd',
              status: CollaborationStatus.accepted,
            ),
          ],
        );
        when(
          () => remote.updateStatus(
            any(),
            any(),
            confirmingIsPlanner: any(named: 'confirmingIsPlanner'),
          ),
        ).thenAnswer((_) async {});

        await repo.completeAcceptedCollaborationsForEvent('event-1');

        verify(
          () => remote.getCollaborationsByEventId(
            'event-1',
            status: CollaborationStatus.accepted,
          ),
        ).called(1);
        verify(
          () => remote.updateStatus(
            'c1',
            CollaborationStatus.completed,
            confirmingIsPlanner: true,
          ),
        ).called(1);
        verify(
          () => remote.updateStatus(
            'c2',
            CollaborationStatus.completed,
            confirmingIsPlanner: true,
          ),
        ).called(1);
      },
    );
  });
}
