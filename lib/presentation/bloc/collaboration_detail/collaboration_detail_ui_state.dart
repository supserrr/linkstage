import '../../../domain/entities/collaboration_entity.dart';

class CollaborationDetailUiState {
  const CollaborationDetailUiState({
    this.hasReviewed,
    this.overrideStatus,
    this.overrideCreativeConfirmedAt,
    this.isConfirmingCompletion = false,
  });

  final bool? hasReviewed;
  final CollaborationStatus? overrideStatus;
  final DateTime? overrideCreativeConfirmedAt;
  final bool isConfirmingCompletion;

  CollaborationDetailUiState copyWith({
    bool? hasReviewed,
    CollaborationStatus? overrideStatus,
    DateTime? overrideCreativeConfirmedAt,
    bool? isConfirmingCompletion,
  }) {
    return CollaborationDetailUiState(
      hasReviewed: hasReviewed ?? this.hasReviewed,
      overrideStatus: overrideStatus ?? this.overrideStatus,
      overrideCreativeConfirmedAt:
          overrideCreativeConfirmedAt ?? this.overrideCreativeConfirmedAt,
      isConfirmingCompletion:
          isConfirmingCompletion ?? this.isConfirmingCompletion,
    );
  }
}
