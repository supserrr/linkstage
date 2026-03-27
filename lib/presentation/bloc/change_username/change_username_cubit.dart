import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/user/change_username_usecase.dart';
import 'change_username_state.dart';

class ChangeUsernameCubit extends Cubit<ChangeUsernameState> {
  ChangeUsernameCubit(this._useCase, this._user)
      : super(ChangeUsernameState(
          currentUsername: _user.username,
          nextChangeDate: _nextChangeDate(_user.lastUsernameChangeAt),
        ));

  final ChangeUsernameUseCase _useCase;
  final UserEntity _user;

  Future<void> checkAvailability(String username) async {
    if (username.length < 3) {
      emit(state.copyWith(
        validationError: 'At least 3 characters required',
        isAvailable: false,
        isCheckingAvailability: false,
      ));
      return;
    }
    emit(state.copyWith(
      isCheckingAvailability: true,
      validationError: null,
    ));
    final error = await _useCase.validate(username, excludeUserId: _user.id);
    emit(state.copyWith(
      isCheckingAvailability: false,
      validationError: error,
      isAvailable: error == null,
    ));
  }

  void clearValidation() {
    emit(state.copyWith(
      validationError: null,
      isAvailable: null,
    ));
  }

  Future<void> submit(String newUsername) async {
    if (newUsername.length < 3) return;
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    final result = await _useCase(_user, newUsername);
    if (result is ChangeUsernameSuccess) {
      emit(state.copyWith(
        isSubmitting: false,
        status: ChangeUsernameStatus.success,
        currentUsername: newUsername.toLowerCase(),
      ));
      return;
    }
    if (result is ChangeUsernameCooldown) {
      emit(state.copyWith(
        isSubmitting: false,
        status: ChangeUsernameStatus.error,
        nextChangeDate: _formatDate(result.nextChangeDate),
      ));
      return;
    }
    if (result is ChangeUsernameInvalid) {
      emit(state.copyWith(
        isSubmitting: false,
        status: ChangeUsernameStatus.error,
        errorMessage: result.message,
      ));
      return;
    }
    if (result is ChangeUsernameTaken) {
      emit(state.copyWith(
        isSubmitting: false,
        status: ChangeUsernameStatus.error,
        errorMessage: 'This username is taken',
      ));
      return;
    }
    emit(state.copyWith(isSubmitting: false));
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String? _nextChangeDate(DateTime? lastChange) {
    if (lastChange == null) return null;
    final next = lastChange.add(const Duration(days: ChangeUsernameUseCase.cooldownDays));
    return next.isAfter(DateTime.now()) ? _formatDate(next) : null;
  }
}
