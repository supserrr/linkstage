import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/review_entity.dart';

/// Firestore model for review document.
class ReviewModel {
  ReviewModel({
    required this.id,
    this.bookingId = '',
    this.collaborationId = '',
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment = '',
    this.createdAt,
    this.reply = '',
    this.replyAt,
    this.likeCount = 0,
    this.likedBy = const [],
    this.flagCount = 0,
    this.flaggedBy = const [],
  });

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp?;
    final replyTs = data['replyAt'] as Timestamp?;
    final likedByList = data['likedBy'] as List<dynamic>?;
    final flaggedByList = data['flaggedBy'] as List<dynamic>?;
    return ReviewModel(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      collaborationId: data['collaborationId'] as String? ?? '',
      reviewerId: data['reviewerId'] as String? ?? '',
      revieweeId: data['revieweeId'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: ts?.toDate(),
      reply: data['reply'] as String? ?? '',
      replyAt: replyTs?.toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      likedBy: likedByList?.map((e) => e.toString()).toList() ?? [],
      flagCount: data['flagCount'] as int? ?? 0,
      flaggedBy: flaggedByList?.map((e) => e.toString()).toList() ?? [],
    );
  }

  final String id;
  final String bookingId;
  final String collaborationId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String reply;
  final DateTime? replyAt;
  final int likeCount;
  final List<String> likedBy;
  final int flagCount;
  final List<String> flaggedBy;

  ReviewEntity toEntity() {
    return ReviewEntity(
      id: id,
      bookingId: bookingId,
      collaborationId: collaborationId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      reply: reply,
      replyAt: replyAt,
      likeCount: likeCount,
      likedBy: likedBy,
      flagCount: flagCount,
      flaggedBy: flaggedBy,
    );
  }
}
