import '../entities/event_entity.dart';

/// Abstract contract for event operations.
abstract class EventRepository {
  /// Stream of events for a planner.
  Stream<List<EventEntity>> getEventsByPlannerId(String plannerId);

  /// One-time fetch of events for a planner.
  Future<List<EventEntity>> fetchEventsByPlannerId(String plannerId);

  /// Fetch a single event by ID.
  Future<EventEntity?> getEventById(String eventId);

  /// Fetch multiple events by IDs. Returns only existing events.
  Future<List<EventEntity>> getEventsByIds(List<String> eventIds);

  /// Fetch open events for discovery (e.g. creative home).
  Future<List<EventEntity>> fetchOpenEvents({int limit = 20});

  /// Fetch discoverable events for search (open + booked, excludes draft/completed).
  Future<List<EventEntity>> fetchDiscoverableEvents({int limit = 50});

  /// Create a new event.
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
  });

  /// Update an existing event.
  Future<EventEntity> updateEvent(EventEntity event);

  /// Update only the status of an event (e.g. publish/unpublish).
  Future<void> updateEventStatus(String eventId, EventStatus status);

  /// Delete an event.
  Future<void> deleteEvent(String eventId);
}
