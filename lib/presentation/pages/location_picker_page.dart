import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';

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
  const LocationPickerPage({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  static const LatLng _kigali = LatLng(-1.9403, 29.8739);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late MapController _mapController;
  LatLng? _selectedPoint;
  String? _address;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _address = null;
      _isLoading = true;
    });
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final addr = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      if (mounted) {
        setState(() {
          _address = addr;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
          _isLoading = false;
        });
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

  void _confirm() {
    if (_selectedPoint == null) return;
    final addr =
        _address ??
        '${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}';
    Navigator.of(context).pop(
      LocationPickerResult(
        address: addr,
        lat: _selectedPoint!.latitude,
        lng: _selectedPoint!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        _selectedPoint ??
        (widget.initialLat != null && widget.initialLng != null
            ? LatLng(widget.initialLat!, widget.initialLng!)
            : LocationPickerPage._kigali);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: _selectedPoint != null ? _confirm : null,
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
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.linkstage.app',
                ),
                if (_selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint!,
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
          if (_selectedPoint != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: LoadingAnimationWidget.stretchedDots(
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          )
                        : Text(
                            _address ?? 'Getting address...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  FilledButton(
                    onPressed: _confirm,
                    child: const Text('Use this location'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
