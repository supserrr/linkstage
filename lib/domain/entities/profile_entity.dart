import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Creative professional category.
enum ProfileCategory { dj, photographer, decorator, contentCreator }

/// Availability status for creatives.
enum ProfileAvailability { openToWork, notAvailable }

/// Domain entity for creative professional profile.
class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    required this.userId,
    this.username,
    this.bio = '',
    this.category,
    this.professions = const [],
    this.priceRange = '',
    this.location = '',
    this.portfolioUrls = const [],
    this.portfolioVideoUrls = const [],
    this.availability,
    this.services = const [],
    this.languages = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.displayName,
    this.photoUrl,
    this.profileVisibility,
  });

  /// Profile doc ID when keyed by username. id == username.
  final String id;
  final String userId;
  final String? username;
  final String bio;
  final ProfileCategory? category;
  final List<String> professions;
  final String priceRange;
  final String location;
  final List<String> portfolioUrls;
  final List<String> portfolioVideoUrls;
  final ProfileAvailability? availability;
  final List<String> services;
  final List<String> languages;
  final double rating;
  final int reviewCount;
  final String? displayName;
  /// Profile picture URL (from user document); used for avatar display.
  final String? photoUrl;
  /// Denormalized from user; for query filtering (everyone | connections_only | only_me).
  final ProfileVisibility? profileVisibility;

  ProfileEntity copyWith({String? photoUrl, ProfileVisibility? profileVisibility}) {
    return ProfileEntity(
      id: id,
      userId: userId,
      username: username,
      bio: bio,
      category: category,
      professions: professions,
      priceRange: priceRange,
      location: location,
      portfolioUrls: portfolioUrls,
      portfolioVideoUrls: portfolioVideoUrls,
      availability: availability,
      services: services,
      languages: languages,
      rating: rating,
      reviewCount: reviewCount,
      displayName: displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      profileVisibility: profileVisibility ?? this.profileVisibility,
    );
  }

  static ProfileAvailability? availabilityFromKey(String? key) {
    switch (key) {
      case 'open_to_work':
        return ProfileAvailability.openToWork;
      case 'not_available':
        return ProfileAvailability.notAvailable;
      default:
        return null;
    }
  }

  String get availabilityKey {
    switch (availability) {
      case ProfileAvailability.openToWork:
        return 'open_to_work';
      case ProfileAvailability.notAvailable:
        return 'not_available';
      case null:
        return '';
    }
  }

  String get categoryKey {
    switch (category) {
      case ProfileCategory.dj:
        return 'dj';
      case ProfileCategory.photographer:
        return 'photographer';
      case ProfileCategory.decorator:
        return 'decorator';
      case ProfileCategory.contentCreator:
        return 'content_creator';
      case null:
        return '';
    }
  }

  static ProfileCategory? categoryFromKey(String? key) {
    switch (key) {
      case 'dj':
        return ProfileCategory.dj;
      case 'photographer':
        return ProfileCategory.photographer;
      case 'decorator':
        return ProfileCategory.decorator;
      case 'content_creator':
        return ProfileCategory.contentCreator;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        bio,
        category,
        priceRange,
        location,
        portfolioUrls,
        portfolioVideoUrls,
        availability,
        services,
        languages,
        professions,
        photoUrl,
        profileVisibility,
      ];
}
