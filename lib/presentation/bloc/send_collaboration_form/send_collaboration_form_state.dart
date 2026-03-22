class SendCollaborationFormState {
  const SendCollaborationFormState({
    this.isSubmitting = false,
    this.eventType,
    this.date,
    this.startTime = '',
    this.endTime = '',
  });

  final bool isSubmitting;
  final String? eventType;
  final DateTime? date;
  final String startTime;
  final String endTime;

  SendCollaborationFormState copyWith({
    bool? isSubmitting,
    String? eventType,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool clearEventType = false,
    bool clearDate = false,
  }) {
    return SendCollaborationFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      eventType: clearEventType ? null : (eventType ?? this.eventType),
      date: clearDate ? null : (date ?? this.date),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
