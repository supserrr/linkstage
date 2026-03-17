import '../../../domain/entities/event_entity.dart';

/// A single recent activity item (e.g. proposal received).
class PlannerDashboardActivityItem {
  const PlannerDashboardActivityItem({
    required this.creativeName,
    required this.eventTitle,
    required this.createdAt,
  });

  final String creativeName;
  final String eventTitle;
  final DateTime createdAt;
}

/// State for the event planner dashboard.
class PlannerDashboardState {
  const PlannerDashboardState({
    this.events = const [],
    this.applicantsCount = 0,
    this.eventsCount = 0,
    this.unreadCount = 0,
    this.recentActivities = const [],
    this.pendingCountByEventId = const {},
    this.isLoading = false,
    this.error,
  });

  final List<EventEntity> events;
  final int applicantsCount;
  final int eventsCount;
  final int unreadCount;
  final List<PlannerDashboardActivityItem> recentActivities;
  /// Pending bookings count per event ID (for "+N New" on stage cards).
  final Map<String, int> pendingCountByEventId;
  final bool isLoading;
  final String? error;

  PlannerDashboardState copyWith({
    List<EventEntity>? events,
    int? applicantsCount,
    int? eventsCount,
    int? unreadCount,
    List<PlannerDashboardActivityItem>? recentActivities,
    Map<String, int>? pendingCountByEventId,
    bool? isLoading,
    String? error,
  }) {
    return PlannerDashboardState(
      events: events ?? this.events,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      eventsCount: eventsCount ?? this.eventsCount,
      unreadCount: unreadCount ?? this.unreadCount,
      recentActivities: recentActivities ?? this.recentActivities,
      pendingCountByEventId:
          pendingCountByEventId ?? this.pendingCountByEventId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
