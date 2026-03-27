import '../../../domain/entities/review_entity.dart';
import '../../../domain/entities/user_entity.dart';

/// State for profile reviews screen.
class ProfileReviewsState {
  const ProfileReviewsState({
    this.reviews = const [],
    this.reviewAuthorsById = const {},
    required this.revieweeUserId,
    this.isLoading = false,
    this.error,
  });

  final List<ReviewEntity> reviews;
  final Map<String, UserEntity> reviewAuthorsById;
  /// User whose profile these reviews belong to (reviewee).
  final String revieweeUserId;
  final bool isLoading;
  final String? error;

  ProfileReviewsState copyWith({
    List<ReviewEntity>? reviews,
    Map<String, UserEntity>? reviewAuthorsById,
    String? revieweeUserId,
    bool? isLoading,
    String? error,
  }) =>
      ProfileReviewsState(
        reviews: reviews ?? this.reviews,
        reviewAuthorsById: reviewAuthorsById ?? this.reviewAuthorsById,
        revieweeUserId: revieweeUserId ?? this.revieweeUserId,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
