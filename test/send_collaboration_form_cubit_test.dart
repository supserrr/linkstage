import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/bloc/send_collaboration_form/send_collaboration_form_cubit.dart';
import 'package:linkstage/presentation/bloc/send_collaboration_form/send_collaboration_form_state.dart';

void main() {
  group('SendCollaborationFormCubit', () {
    blocTest<SendCollaborationFormCubit, SendCollaborationFormState>(
      'setSubmitting toggles',
      build: SendCollaborationFormCubit.new,
      act: (c) => c.setSubmitting(true),
      verify: (c) => expect(c.state.isSubmitting, isTrue),
    );

    blocTest<SendCollaborationFormCubit, SendCollaborationFormState>(
      'setEventType and clear',
      build: SendCollaborationFormCubit.new,
      act: (c) => c
        ..setEventType('Wedding')
        ..setEventType(null),
      verify: (c) {
        expect(c.state.eventType, isNull);
      },
    );

    blocTest<SendCollaborationFormCubit, SendCollaborationFormState>(
      'setDate and times',
      build: SendCollaborationFormCubit.new,
      act: (c) => c
        ..setDate(DateTime(2026, 6, 1))
        ..setStartTime('10:00')
        ..setEndTime('12:00')
        ..setDate(null),
      verify: (c) {
        expect(c.state.date, isNull);
        expect(c.state.startTime, '10:00');
        expect(c.state.endTime, '12:00');
      },
    );
  });
}
