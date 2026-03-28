import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Domain entity for event planner profile.
class PlannerProfileEntity extends Equatable {
  const PlannerProfileEntity({
    required this.userId,
    this.bio = '',
    this.location = '',
    this.eventTypes = const [],
    this.languages = const [],
    this.portfolioUrls = const [],
    this.displayName,
    this.role,
    this.photoUrl,
    this.profileVisibility,
  });

  final String userId;
  final String bio;
  final String location;
  final List<String> eventTypes;
  final List<String> languages;
  final List<String> portfolioUrls;
  final String? displayName;
  /// Role/title shown in "Hosted by" section (e.g. Event Planner).
  final String? role;
  /// Profile picture URL (from user document); used for avatar display.
  final String? photoUrl;
  /// Denormalized from user; for query filtering (everyone | connections_only | only_me).
  final ProfileVisibility? profileVisibility;

  @override
  List<Object?> get props => [
        userId,
        bio,
        location,
        eventTypes,
        languages,
        portfolioUrls,
        displayName,
        role,
        photoUrl,
        profileVisibility,
      ];

  PlannerProfileEntity copyWith({String? photoUrl, ProfileVisibility? profileVisibility}) {
    return PlannerProfileEntity(
      userId: userId,
      bio: bio,
      location: location,
      eventTypes: eventTypes,
      languages: languages,
      portfolioUrls: portfolioUrls,
      displayName: displayName,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      profileVisibility: profileVisibility ?? this.profileVisibility,
    );
  }
}
