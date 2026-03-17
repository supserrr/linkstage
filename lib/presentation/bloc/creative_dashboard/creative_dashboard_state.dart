import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/profile_entity.dart';

/// Filter for the creative home content: Events vs Creatives.
enum CreativeHomeFilter { events, creatives }

/// State for the creative home dashboard.
class CreativeDashboardState {
  const CreativeDashboardState({
    this.profile,
    this.notificationCount = 0,
    this.homeFilter = CreativeHomeFilter.events,
    this.openEvents = const [],
    this.fellowCreatives = const [],
    this.pendingCountByEventId = const {},
    this.savedEventIds = const {},
    this.savedEvents = const [],
    this.savedCreativeIds = const {},
    this.savedCreatives = const [],
    this.recommendedForYouEvents = const [],
    this.applicationsCount = 0,
    this.gigsCount = 0,
    this.followedPlannersCount = 0,
    this.acceptedEventIds = const {},
    this.isLoading = false,
    this.error,
  });

  final ProfileEntity? profile;
  final int notificationCount;
  final CreativeHomeFilter homeFilter;
  final List<EventEntity> openEvents;
  final List<ProfileEntity> fellowCreatives;
  final Map<String, int> pendingCountByEventId;
  final Set<String> savedEventIds;
  /// Resolved list of saved events (for display in Saved section).
  final List<EventEntity> savedEvents;
  final Set<String> savedCreativeIds;
  /// Resolved list of saved creative profiles.
  final List<ProfileEntity> savedCreatives;
  /// Top open events recommended for this creative (skills/location match).
  final List<EventEntity> recommendedForYouEvents;
  final int applicationsCount;
  final int gigsCount;
  final int followedPlannersCount;
  /// Event IDs where this creative has an accepted booking (for location visibility).
  final Set<String> acceptedEventIds;
  final bool isLoading;
  final String? error;

  String get displayName =>
      profile?.displayName ?? '';

  /// Role label for "For: [Role]" (e.g. "Jazz Vocalist", "DJ").
  String? get roleLabel {
    final p = profile;
    if (p == null) return null;
    if (p.professions.isNotEmpty) return p.professions.first;
    if (p.category != null) {
      switch (p.category!) {
        case ProfileCategory.dj:
          return 'DJ';
        case ProfileCategory.photographer:
          return 'Photographer';
        case ProfileCategory.decorator:
          return 'Decorator';
        case ProfileCategory.contentCreator:
          return 'Content Creator';
      }
    }
    return null;
  }

  CreativeDashboardState copyWith({
    ProfileEntity? profile,
    int? notificationCount,
    CreativeHomeFilter? homeFilter,
    List<EventEntity>? openEvents,
    List<ProfileEntity>? fellowCreatives,
    Map<String, int>? pendingCountByEventId,
    Set<String>? savedEventIds,
    List<EventEntity>? savedEvents,
    Set<String>? savedCreativeIds,
    List<ProfileEntity>? savedCreatives,
    List<EventEntity>? recommendedForYouEvents,
    int? applicationsCount,
    int? gigsCount,
    int? followedPlannersCount,
    Set<String>? acceptedEventIds,
    bool? isLoading,
    String? error,
  }) {
    return CreativeDashboardState(
      profile: profile ?? this.profile,
      notificationCount: notificationCount ?? this.notificationCount,
      homeFilter: homeFilter ?? this.homeFilter,
      openEvents: openEvents ?? this.openEvents,
      fellowCreatives: fellowCreatives ?? this.fellowCreatives,
      pendingCountByEventId:
          pendingCountByEventId ?? this.pendingCountByEventId,
      savedEventIds: savedEventIds ?? this.savedEventIds,
      savedEvents: savedEvents ?? this.savedEvents,
      savedCreativeIds: savedCreativeIds ?? this.savedCreativeIds,
      savedCreatives: savedCreatives ?? this.savedCreatives,
      recommendedForYouEvents:
          recommendedForYouEvents ?? this.recommendedForYouEvents,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      gigsCount: gigsCount ?? this.gigsCount,
      followedPlannersCount:
          followedPlannersCount ?? this.followedPlannersCount,
      acceptedEventIds: acceptedEventIds ?? this.acceptedEventIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
