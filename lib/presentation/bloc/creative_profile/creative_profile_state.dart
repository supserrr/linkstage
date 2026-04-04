import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../domain/entities/user_entity.dart';

/// State for creative profile edit.
class CreativeProfileState {
  const CreativeProfileState({
    this.profile,
    this.reviews = const [],
    this.reviewAuthorsById = const {},
    this.totalGigs = 0,
    this.followersCount = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final ProfileEntity? profile;
  final List<ReviewEntity> reviews;

  /// Reviewer userId -> user (for review avatars and names).
  final Map<String, UserEntity> reviewAuthorsById;
  final int totalGigs;
  final int followersCount;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  CreativeProfileState copyWith({
    ProfileEntity? profile,
    List<ReviewEntity>? reviews,
    Map<String, UserEntity>? reviewAuthorsById,
    int? totalGigs,
    int? followersCount,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return CreativeProfileState(
      profile: profile ?? this.profile,
      reviews: reviews ?? this.reviews,
      reviewAuthorsById: reviewAuthorsById ?? this.reviewAuthorsById,
      totalGigs: totalGigs ?? this.totalGigs,
      followersCount: followersCount ?? this.followersCount,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}
