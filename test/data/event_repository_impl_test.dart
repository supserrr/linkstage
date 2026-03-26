import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/event_remote_datasource.dart';
import 'package:linkstage/data/repositories/event_repository_impl.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRemoteDataSource extends Mock implements EventRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(EventStatus.draft);
    registerFallbackValue(LocationVisibility.public);
  });

  group('EventRepositoryImpl', () {
    late MockEventRemoteDataSource remote;
    late EventRepositoryImpl repo;

    setUp(() {
      remote = MockEventRemoteDataSource();
      repo = EventRepositoryImpl(remote);
    });

    test('createEvent delegates to remote with provided params', () async {
      when(
        () => remote.createEvent(
          plannerId: any(named: 'plannerId'),
          title: any(named: 'title'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          description: any(named: 'description'),
          status: any(named: 'status'),
          imageUrls: any(named: 'imageUrls'),
          eventType: any(named: 'eventType'),
          budget: any(named: 'budget'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          venueName: any(named: 'venueName'),
          locationVisibility: any(named: 'locationVisibility'),
        ),
      ).thenAnswer(
        (_) async => const EventEntity(
          id: 'e1',
          plannerId: 'p1',
          title: 'T',
          showOnProfile: true,
        ),
      );

      final event = await repo.createEvent(
        plannerId: 'p1',
        title: 'T',
        location: 'Kigali',
        status: EventStatus.open,
        locationVisibility: LocationVisibility.private,
      );

      expect(event.id, 'e1');
      verify(
        () => remote.createEvent(
          plannerId: 'p1',
          title: 'T',
          date: null,
          location: 'Kigali',
          description: '',
          status: EventStatus.open,
          imageUrls: const [],
          eventType: '',
          budget: null,
          startTime: '',
          endTime: '',
          venueName: '',
          locationVisibility: LocationVisibility.private,
        ),
      ).called(1);
    });
  });
}
