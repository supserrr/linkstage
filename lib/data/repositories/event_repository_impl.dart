import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';

/// Implementation of [EventRepository] using Firestore.
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._remote);

  final EventRemoteDataSource _remote;

  @override
  Stream<List<EventEntity>> getEventsByPlannerId(String plannerId) =>
      _remote.getEventsByPlannerId(plannerId);

  @override
  Future<List<EventEntity>> fetchEventsByPlannerId(String plannerId) =>
      _remote.fetchEventsByPlannerId(plannerId);

  @override
  Future<EventEntity?> getEventById(String eventId) =>
      _remote.getEventById(eventId);

  @override
  Future<List<EventEntity>> getEventsByIds(List<String> eventIds) =>
      _remote.getEventsByIds(eventIds);

  @override
  Future<List<EventEntity>> fetchOpenEvents({int limit = 20}) =>
      _remote.fetchOpenEvents(limit: limit);

  @override
  Future<List<EventEntity>> fetchDiscoverableEvents({int limit = 50}) =>
      _remote.fetchDiscoverableEvents(limit: limit);

  @override
  Future<EventEntity> createEvent({
    required String plannerId,
    required String title,
    DateTime? date,
    String location = '',
    String description = '',
    EventStatus status = EventStatus.draft,
    List<String> imageUrls = const [],
    String eventType = '',
    double? budget,
    String startTime = '',
    String endTime = '',
    String venueName = '',
    LocationVisibility locationVisibility = LocationVisibility.public,
  }) => _remote.createEvent(
    plannerId: plannerId,
    title: title,
    date: date,
    location: location,
    description: description,
    status: status,
    imageUrls: imageUrls,
    eventType: eventType,
    budget: budget,
    startTime: startTime,
    endTime: endTime,
    venueName: venueName,
    locationVisibility: locationVisibility,
  );

  @override
  Future<EventEntity> updateEvent(EventEntity event) =>
      _remote.updateEvent(event);

  @override
  Future<void> updateEventStatus(String eventId, EventStatus status) =>
      _remote.updateEventStatus(eventId, status);

  @override
  Future<void> deleteEvent(String eventId) => _remote.deleteEvent(eventId);
}
