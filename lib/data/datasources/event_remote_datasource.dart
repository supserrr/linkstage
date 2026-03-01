import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event_entity.dart';
import '../models/event_model.dart';

/// Remote data source for events in Firestore.
class EventRemoteDataSource {
  EventRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _eventsCollection = 'events';

  /// Stream of events for a planner.
  Stream<List<EventEntity>> getEventsByPlannerId(String plannerId) {
    return _firestore
        .collection(_eventsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => EventModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// One-time fetch of events for a planner.
  Future<List<EventEntity>> fetchEventsByPlannerId(String plannerId) async {
    final snapshot = await _firestore
        .collection(_eventsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((d) => EventModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch open events for discovery (e.g. creative home, search).
  /// Does not use orderBy in the query so events with null/missing date
  /// are included; results are sorted by date in Dart (nulls last).
  Future<List<EventEntity>> fetchOpenEvents({int limit = 20}) async {
    final snapshot = await _firestore
        .collection(_eventsCollection)
        .where('status', isEqualTo: 'open')
        .limit(limit)
        .get();
    final list = snapshot.docs
        .map((d) => EventModel.fromFirestore(d).toEntity())
        .toList();
    list.sort((a, b) {
      final da = a.date;
      final db = b.date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  /// Fetch discoverable events for search (open + booked, excludes draft/completed).
  /// Does not use orderBy in the query so events with null/missing date are
  /// included; results are sorted by date in Dart (nulls last).
  Future<List<EventEntity>> fetchDiscoverableEvents({int limit = 50}) async {
    final snapshot = await _firestore
        .collection(_eventsCollection)
        .where('status', whereIn: ['open', 'booked'])
        .limit(limit)
        .get();
    final list = snapshot.docs
        .map((d) => EventModel.fromFirestore(d).toEntity())
        .toList();
    list.sort((a, b) {
      final da = a.date;
      final db = b.date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

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
  }) async {
    final model = EventModel(
      id: '',
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
    final ref = await _firestore
        .collection(_eventsCollection)
        .add(model.toFirestore());
    return EventEntity(
      id: ref.id,
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
      showOnProfile: true,
      locationVisibility: locationVisibility,
    );
  }

  /// Update an existing event.
  Future<EventEntity> updateEvent(EventEntity event) async {
    final model = EventModel(
      id: event.id,
      plannerId: event.plannerId,
      title: event.title,
      date: event.date,
      location: event.location,
      description: event.description,
      status: event.status,
      imageUrls: event.imageUrls,
      eventType: event.eventType,
      budget: event.budget,
      startTime: event.startTime,
      endTime: event.endTime,
      venueName: event.venueName,
      showOnProfile: event.showOnProfile,
      locationVisibility: event.locationVisibility,
    );
    await _firestore
        .collection(_eventsCollection)
        .doc(event.id)
        .update(model.toFirestore());
    return event;
  }

  /// Fetch a single event by ID.
  Future<EventEntity?> getEventById(String eventId) async {
    final doc = await _firestore.collection(_eventsCollection).doc(eventId).get();
    if (doc.exists && doc.data() != null) {
      return EventModel.fromFirestore(doc).toEntity();
    }
    return null;
  }

  /// Fetch multiple events by IDs. Returns only existing events.
  /// Uses parallel get() per chunk (Flutter SDK has no getAll).
  Future<List<EventEntity>> getEventsByIds(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    final uniqueIds = eventIds.toSet().where((id) => id.isNotEmpty).toList();
    if (uniqueIds.isEmpty) return [];
    const chunkSize = 30;
    final results = <EventEntity>[];
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunk = uniqueIds.skip(i).take(chunkSize).toList();
      final refs =
          chunk.map((id) => _firestore.collection(_eventsCollection).doc(id));
      final docs = await Future.wait(refs.map((ref) => ref.get()));
      for (final doc in docs) {
        if (doc.exists && doc.data() != null) {
          results.add(EventModel.fromFirestore(doc).toEntity());
        }
      }
    }
    return results;
  }

  /// Update only the status of an event.
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _firestore.collection(_eventsCollection).doc(eventId).update({
      'status': _statusKey(status),
    });
  }

  /// Delete an event.
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(_eventsCollection).doc(eventId).delete();
  }

  String _statusKey(EventStatus s) {
    switch (s) {
      case EventStatus.draft:
        return 'draft';
      case EventStatus.open:
        return 'open';
      case EventStatus.booked:
        return 'booked';
      case EventStatus.completed:
        return 'completed';
    }
  }
}
