import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'creative_profile_state.dart';

/// Cubit for creative profile edit flow.
class CreativeProfileCubit extends Cubit<CreativeProfileState> {
  CreativeProfileCubit(
    this._profileRepository,
    this._reviewRepository,
    this._bookingRepository,
    this._userRepository,
    String userId,
  ) : _userId = userId,
      super(const CreativeProfileState()) {
    load(userId);
  }

  final ProfileRepository _profileRepository;
  final String _userId;
  final ReviewRepository _reviewRepository;
  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;

  Future<void> load(String userId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      var profile = await _profileRepository.getProfileByUserId(userId);
      if (profile != null &&
          (profile.photoUrl == null || profile.photoUrl!.isEmpty)) {
        final user = await _userRepository.getUser(userId);
        if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
          profile = profile.copyWith(photoUrl: user.photoUrl);
        }
      }
      final reviews = await _reviewRepository.getReviewsByRevieweeId(userId);
      final reviewerIds = reviews
          .map((r) => r.reviewerId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final reviewAuthorsById = reviewerIds.isEmpty
          ? <String, UserEntity>{}
          : await _userRepository.getUsersByIds(reviewerIds);
      final bookings = await _bookingRepository
          .getCompletedBookingsByCreativeId(userId);
      emit(
        state.copyWith(
          profile: profile,
          reviews: reviews,
          reviewAuthorsById: reviewAuthorsById,
          totalGigs: bookings.length,
          followersCount: 0,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception:', '').trim(),
        ),
      );
    }
  }

  void setBio(String value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: value,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setDisplayName(String value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: value.isEmpty ? null : value,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setPriceRange(String value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: value,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setProfessions(List<String> value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            professions: value,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setLocation(String value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: value,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setAvailability(ProfileAvailability? value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: value,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setPortfolioUrls(List<String> value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: value,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setPortfolioVideoUrls(List<String> value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: value,
            availability: p.availability,
            services: p.services,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setServices(List<String> value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: value,
            languages: p.languages,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  void setLanguages(List<String> value) {
    final p = state.profile;
    if (p != null) {
      emit(
        state.copyWith(
          profile: ProfileEntity(
            id: p.id,
            userId: p.userId,
            username: p.username,
            bio: p.bio,
            category: p.category,
            priceRange: p.priceRange,
            location: p.location,
            portfolioUrls: p.portfolioUrls,
            portfolioVideoUrls: p.portfolioVideoUrls,
            availability: p.availability,
            services: p.services,
            languages: value,
            professions: p.professions,
            rating: p.rating,
            reviewCount: p.reviewCount,
            displayName: p.displayName,
            photoUrl: p.photoUrl,
            profileVisibility: p.profileVisibility,
          ),
        ),
      );
    }
  }

  /// Reload profile and related data (e.g. after returning from edit).
  Future<void> refresh() => load(_userId);

  Future<void> save() async {
    final p = state.profile;
    if (p == null) return;
    final dn = p.displayName?.trim();
    final normalizedDisplay = (dn == null || dn.isEmpty) ? null : dn;
    final pSave = ProfileEntity(
      id: p.id,
      userId: p.userId,
      username: p.username,
      bio: p.bio,
      category: p.category,
      priceRange: p.priceRange,
      location: p.location,
      portfolioUrls: p.portfolioUrls,
      portfolioVideoUrls: p.portfolioVideoUrls,
      availability: p.availability,
      services: p.services,
      languages: p.languages,
      professions: p.professions,
      rating: p.rating,
      reviewCount: p.reviewCount,
      displayName: normalizedDisplay,
      photoUrl: p.photoUrl,
      profileVisibility: p.profileVisibility,
    );
    emit(state.copyWith(isSaving: true, error: null));
    try {
      await _profileRepository.upsertProfile(pSave);
      final firestoreUser = await _userRepository.getUser(_userId);
      if (firestoreUser != null) {
        await _userRepository.upsertUser(
          UserEntity(
            id: firestoreUser.id,
            email: firestoreUser.email,
            emailVerified: firestoreUser.emailVerified,
            username: firestoreUser.username,
            displayName: normalizedDisplay,
            photoUrl: firestoreUser.photoUrl,
            role: firestoreUser.role,
            lastUsernameChangeAt: firestoreUser.lastUsernameChangeAt,
            profileVisibility: firestoreUser.profileVisibility,
            whoCanMessage: firestoreUser.whoCanMessage,
            showOnlineStatus: firestoreUser.showOnlineStatus,
            lastSeen: firestoreUser.lastSeen,
          ),
        );
      }
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          error: e.toString().replaceAll('Exception:', '').trim(),
        ),
      );
    }
  }
}
