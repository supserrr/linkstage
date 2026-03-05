import 'package:equatable/equatable.dart';

enum ChangeUsernameStatus { initial, checking, available, unavailable, invalid, submitting, success, error }

class ChangeUsernameState extends Equatable {
  const ChangeUsernameState({
    this.currentUsername,
    this.validationError,
    this.isAvailable,
    this.isCheckingAvailability = false,
    this.status = ChangeUsernameStatus.initial,
    this.errorMessage,
    this.nextChangeDate,
    this.isSubmitting = false,
  });

  final String? currentUsername;
  final String? validationError;
  final bool? isAvailable;
  final bool isCheckingAvailability;
  final ChangeUsernameStatus status;
  final String? errorMessage;
  final String? nextChangeDate;
  final bool isSubmitting;

  bool get canChangeUsername => nextChangeDate == null;

  ChangeUsernameState copyWith({
    String? currentUsername,
    String? validationError,
    bool? isAvailable,
    bool? isCheckingAvailability,
    ChangeUsernameStatus? status,
    String? errorMessage,
    String? nextChangeDate,
    bool? isSubmitting,
  }) {
    return ChangeUsernameState(
      currentUsername: currentUsername ?? this.currentUsername,
      validationError: validationError,
      isAvailable: isAvailable ?? this.isAvailable,
      isCheckingAvailability: isCheckingAvailability ?? this.isCheckingAvailability,
      status: status ?? this.status,
      errorMessage: errorMessage,
      nextChangeDate: nextChangeDate ?? this.nextChangeDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        currentUsername,
        validationError,
        isAvailable,
        isCheckingAvailability,
        status,
        errorMessage,
        nextChangeDate,
        isSubmitting,
      ];
}
