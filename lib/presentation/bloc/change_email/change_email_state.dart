/// State for change email flow.
class ChangeEmailState {
  const ChangeEmailState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  final bool isSubmitting;
  final String? error;
  final bool success;

  ChangeEmailState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
  }) {
    return ChangeEmailState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
    );
  }
}
