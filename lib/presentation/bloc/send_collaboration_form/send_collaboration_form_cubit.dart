import 'package:flutter_bloc/flutter_bloc.dart';

import 'send_collaboration_form_state.dart';

class SendCollaborationFormCubit extends Cubit<SendCollaborationFormState> {
  SendCollaborationFormCubit() : super(const SendCollaborationFormState());

  void setSubmitting(bool v) => emit(state.copyWith(isSubmitting: v));

  void setEventType(String? v) =>
      emit(state.copyWith(eventType: v, clearEventType: v == null));

  void setDate(DateTime? v) =>
      emit(state.copyWith(date: v, clearDate: v == null));

  void setStartTime(String v) => emit(state.copyWith(startTime: v));

  void setEndTime(String v) => emit(state.copyWith(endTime: v));
}
