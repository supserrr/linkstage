import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

/// Implementation of [ReviewRepository] using Firestore.
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._remote, this._profileRepository);

  final ReviewRemoteDataSource _remote;
  final ProfileRepository _profileRepository;

  @override
  Future<List<ReviewEntity>> getReviewsByRevieweeId(String revieweeId) =>
      _remote.getReviewsByRevieweeId(revieweeId);

  @override
  Future<ReviewEntity> createReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final review = await _remote.createReview(
      bookingId: bookingId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      rating: rating,
      comment: comment,
    );
    await _updateProfileRatingIfCreative(revieweeId);
    return review;
  }

  /// When reviewee is a creative (has profile), recompute and update rating/reviewCount.
  Future<void> _updateProfileRatingIfCreative(String revieweeUserId) async {
    final profile = await _profileRepository.getProfileByUserId(revieweeUserId);
    if (profile == null) return;
    final reviews = await _remote.getReviewsByRevieweeId(revieweeUserId);
    if (reviews.isEmpty) return;
    final total = reviews.fold<double>(0, (s, r) => s + r.rating);
    final avg = total / reviews.length;
    await _profileRepository.updateProfileRatingStats(
      profile.id,
      double.parse(avg.toStringAsFixed(1)),
      reviews.length,
    );
  }

  @override
  Future<ReviewEntity?> getReviewByBookingAndReviewer(
    String bookingId,
    String reviewerId,
  ) => _remote.getReviewByBookingAndReviewer(bookingId, reviewerId);

  @override
  Future<ReviewEntity> createCollaborationReview({
    required String collaborationId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final review = await _remote.createCollaborationReview(
      collaborationId: collaborationId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      rating: rating,
      comment: comment,
    );
    await _updateProfileRatingIfCreative(revieweeId);
    return review;
  }

  @override
  Future<ReviewEntity?> getReviewByCollaborationAndReviewer(
    String collaborationId,
    String reviewerId,
  ) => _remote.getReviewByCollaborationAndReviewer(collaborationId, reviewerId);

  @override
  Future<void> addReply(String reviewId, String text) =>
      _remote.addReply(reviewId, text);

  @override
  Future<void> likeReview(String reviewId, String userId) =>
      _remote.likeReview(reviewId, userId);

  @override
  Future<void> flagReview(String reviewId, String userId) =>
      _remote.flagReview(reviewId, userId);
}
