import '../entities/booking_entity.dart';

/// Abstract contract for booking operations.
abstract class BookingRepository {
  /// Fetch completed bookings for a creative (for total gigs count).
  Future<List<BookingEntity>> getCompletedBookingsByCreativeId(
    String creativeId,
  );

  /// Fetch completed bookings for a planner.
  Future<List<BookingEntity>> getCompletedBookingsByPlannerId(String plannerId);

  /// Fetch accepted or completed bookings for a planner (creatives hired / worked with).
  Future<List<BookingEntity>> getAcceptedOrCompletedBookingsByPlannerId(
    String plannerId,
  );

  /// Fetch pending bookings for a planner (applicants, recent proposals).
  Future<List<BookingEntity>> getPendingBookingsByPlannerId(String plannerId);

  /// Fetch pending bookings (applications) for a creative.
  Future<List<BookingEntity>> getPendingBookingsByCreativeId(String creativeId);

  /// Fetch accepted bookings for a creative (upcoming gigs).
  Future<List<BookingEntity>> getAcceptedBookingsByCreativeId(
    String creativeId,
  );

  /// Count pending bookings (applications) for an event.
  Future<int> getPendingBookingsCountByEventId(String eventId);

  /// Batch fetch pending counts for multiple events. Returns map of eventId -> count.
  Future<Map<String, int>> getPendingBookingsCountByEventIds(
    List<String> eventIds,
  );

  /// Fetch pending bookings (applicants) for an event.
  Future<List<BookingEntity>> getPendingBookingsByEventId(String eventId);

  /// Fetch accepted bookings for an event (for showing Message option).
  Future<List<BookingEntity>> getAcceptedBookingsByEventId(String eventId);

  /// Fetch completed bookings for an event (for showing Leave review option).
  Future<List<BookingEntity>> getCompletedBookingsByEventId(String eventId);

  /// Create a pending booking (creative applies to collaborate).
  Future<BookingEntity> createBooking({
    required String eventId,
    required String creativeId,
    required String plannerId,
  });

  /// Create an invitation booking (planner invites creative to their event).
  Future<BookingEntity> createInvitation({
    required String eventId,
    required String creativeId,
    required String plannerId,
  });

  /// Fetch invited bookings for a creative.
  Future<List<BookingEntity>> getInvitedBookingsByCreativeId(String creativeId);

  /// Fetch declined bookings for a creative.
  Future<List<BookingEntity>> getDeclinedBookingsByCreativeId(
    String creativeId,
  );

  /// Fetch invited bookings for an event.
  Future<List<BookingEntity>> getInvitedBookingsByEventId(String eventId);

  /// Check if creative has already applied to this event.
  Future<bool> hasPendingBookingForEvent(String eventId, String creativeId);

  /// Update booking status (e.g. planner accepts or declines an application).
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);

  /// Mark all accepted bookings for an event as completed (cascade when event is completed).
  Future<void> completeAcceptedBookingsForEvent(String eventId);

  /// Creative confirms they completed the work (sets creativeConfirmedAt).
  Future<void> confirmCompletionByCreative(String bookingId);

  /// Stream of pending bookings for a planner (real-time updates).
  Stream<List<BookingEntity>> watchPendingBookingsByPlannerId(String plannerId);

  /// Stream of completed bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchCompletedBookingsByCreativeId(
    String creativeId,
  );

  /// Stream of invited bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchInvitedBookingsByCreativeId(
    String creativeId,
  );

  /// Stream of accepted bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchAcceptedBookingsByCreativeId(
    String creativeId,
  );

  /// Stream of declined bookings for a creative (real-time updates).
  Stream<List<BookingEntity>> watchDeclinedBookingsByCreativeId(
    String creativeId,
  );

  /// Stream of accepted invitation bookings for a planner (creative accepted).
  Stream<List<BookingEntity>> watchAcceptedInvitationBookingsByPlannerId(
    String plannerId,
  );

  /// Stream of declined invitation bookings for a planner (creative declined).
  Stream<List<BookingEntity>> watchDeclinedInvitationBookingsByPlannerId(
    String plannerId,
  );
}
