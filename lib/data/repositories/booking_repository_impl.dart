import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

/// Implementation of [BookingRepository] using Firestore.
class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  @override
  Future<List<BookingEntity>> getCompletedBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.getCompletedBookingsByCreativeId(creativeId);

  @override
  Future<List<BookingEntity>> getCompletedBookingsByPlannerId(
    String plannerId,
  ) =>
      _remote.getCompletedBookingsByPlannerId(plannerId);

  @override
  Future<List<BookingEntity>> getAcceptedOrCompletedBookingsByPlannerId(
    String plannerId,
  ) =>
      _remote.getAcceptedOrCompletedBookingsByPlannerId(plannerId);

  @override
  Future<List<BookingEntity>> getPendingBookingsByPlannerId(
    String plannerId,
  ) =>
      _remote.getPendingBookingsByPlannerId(plannerId);

  @override
  Future<List<BookingEntity>> getPendingBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.getPendingBookingsByCreativeId(creativeId);

  @override
  Future<List<BookingEntity>> getAcceptedBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.getAcceptedBookingsByCreativeId(creativeId);

  @override
  Future<int> getPendingBookingsCountByEventId(String eventId) =>
      _remote.getPendingBookingsCountByEventId(eventId);

  @override
  Future<Map<String, int>> getPendingBookingsCountByEventIds(
    List<String> eventIds,
  ) =>
      _remote.getPendingBookingsCountByEventIds(eventIds);

  @override
  Future<List<BookingEntity>> getPendingBookingsByEventId(String eventId) =>
      _remote.getPendingBookingsByEventId(eventId);

  @override
  Future<List<BookingEntity>> getAcceptedBookingsByEventId(String eventId) =>
      _remote.getAcceptedBookingsByEventId(eventId);

  @override
  Future<List<BookingEntity>> getCompletedBookingsByEventId(String eventId) =>
      _remote.getCompletedBookingsByEventId(eventId);

  @override
  Future<BookingEntity> createBooking({
    required String eventId,
    required String creativeId,
    required String plannerId,
  }) =>
      _remote.createBooking(
        eventId: eventId,
        creativeId: creativeId,
        plannerId: plannerId,
      );

  @override
  Future<BookingEntity> createInvitation({
    required String eventId,
    required String creativeId,
    required String plannerId,
  }) =>
      _remote.createInvitation(
        eventId: eventId,
        creativeId: creativeId,
        plannerId: plannerId,
      );

  @override
  Future<List<BookingEntity>> getInvitedBookingsByCreativeId(String creativeId) =>
      _remote.getInvitedBookingsByCreativeId(creativeId);

  @override
  Future<List<BookingEntity>> getDeclinedBookingsByCreativeId(String creativeId) =>
      _remote.getDeclinedBookingsByCreativeId(creativeId);

  @override
  Future<List<BookingEntity>> getInvitedBookingsByEventId(String eventId) =>
      _remote.getInvitedBookingsByEventId(eventId);

  @override
  Future<bool> hasPendingBookingForEvent(String eventId, String creativeId) =>
      _remote.hasPendingBookingForEvent(eventId, creativeId);

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) =>
      _remote.updateBookingStatus(bookingId, status);

  @override
  Future<void> completeAcceptedBookingsForEvent(String eventId) async {
    final accepted = await _remote.getAcceptedBookingsByEventId(eventId);
    for (final b in accepted) {
      await _remote.updateBookingStatus(b.id, BookingStatus.completed);
    }
  }

  @override
  Future<void> confirmCompletionByCreative(String bookingId) =>
      _remote.confirmCompletionByCreative(bookingId);

  @override
  Stream<List<BookingEntity>> watchPendingBookingsByPlannerId(
    String plannerId,
  ) =>
      _remote.watchPendingBookingsByPlannerId(plannerId);

  @override
  Stream<List<BookingEntity>> watchCompletedBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.watchCompletedBookingsByCreativeId(creativeId);

  @override
  Stream<List<BookingEntity>> watchInvitedBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.watchInvitedBookingsByCreativeId(creativeId);

  @override
  Stream<List<BookingEntity>> watchAcceptedBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.watchAcceptedBookingsByCreativeId(creativeId);

  @override
  Stream<List<BookingEntity>> watchDeclinedBookingsByCreativeId(
    String creativeId,
  ) =>
      _remote.watchDeclinedBookingsByCreativeId(creativeId);

  @override
  Stream<List<BookingEntity>> watchAcceptedInvitationBookingsByPlannerId(
    String plannerId,
  ) =>
      _remote.watchAcceptedInvitationBookingsByPlannerId(plannerId);

  @override
  Stream<List<BookingEntity>> watchDeclinedInvitationBookingsByPlannerId(
    String plannerId,
  ) =>
      _remote.watchDeclinedInvitationBookingsByPlannerId(plannerId);
}
