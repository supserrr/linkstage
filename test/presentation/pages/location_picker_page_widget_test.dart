import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:linkstage/presentation/bloc/location_picker/location_picker_cubit.dart';
import 'package:linkstage/presentation/bloc/location_picker/location_picker_state.dart';
import 'package:linkstage/presentation/pages/location_picker_page.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationPickerCubit extends MockCubit<LocationPickerState>
    implements LocationPickerCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LocationPickerState());
  });

  testWidgets('confirm is disabled when no selection', (tester) async {
    final cubit = MockLocationPickerCubit();
    const seeded = LocationPickerState(selectedPoint: null, isLoading: false);
    when(() => cubit.state).thenReturn(seeded);
    whenListen<LocationPickerState>(
      cubit,
      const Stream<LocationPickerState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: LocationPickerPage(locationPickerCubit: cubit)),
    );
    await tester.pump();

    final confirm = find.widgetWithText(TextButton, 'Confirm');
    expect(confirm, findsOneWidget);
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);
  });

  testWidgets('confirm is enabled when selection exists', (tester) async {
    final cubit = MockLocationPickerCubit();
    const seeded = LocationPickerState(
      selectedPoint: LatLng(1.0, 2.0),
      address: 'Kigali',
      isLoading: false,
    );
    when(() => cubit.state).thenReturn(seeded);
    whenListen<LocationPickerState>(
      cubit,
      const Stream<LocationPickerState>.empty(),
      initialState: seeded,
    );

    await tester.pumpWidget(
      MaterialApp(home: LocationPickerPage(locationPickerCubit: cubit)),
    );
    await tester.pump();

    final confirm = find.widgetWithText(TextButton, 'Confirm');
    expect(confirm, findsOneWidget);
    expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
    expect(find.text('Use this location'), findsOneWidget);
  });
}
