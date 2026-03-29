import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/user_entity.dart';

class EventApplicantsState {
  const EventApplicantsState({
    required this.eventId,
    this.event,
    this.applicants = const [],
    this.creativeUsers = const {},
    this.loading = true,
    this.error,
    this.acceptingBookingId,
    this.rejectingBookingId,
    this.completingBookingId,
    this.hasReviewedByBookingId = const {},
  });

  final String eventId;
  final EventEntity? event;
  final List<BookingEntity> applicants;
  final Map<String, UserEntity> creativeUsers;
  final bool loading;
  final String? error;
  final String? acceptingBookingId;
  final String? rejectingBookingId;
  final String? completingBookingId;
  final Map<String, bool> hasReviewedByBookingId;

  EventApplicantsState copyWith({
    EventEntity? event,
    List<BookingEntity>? applicants,
    Map<String, UserEntity>? creativeUsers,
    bool? loading,
    String? error,
    String? acceptingBookingId,
    String? rejectingBookingId,
    String? completingBookingId,
    Map<String, bool>? hasReviewedByBookingId,
    bool clearError = false,
    bool clearAccepting = false,
    bool clearRejecting = false,
    bool clearCompleting = false,
  }) {
    return EventApplicantsState(
      eventId: eventId,
      event: event ?? this.event,
      applicants: applicants ?? this.applicants,
      creativeUsers: creativeUsers ?? this.creativeUsers,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      acceptingBookingId: clearAccepting
          ? null
          : (acceptingBookingId ?? this.acceptingBookingId),
      rejectingBookingId: clearRejecting
          ? null
          : (rejectingBookingId ?? this.rejectingBookingId),
      completingBookingId: clearCompleting
          ? null
          : (completingBookingId ?? this.completingBookingId),
      hasReviewedByBookingId:
          hasReviewedByBookingId ?? this.hasReviewedByBookingId,
    );
  }
}
