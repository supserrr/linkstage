import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/planner_profile_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/user_entity.dart';

/// State for planner profile edit.
class PlannerProfileState {
  const PlannerProfileState({
    this.user,
    this.plannerProfile,
    this.events = const [],
    this.currentEvents = const [],
    this.pastEvents = const [],
    this.recentCreatives = const [],
    this.acceptedEventIdsForViewer = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final UserEntity? user;
  final PlannerProfileEntity? plannerProfile;
  final List<EventEntity> events;
  final List<EventEntity> currentEvents;
  final List<EventEntity> pastEvents;
  final List<ProfileEntity> recentCreatives;
  /// When viewing another planner, event IDs where the signed-in user has an accepted booking.
  final Set<String> acceptedEventIdsForViewer;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  PlannerProfileState copyWith({
    UserEntity? user,
    PlannerProfileEntity? plannerProfile,
    List<EventEntity>? events,
    List<EventEntity>? currentEvents,
    List<EventEntity>? pastEvents,
    List<ProfileEntity>? recentCreatives,
    Set<String>? acceptedEventIdsForViewer,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return PlannerProfileState(
      user: user ?? this.user,
      plannerProfile: plannerProfile ?? this.plannerProfile,
      events: events ?? this.events,
      currentEvents: currentEvents ?? this.currentEvents,
      pastEvents: pastEvents ?? this.pastEvents,
      recentCreatives: recentCreatives ?? this.recentCreatives,
      acceptedEventIdsForViewer:
          acceptedEventIdsForViewer ?? this.acceptedEventIdsForViewer,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}
