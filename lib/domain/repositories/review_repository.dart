import '../entities/review_entity.dart';

/// Abstract contract for review operations.
abstract class ReviewRepository {
  /// Fetch reviews where the given user was reviewed (as reviewee).
  Future<List<ReviewEntity>> getReviewsByRevieweeId(String revieweeId);

  /// Create a new review for a completed booking.
  Future<ReviewEntity> createReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  });

  /// Fetch review by booking and reviewer, or null if none exists.
  Future<ReviewEntity?> getReviewByBookingAndReviewer(
    String bookingId,
    String reviewerId,
  );

  /// Create a new review for an accepted collaboration.
  Future<ReviewEntity> createCollaborationReview({
    required String collaborationId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  });

  /// Fetch review by collaboration and reviewer, or null if none exists.
  Future<ReviewEntity?> getReviewByCollaborationAndReviewer(
    String collaborationId,
    String reviewerId,
  );

  /// Add or update reply to a review.
  Future<void> addReply(String reviewId, String text);

  /// Toggle like on a review.
  Future<void> likeReview(String reviewId, String userId);

  /// Toggle flag on a review.
  Future<void> flagReview(String reviewId, String userId);
}
