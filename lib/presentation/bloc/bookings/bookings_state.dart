import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/user_entity.dart';

class BookingsState {
  const BookingsState({
    this.invited = const [],
    this.applications = const [],
    this.accepted = const [],
    this.completed = const [],
    this.collaborations = const [],
    this.events = const {},
    this.requesterNames = const {},
    this.requesterPhotoUrls = const {},
    this.requesterRoles = const {},
    this.confirmingBookingId,
    this.loading = true,
    this.error,
  });

  final List<BookingEntity> invited;
  final List<BookingEntity> applications;
  final List<BookingEntity> accepted;
  final List<BookingEntity> completed;
  final List<CollaborationEntity> collaborations;
  final Map<String, EventEntity?> events;
  final Map<String, String> requesterNames;
  final Map<String, String?> requesterPhotoUrls;
  final Map<String, UserRole?> requesterRoles;
  final String? confirmingBookingId;
  final bool loading;
  final String? error;

  BookingsState copyWith({
    List<BookingEntity>? invited,
    List<BookingEntity>? applications,
    List<BookingEntity>? accepted,
    List<BookingEntity>? completed,
    List<CollaborationEntity>? collaborations,
    Map<String, EventEntity?>? events,
    Map<String, String>? requesterNames,
    Map<String, String?>? requesterPhotoUrls,
    Map<String, UserRole?>? requesterRoles,
    String? confirmingBookingId,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearConfirming = false,
  }) {
    return BookingsState(
      invited: invited ?? this.invited,
      applications: applications ?? this.applications,
      accepted: accepted ?? this.accepted,
      completed: completed ?? this.completed,
      collaborations: collaborations ?? this.collaborations,
      events: events ?? this.events,
      requesterNames: requesterNames ?? this.requesterNames,
      requesterPhotoUrls: requesterPhotoUrls ?? this.requesterPhotoUrls,
      requesterRoles: requesterRoles ?? this.requesterRoles,
      confirmingBookingId: clearConfirming
          ? null
          : (confirmingBookingId ?? this.confirmingBookingId),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
