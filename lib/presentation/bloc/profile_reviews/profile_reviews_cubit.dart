import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'profile_reviews_state.dart';

/// Cubit for profile reviews screen.
class ProfileReviewsCubit extends Cubit<ProfileReviewsState> {
  ProfileReviewsCubit(
    this._reviewRepository,
    this._userRepository,
    this._revieweeUserId,
    this._currentViewerId,
  ) : super(ProfileReviewsState(revieweeUserId: _revieweeUserId)) {
    load();
  }

  final ReviewRepository _reviewRepository;
  final UserRepository _userRepository;
  final String _revieweeUserId;
  final String _currentViewerId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final reviews = await _reviewRepository.getReviewsByRevieweeId(
        _revieweeUserId,
      );
      final reviewerIds = reviews
          .map((r) => r.reviewerId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final reviewAuthorsById = reviewerIds.isEmpty
          ? <String, UserEntity>{}
          : await _userRepository.getUsersByIds(reviewerIds);
      emit(state.copyWith(
        reviews: reviews,
        reviewAuthorsById: reviewAuthorsById,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  Future<void> addReply(String reviewId, String text) async {
    try {
      await _reviewRepository.addReply(reviewId, text);
      await load();
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  Future<void> likeReview(String reviewId) async {
    try {
      await _reviewRepository.likeReview(reviewId, _currentViewerId);
      await load();
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  Future<void> flagReview(String reviewId) async {
    try {
      await _reviewRepository.flagReview(reviewId, _currentViewerId);
      await load();
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }
}
