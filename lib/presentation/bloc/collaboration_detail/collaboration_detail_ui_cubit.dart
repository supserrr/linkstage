import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/repositories/review_repository.dart';
import 'collaboration_detail_ui_state.dart';

class CollaborationDetailUiCubit extends Cubit<CollaborationDetailUiState> {
  CollaborationDetailUiCubit(this.collaboration)
    : super(const CollaborationDetailUiState()) {
    loadHasReviewed();
  }

  final CollaborationEntity collaboration;

  CollaborationStatus get _effectiveStatus =>
      state.overrideStatus ?? collaboration.status;

  Future<void> loadHasReviewed() async {
    final status = _effectiveStatus;
    if (status != CollaborationStatus.accepted &&
        status != CollaborationStatus.completed) {
      emit(state.copyWith(hasReviewed: false));
      return;
    }
    final userId = sl<AuthRedirectNotifier>().user?.id;
    if (userId == null || userId.isEmpty) {
      emit(state.copyWith(hasReviewed: false));
      return;
    }
    try {
      final review = await sl<ReviewRepository>()
          .getReviewByCollaborationAndReviewer(collaboration.id, userId);
      if (!isClosed) emit(state.copyWith(hasReviewed: review != null));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(hasReviewed: false));
    }
  }

  void setHasReviewed(bool value) {
    emit(
      CollaborationDetailUiState(
        hasReviewed: value,
        overrideStatus: state.overrideStatus,
        overrideCreativeConfirmedAt: state.overrideCreativeConfirmedAt,
        isConfirmingCompletion: state.isConfirmingCompletion,
      ),
    );
  }

  void setConfirmingCompletion(bool v) =>
      emit(state.copyWith(isConfirmingCompletion: v));

  void applyCreativeConfirmedNow() {
    emit(
      state.copyWith(
        isConfirmingCompletion: false,
        overrideCreativeConfirmedAt: DateTime.now(),
      ),
    );
  }

  void applyMarkAsDone({required bool viewerIsCreative}) {
    emit(
      state.copyWith(
        overrideStatus: CollaborationStatus.completed,
        overrideCreativeConfirmedAt: viewerIsCreative
            ? DateTime.now()
            : state.overrideCreativeConfirmedAt,
      ),
    );
  }
}
