import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

/// Remote data source for bookings in Firestore.
class BookingRemoteDataSource {
  BookingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _bookingsCollection = 'bookings';

  static const String _statusCompleted = 'completed';
  static const String _statusPending = 'pending';

  /// Fetch pending bookings for a planner (applicants, recent proposals, per-event counts).
  Future<List<BookingEntity>> getPendingBookingsByPlannerId(
    String plannerId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: _statusPending)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch pending bookings (applications) for a creative.
  Future<List<BookingEntity>> getPendingBookingsByCreativeId(
    String creativeId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: _statusPending)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch accepted bookings for a creative (upcoming gigs, not yet completed).
  Future<List<BookingEntity>> getAcceptedBookingsByCreativeId(
    String creativeId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: 'accepted')
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch completed bookings for a creative (for total gigs count).
  Future<List<BookingEntity>> getCompletedBookingsByCreativeId(
    String creativeId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: _statusCompleted)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch completed bookings for a planner (to get recent creatives).
  Future<List<BookingEntity>> getCompletedBookingsByPlannerId(
    String plannerId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: _statusCompleted)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch accepted or completed bookings for a planner (creatives hired / worked with).
  Future<List<BookingEntity>> getAcceptedOrCompletedBookingsByPlannerId(
    String plannerId,
  ) async {
    final completed = await getCompletedBookingsByPlannerId(plannerId);
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: 'accepted')
        .get();
    final accepted = snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
    final result = List<BookingEntity>.from(completed);
    final seenIds = completed.map((b) => b.creativeId).toSet();
    for (final b in accepted) {
      if (!seenIds.contains(b.creativeId)) {
        result.add(b);
        seenIds.add(b.creativeId);
      }
    }
    return result;
  }

  /// Create a pending booking (creative applies to collaborate).
  Future<BookingEntity> createBooking({
    required String eventId,
    required String creativeId,
    required String plannerId,
  }) async {
    final alreadyApplied = await hasPendingBookingForEvent(eventId, creativeId);
    if (alreadyApplied) {
      throw Exception('You already applied to this gig');
    }

    final model = BookingModel(
      id: '',
      eventId: eventId,
      creativeId: creativeId,
      plannerId: plannerId,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );
    final ref = await _firestore
        .collection(_bookingsCollection)
        .add(model.toFirestore());
    return BookingEntity(
      id: ref.id,
      eventId: eventId,
      creativeId: creativeId,
      plannerId: plannerId,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// Create an invitation booking (planner invites creative to their event).
  Future<BookingEntity> createInvitation({
    required String eventId,
    required String creativeId,
    required String plannerId,
  }) async {
    final exists = await hasPendingBookingForEvent(eventId, creativeId);
    if (exists) {
      throw Exception('This creative is already invited or has applied');
    }
    final model = BookingModel(
      id: '',
      eventId: eventId,
      creativeId: creativeId,
      plannerId: plannerId,
      status: BookingStatus.invited,
      createdAt: DateTime.now(),
      wasInvitation: true,
    );
    final ref = await _firestore
        .collection(_bookingsCollection)
        .add(model.toFirestore());
    return BookingEntity(
      id: ref.id,
      eventId: eventId,
      creativeId: creativeId,
      plannerId: plannerId,
      status: BookingStatus.invited,
      createdAt: DateTime.now(),
    );
  }

  /// Fetch invited bookings for a creative (planner invited them).
  Future<List<BookingEntity>> getInvitedBookingsByCreativeId(
    String creativeId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: 'invited')
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch declined bookings for a creative.
  Future<List<BookingEntity>> getDeclinedBookingsByCreativeId(
    String creativeId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: 'declined')
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch invited bookings for an event.
  Future<List<BookingEntity>> getInvitedBookingsByEventId(
    String eventId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'invited')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Update booking status (e.g. accept, decline, invite, complete).
  /// When marking completed, also sets plannerConfirmedAt.
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final key = status == BookingStatus.pending
        ? _statusPending
        : status == BookingStatus.invited
        ? 'invited'
        : status == BookingStatus.accepted
        ? 'accepted'
        : status == BookingStatus.declined
        ? 'declined'
        : _statusCompleted;
    final updates = <String, dynamic>{'status': key};
    if (status == BookingStatus.completed) {
      updates['plannerConfirmedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore
        .collection(_bookingsCollection)
        .doc(bookingId)
        .update(updates);
  }

  /// Creative confirms they completed the work (sets creativeConfirmedAt).
  Future<void> confirmCompletionByCreative(String bookingId) async {
    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
      'creativeConfirmedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if creative has already applied to this event (any status).
  Future<bool> hasPendingBookingForEvent(
    String eventId,
    String creativeId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('eventId', isEqualTo: eventId)
        .where('creativeId', isEqualTo: creativeId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Fetch pending bookings (applicants) for an event.
  Future<List<BookingEntity>> getPendingBookingsByEventId(
    String eventId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: _statusPending)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch accepted bookings for an event.
  Future<List<BookingEntity>> getAcceptedBookingsByEventId(
    String eventId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'accepted')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Fetch completed bookings for an event.
  Future<List<BookingEntity>> getCompletedBookingsByEventId(
    String eventId,
  ) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: _statusCompleted)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => BookingModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Count pending bookings (applications) for an event.
  Future<int> getPendingBookingsCountByEventId(String eventId) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: _statusPending)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Batch fetch pending counts for multiple events. Returns map of eventId -> count.
  /// Uses whereIn (max 30 per query); chunks if needed.
  Future<Map<String, int>> getPendingBookingsCountByEventIds(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return {};
    final uniqueIds = eventIds.toSet().toList();
    final counts = <String, int>{};
    for (final id in uniqueIds) {
      counts[id] = 0;
    }
    const chunkSize = 30;
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunk = uniqueIds.skip(i).take(chunkSize).toList();
      final snapshot = await _firestore
          .collection(_bookingsCollection)
          .where('eventId', whereIn: chunk)
          .where('status', isEqualTo: _statusPending)
          .get();
      for (final doc in snapshot.docs) {
        final eventId = doc.data()['eventId'] as String?;
        if (eventId != null) {
          counts[eventId] = (counts[eventId] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// Stream of pending bookings for a planner (applicants, recent proposals).
  Stream<List<BookingEntity>> watchPendingBookingsByPlannerId(
    String plannerId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: _statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Stream of completed bookings for a creative (for gig list).
  Stream<List<BookingEntity>> watchCompletedBookingsByCreativeId(
    String creativeId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: _statusCompleted)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Stream of invited bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchInvitedBookingsByCreativeId(
    String creativeId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: 'invited')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Stream of accepted bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchAcceptedBookingsByCreativeId(
    String creativeId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Stream of declined bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchDeclinedBookingsByCreativeId(
    String creativeId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('creativeId', isEqualTo: creativeId)
        .where('status', isEqualTo: 'declined')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Stream of accepted invitation bookings for a planner (creative accepted).
  Stream<List<BookingEntity>> watchAcceptedInvitationBookingsByPlannerId(
    String plannerId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: 'accepted')
        .where('wasInvitation', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Stream of declined invitation bookings for a planner (creative declined).
  Stream<List<BookingEntity>> watchDeclinedInvitationBookingsByPlannerId(
    String plannerId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: 'declined')
        .where('wasInvitation', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .toList(),
        );
  }

  /// Accepted bookings from creative applications (excludes invitation flows).
  ///
  /// Firestore returns all accepted rows for the planner; we filter out
  /// `wasInvitation == true` client-side so older docs without the field stay
  /// included.
  Stream<List<BookingEntity>> watchAcceptedApplicationBookingsByPlannerId(
    String plannerId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('plannerId', isEqualTo: plannerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromFirestore(d).toEntity())
              .where((b) => b.wasInvitation != true)
              .toList(),
        );
  }
}
