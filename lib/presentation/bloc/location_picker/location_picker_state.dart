import 'package:latlong2/latlong.dart';

class LocationPickerState {
  const LocationPickerState({
    this.selectedPoint,
    this.address,
    this.isLoading = false,
  });

  final LatLng? selectedPoint;
  final String? address;
  final bool isLoading;

  LocationPickerState copyWith({
    LatLng? selectedPoint,
    String? address,
    bool clearAddress = false,
    bool? isLoading,
  }) {
    return LocationPickerState(
      selectedPoint: selectedPoint ?? this.selectedPoint,
      address: clearAddress ? null : (address ?? this.address),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
