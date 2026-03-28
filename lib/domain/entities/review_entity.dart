import 'package:equatable/equatable.dart';

/// Domain entity for a review.
class ReviewEntity extends Equatable {
  const ReviewEntity({
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

  @override
  List<Object?> get props => [
    id,
    bookingId,
    collaborationId,
    reviewerId,
    revieweeId,
    rating,
    comment,
    createdAt,
    reply,
    replyAt,
    likeCount,
    likedBy,
    flagCount,
    flaggedBy,
  ];
}
