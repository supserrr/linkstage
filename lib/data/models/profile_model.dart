import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entity_extensions.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';

/// Firestore model for profile document.
class ProfileModel {
  ProfileModel({
    required this.id,
    required this.userId,
    this.username,
    this.bio = '',
    this.category,
    this.priceRange = '',
    this.location = '',
    this.portfolioUrls = const [],
    this.portfolioVideoUrls = const [],
    this.availability,
    this.services = const [],
    this.languages = const [],
    this.professions = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.displayName,
    this.profileVisibility,
  });

  factory ProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final portfolio = data['portfolioUrls'] as List<dynamic>?;
    final portfolioVideos = data['portfolioVideoUrls'] as List<dynamic>?;
    final svcs = data['services'] as List<dynamic>?;
    final langs = data['languages'] as List<dynamic>?;
    final specs = data['specializations'] as List<dynamic>?;
    final profs = data['professions'] as List<dynamic>?;
    final svcList = svcs?.map((e) => e.toString()).toList() ?? [];
    final specList = specs?.map((e) => e.toString()).toList() ?? [];
    final mergedServices = [
      ...{...svcList, ...specList},
    ];
    return ProfileModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? doc.id,
      bio: data['bio'] as String? ?? '',
      category: ProfileEntity.categoryFromKey(data['category'] as String?),
      priceRange: data['priceRange'] as String? ?? '',
      location: data['location'] as String? ?? '',
      portfolioUrls: portfolio?.map((e) => e.toString()).toList() ?? [],
      portfolioVideoUrls:
          portfolioVideos?.map((e) => e.toString()).toList() ?? const [],
      availability: ProfileEntity.availabilityFromKey(
        data['availability'] as String?,
      ),
      services: mergedServices,
      languages: langs?.map((e) => e.toString()).toList() ?? const [],
      professions: profs?.map((e) => e.toString()).toList() ?? const [],
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      displayName: data['displayName'] as String?,
      profileVisibility: UserEntity.profileVisibilityFromKey(
        data['profileVisibility'] as String?,
      ),
    );
  }

  final String id;
  final String userId;
  final String? username;
  final String bio;
  final ProfileCategory? category;
  final String priceRange;
  final String location;
  final List<String> portfolioUrls;
  final List<String> portfolioVideoUrls;
  final ProfileAvailability? availability;
  final List<String> services;
  final List<String> languages;
  final List<String> professions;
  final double rating;
  final int reviewCount;
  final String? displayName;
  final ProfileVisibility? profileVisibility;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username ?? id,
      'bio': bio,
      'category': category?.categoryKey,
      'priceRange': priceRange,
      'location': location,
      'portfolioUrls': portfolioUrls,
      'portfolioVideoUrls': portfolioVideoUrls,
      'availability': availability != null ? _availabilityKey : null,
      'services': services,
      'languages': languages,
      'professions': professions,
      'rating': rating,
      'reviewCount': reviewCount,
      'displayName': displayName,
      'profileVisibility': profileVisibility != null
          ? UserEntity.profileVisibilityToKey(profileVisibility!)
          : null,
    };
  }

  String get _availabilityKey {
    switch (availability) {
      case ProfileAvailability.openToWork:
        return 'open_to_work';
      case ProfileAvailability.notAvailable:
        return 'not_available';
      default:
        return '';
    }
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      userId: userId,
      username: username ?? id,
      bio: bio,
      category: category,
      priceRange: priceRange,
      location: location,
      portfolioUrls: portfolioUrls,
      portfolioVideoUrls: portfolioVideoUrls,
      availability: availability,
      services: services,
      languages: languages,
      professions: professions,
      rating: rating,
      reviewCount: reviewCount,
      displayName: displayName,
      profileVisibility: profileVisibility,
    );
  }
}
