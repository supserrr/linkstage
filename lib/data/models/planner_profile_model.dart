import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/planner_profile_entity.dart';
import '../../domain/entities/user_entity.dart';

/// Firestore model for planner profile document.
class PlannerProfileModel {
  PlannerProfileModel({
    required this.userId,
    this.bio = '',
    this.location = '',
    this.eventTypes = const [],
    this.languages = const [],
    this.portfolioUrls = const [],
    this.displayName,
    this.role,
    this.profileVisibility,
  });

  factory PlannerProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final eventTypesList = data['eventTypes'] as List<dynamic>?;
    final langs = data['languages'] as List<dynamic>?;
    final portfolio = data['portfolioUrls'] as List<dynamic>?;
    return PlannerProfileModel(
      userId: data['userId'] as String? ?? doc.id,
      bio: data['bio'] as String? ?? '',
      location: data['location'] as String? ?? '',
      eventTypes: eventTypesList?.map((e) => e.toString()).toList() ?? const [],
      languages: langs?.map((e) => e.toString()).toList() ?? const [],
      portfolioUrls: portfolio?.map((e) => e.toString()).toList() ?? const [],
      displayName: data['displayName'] as String?,
      role: data['role'] as String?,
      profileVisibility:
          UserEntity.profileVisibilityFromKey(data['profileVisibility'] as String?),
    );
  }

  final String userId;
  final String bio;
  final String location;
  final List<String> eventTypes;
  final List<String> languages;
  final List<String> portfolioUrls;
  final String? displayName;
  final String? role;
  final ProfileVisibility? profileVisibility;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bio': bio,
      'location': location,
      'eventTypes': eventTypes,
      'languages': languages,
      'portfolioUrls': portfolioUrls,
      'displayName': displayName,
      'role': role,
      'profileVisibility':
          profileVisibility != null
              ? UserEntity.profileVisibilityToKey(profileVisibility!)
              : null,
    };
  }

  PlannerProfileEntity toEntity() {
    return PlannerProfileEntity(
      userId: userId,
      bio: bio,
      location: location,
      eventTypes: eventTypes,
      languages: languages,
      portfolioUrls: portfolioUrls,
      displayName: displayName,
      role: role,
      profileVisibility: profileVisibility,
    );
  }
}
