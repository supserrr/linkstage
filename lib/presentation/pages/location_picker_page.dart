import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';

import '../bloc/location_picker/location_picker_cubit.dart';
import '../bloc/location_picker/location_picker_state.dart';

/// Result from the OSM location picker.
class LocationPickerResult {
  const LocationPickerResult({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;
}

/// Full-screen OSM map picker. Tap to select location; uses device geocoding
/// (free) to get address from coordinates.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
    this.locationPickerCubit,
  });

  final double? initialLat;
  final double? initialLng;
  final LocationPickerCubit? locationPickerCubit;

  static const LatLng _kigali = LatLng(-1.9403, 29.8739);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _onMapTap(BuildContext context, LatLng point) async {
    context.read<LocationPickerCubit>().tapMap(point);
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final addr = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      if (context.mounted) {
        context.read<LocationPickerCubit>().setGeocodeResult(
          address: addr,
          loading: false,
        );
      }
    } catch (_) {
      if (context.mounted) {
        context.read<LocationPickerCubit>().setGeocodeResult(
          address:
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
          loading: false,
        );
      }
    }
  }

  String _formatAddress(geocoding.Placemark p) {
    final parts = <String>[];
    if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
    if (p.subLocality != null && p.subLocality!.isNotEmpty) {
      parts.add(p.subLocality!);
    }
    if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
    if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
      parts.add(p.administrativeArea!);
    }
    if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
    return parts.join(', ');
  }

  void _confirm(BuildContext context, LocationPickerState locState) {
    final point = locState.selectedPoint;
    if (point == null) return;
    final addr =
        locState.address ??
        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    Navigator.of(context).pop(
      LocationPickerResult(
        address: addr,
        lat: point.latitude,
        lng: point.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPoint = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : null;

    final child = BlocBuilder<LocationPickerCubit, LocationPickerState>(
        builder: (context, locState) {
          final initial =
              locState.selectedPoint ??
              (widget.initialLat != null && widget.initialLng != null
                  ? LatLng(widget.initialLat!, widget.initialLng!)
                  : LocationPickerPage._kigali);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Pick location'),
              actions: [
                TextButton(
                  onPressed: locState.selectedPoint != null
                      ? () => _confirm(context, locState)
                      : null,
                  child: const Text('Confirm'),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initial,
                      initialZoom: 14,
                      onTap: (tapPosition, point) => _onMapTap(context, point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.linkstage.app',
                      ),
                      if (locState.selectedPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: locState.selectedPoint!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.place,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (locState.selectedPoint != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Expanded(
                          child: locState.isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: LoadingAnimationWidget.stretchedDots(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 24,
                                  ),
                                )
                              : Text(
                                  locState.address ?? 'Getting address...',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                        ),
                        FilledButton(
                          onPressed: () => _confirm(context, locState),
                          child: const Text('Use this location'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    final injected = widget.locationPickerCubit;
    if (injected != null) {
      return BlocProvider<LocationPickerCubit>.value(value: injected, child: child);
    }
    return BlocProvider(
      create: (_) => LocationPickerCubit(initialPoint: initialPoint),
      child: child,
    );
  }
}
