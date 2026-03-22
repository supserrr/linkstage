import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'location_picker_state.dart';

class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit({LatLng? initialPoint})
    : super(LocationPickerState(selectedPoint: initialPoint));

  void tapMap(LatLng point) {
    emit(
      state.copyWith(selectedPoint: point, clearAddress: true, isLoading: true),
    );
  }

  void setGeocodeResult({required String address, required bool loading}) {
    emit(state.copyWith(address: address, isLoading: loading));
  }
}
