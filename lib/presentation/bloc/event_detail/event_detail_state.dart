import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/planner_profile_entity.dart';
import '../../../domain/entities/user_entity.dart';

/// State for event detail page.
class EventDetailState {
  const EventDetailState({
    this.event,
    this.planner,
    this.plannerProfile,
    this.applicationCount = 0,
    this.applicantPhotoUrls = const [],
    this.hasApplied = false,
    this.hasAcceptedBooking = false,
    this.isLoading = true,
    this.error,
    this.isApplying = false,
  });

  final EventEntity? event;
  final UserEntity? planner;
  final PlannerProfileEntity? plannerProfile;
  final int applicationCount;
  final List<String?> applicantPhotoUrls;
  final bool hasApplied;

  /// True when the current user is a creative with an accepted booking for this event.
  final bool hasAcceptedBooking;
  final bool isLoading;
  final String? error;
  final bool isApplying;

  EventDetailState copyWith({
    EventEntity? event,
    UserEntity? planner,
    PlannerProfileEntity? plannerProfile,
    int? applicationCount,
    List<String?>? applicantPhotoUrls,
    bool? hasApplied,
    bool? hasAcceptedBooking,
    bool? isLoading,
    String? error,
    bool? isApplying,
  }) {
    return EventDetailState(
      event: event ?? this.event,
      planner: planner ?? this.planner,
      plannerProfile: plannerProfile ?? this.plannerProfile,
      applicationCount: applicationCount ?? this.applicationCount,
      applicantPhotoUrls: applicantPhotoUrls ?? this.applicantPhotoUrls,
      hasApplied: hasApplied ?? this.hasApplied,
      hasAcceptedBooking: hasAcceptedBooking ?? this.hasAcceptedBooking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApplying: isApplying ?? this.isApplying,
    );
  }
}
