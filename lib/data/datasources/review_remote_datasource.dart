import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/review_entity.dart';
import '../models/review_model.dart';

/// Remote data source for reviews in Firestore.
class ReviewRemoteDataSource {
  ReviewRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _reviewsCollection = 'reviews';

  /// Fetch reviews where the given user was reviewed (as reviewee).
  /// Ordered by createdAt descending (newest first).
  Future<List<ReviewEntity>> getReviewsByRevieweeId(String revieweeId) async {
    final snapshot = await _firestore
        .collection(_reviewsCollection)
        .where('revieweeId', isEqualTo: revieweeId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => ReviewModel.fromFirestore(d).toEntity())
        .toList();
  }

  /// Create a new review for a completed booking.
  Future<ReviewEntity> createReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final ref = _firestore.collection(_reviewsCollection).doc();
    final data = <String, dynamic>{
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating.clamp(1, 5),
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'reply': '',
      'replyAt': null,
      'likeCount': 0,
      'likedBy': <String>[],
      'flagCount': 0,
      'flaggedBy': <String>[],
    };
    await ref.set(data);
    final doc = await ref.get();
    return ReviewModel.fromFirestore(doc).toEntity();
  }

  /// Create a new review for an accepted collaboration.
  Future<ReviewEntity> createCollaborationReview({
    required String collaborationId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final ref = _firestore.collection(_reviewsCollection).doc();
    final data = <String, dynamic>{
      'bookingId': '',
      'collaborationId': collaborationId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating.clamp(1, 5),
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'reply': '',
      'replyAt': null,
      'likeCount': 0,
      'likedBy': <String>[],
      'flagCount': 0,
      'flaggedBy': <String>[],
    };
    await ref.set(data);
    final doc = await ref.get();
    return ReviewModel.fromFirestore(doc).toEntity();
  }

  /// Fetch review by collaboration and reviewer, or null if none exists.
  Future<ReviewEntity?> getReviewByCollaborationAndReviewer(
    String collaborationId,
    String reviewerId,
  ) async {
    final snapshot = await _firestore
        .collection(_reviewsCollection)
        .where('collaborationId', isEqualTo: collaborationId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ReviewModel.fromFirestore(snapshot.docs.first).toEntity();
  }

  /// Fetch review by booking and reviewer, or null if none exists.
  Future<ReviewEntity?> getReviewByBookingAndReviewer(
    String bookingId,
    String reviewerId,
  ) async {
    final snapshot = await _firestore
        .collection(_reviewsCollection)
        .where('bookingId', isEqualTo: bookingId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ReviewModel.fromFirestore(snapshot.docs.first).toEntity();
  }

  /// Max length for review reply text (enforced in UI and Firestore rules).
  static const int maxReplyLength = 1000;

  /// Add or update reply to a review.
  Future<void> addReply(String reviewId, String text) async {
    final trimmed = text.length > maxReplyLength
        ? text.substring(0, maxReplyLength)
        : text;
    await _firestore.collection(_reviewsCollection).doc(reviewId).update({
      'reply': trimmed,
      'replyAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle like: add userId to likedBy if not present, remove if present.
  Future<void> likeReview(String reviewId, String userId) async {
    final ref = _firestore.collection(_reviewsCollection).doc(reviewId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (doc.data() == null) return;
      final likedBy =
          List<String>.from((doc.data()!['likedBy'] as List<dynamic>?) ?? []);
      final hasLiked = likedBy.contains(userId);
      if (hasLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      transaction.update(ref, {'likedBy': likedBy, 'likeCount': likedBy.length});
    });
  }

  /// Toggle flag: add userId to flaggedBy if not present, remove if present.
  Future<void> flagReview(String reviewId, String userId) async {
    final ref = _firestore.collection(_reviewsCollection).doc(reviewId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (doc.data() == null) return;
      final flaggedBy =
          List<String>.from((doc.data()!['flaggedBy'] as List<dynamic>?) ?? []);
      final hasFlagged = flaggedBy.contains(userId);
      if (hasFlagged) {
        flaggedBy.remove(userId);
      } else {
        flaggedBy.add(userId);
      }
      transaction.update(
        ref,
        {'flaggedBy': flaggedBy, 'flagCount': flaggedBy.length},
      );
    });
  }
}
