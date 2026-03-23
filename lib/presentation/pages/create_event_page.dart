import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_borders.dart';
import '../bloc/create_event/create_event_cubit.dart';
import 'location_picker_page.dart';
import '../bloc/create_event/create_event_state.dart';
import '../../core/di/injection.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/router/app_router.dart';
import '../../core/router/auth_redirect.dart';
import '../../data/datasources/portfolio_storage_datasource.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/event_repository.dart';

/// Standard event types (match search filters; used for dropdown on create/edit).
const List<String> _standardEventTypes = [
  'Wedding',
  'Music',
  'Corporate',
  'Party',
  'Conference',
  'Concert',
  'Workshop',
];

/// Page for creating or editing an event (gig).
/// When [invitedCreativeId] is set, the planner is booking this creative; an
/// invitation will be created when the event is saved.
String _locationVisibilityHint(LocationVisibility v) {
  switch (v) {
    case LocationVisibility.public:
      return 'Address and place name appear on event cards and detail for everyone.';
    case LocationVisibility.private:
      return 'Location is hidden from others; only you see the full address.';
    case LocationVisibility.acceptedCreatives:
      return 'Others see "Location on request" until you accept a creative for this event.';
  }
}

class CreateEventPage extends StatelessWidget {
  const CreateEventPage({super.key, this.event, this.invitedCreativeId = ''});

  final EventEntity? event;

  /// Creative to invite when creating a new event (from Book Now flow).
  final String invitedCreativeId;

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.stretchedDots(
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
        ),
      );
    }
    final isEditing = event != null;
    return BlocProvider(
      create: (_) => CreateEventCubit(
        sl<EventRepository>(),
        sl<BookingRepository>(),
        user.id,
        initialEvent: event,
        invitedCreativeId: invitedCreativeId,
      ),
      child: _CreateEventView(isEditing: isEditing),
    );
  }
}

class _CreateEventView extends StatelessWidget {
  const _CreateEventView({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          BlocBuilder<CreateEventCubit, CreateEventState>(
            buildWhen: (a, b) => a.isSaving != b.isSaving,
            builder: (context, state) {
              if (state.isSaving) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: LoadingAnimationWidget.stretchedDots(
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CreateEventCubit, CreateEventState>(
        listenWhen: (a, b) => a.error != b.error,
        listener: (context, state) {
          if (state.error != null) {
            showToast(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Title',
                child: TextFormField(
                  initialValue: state.title,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Kigali wedding reception, corporate year-end party',
                  ),
                  onChanged: (v) =>
                      context.read<CreateEventCubit>().setTitle(v),
                ),
              ),
              _Section(
                title: 'Event Type',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue:
                          _standardEventTypes.contains(state.eventType)
                          ? state.eventType
                          : 'Other',
                      decoration: const InputDecoration(
                        hintText: 'Select type',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        ..._standardEventTypes.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)),
                        ),
                        const DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          context.read<CreateEventCubit>().setEventType(
                            v == 'Other' ? state.eventType : v,
                          );
                        }
                      },
                    ),
                    if (!_standardEventTypes.contains(state.eventType)) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: state.eventType,
                        decoration: const InputDecoration(
                          hintText:
                              'Enter event type (e.g. Umuganura, tech meetup)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            context.read<CreateEventCubit>().setEventType(v),
                      ),
                    ],
                  ],
                ),
              ),
              _Section(
                title: 'Date',
                child: InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: AppBorders.borderRadius,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Select event date',
                    ),
                    child: Text(
                      state.date != null
                          ? '${state.date!.day}/${state.date!.month}/${state.date!.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: state.date != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              _Section(
                title: 'Start Time',
                child: InkWell(
                  onTap: () => _pickStartTime(context),
                  borderRadius: AppBorders.borderRadius,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Select start time',
                    ),
                    child: Text(
                      _formatTimeForDisplay(state.startTime),
                      style: TextStyle(
                        color: state.startTime.isNotEmpty
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              _Section(
                title: 'End Time',
                child: InkWell(
                  onTap: () => _pickEndTime(context),
                  borderRadius: AppBorders.borderRadius,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Select end time',
                    ),
                    child: Text(
                      _formatTimeForDisplay(state.endTime),
                      style: TextStyle(
                        color: state.endTime.isNotEmpty
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              _Section(
                title: 'Budget',
                child: TextFormField(
                  initialValue: state.budget != null
                      ? state.budget!.toStringAsFixed(0)
                      : '',
                  decoration: const InputDecoration(
                    hintText: 'Optional, in RWF - leave blank if not specified',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) {
                    final n = double.tryParse(v.trim());
                    context.read<CreateEventCubit>().setBudget(n);
                  },
                ),
              ),
              _Section(
                title: 'Location',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: state.venueName,
                      decoration: const InputDecoration(
                        labelText: 'Place name',
                        hintText:
                            'e.g. Kigali Convention Centre, Intare Arena',
                      ),
                      onChanged: (v) =>
                          context.read<CreateEventCubit>().setVenueName(v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.location,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'e.g. KG 11 Ave, Remera, Kigali',
                      ),
                      onChanged: (v) =>
                          context.read<CreateEventCubit>().setLocation(v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _useCurrentLocation(context),
                            icon: const Icon(Icons.my_location),
                            label: const Text('Use current location'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickOnMap(context, state),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Pick on map'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location visibility',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<LocationVisibility>(
                      segments: const [
                        ButtonSegment<LocationVisibility>(
                          value: LocationVisibility.public,
                          label: Text('Public'),
                          tooltip: 'Shown to everyone',
                        ),
                        ButtonSegment<LocationVisibility>(
                          value: LocationVisibility.private,
                          label: Text('Private'),
                          tooltip: 'Hidden until you share',
                        ),
                        ButtonSegment<LocationVisibility>(
                          value: LocationVisibility.acceptedCreatives,
                          label: Text('Accepted'),
                          tooltip: 'Visible to creatives you accept',
                        ),
                      ],
                      selected: {state.locationVisibility},
                      onSelectionChanged: (s) {
                        if (s.isNotEmpty) {
                          context
                              .read<CreateEventCubit>()
                              .setLocationVisibility(s.first);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _locationVisibilityHint(state.locationVisibility),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Description',
                child: TextFormField(
                  initialValue: state.description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe your event and what you need...',
                  ),
                  onChanged: (v) =>
                      context.read<CreateEventCubit>().setDescription(v),
                ),
              ),
              _Section(
                title: 'Pictures',
                child: _EventImagesSection(
                  imageUrls: state.imageUrls,
                  isUploading: state.isUploadingImage,
                  onAddImage: () => _addEventImage(context),
                  onRemoveImage: (url) =>
                      context.read<CreateEventCubit>().removeImageUrl(url),
                ),
              ),
              _Section(
                title: 'Status',
                child: DropdownButtonFormField<EventStatus>(
                  initialValue: state.status,
                  decoration: const InputDecoration(hintText: 'Select status'),
                  items: const [
                    DropdownMenuItem(
                      value: EventStatus.draft,
                      child: Text('Draft (save for later)'),
                    ),
                    DropdownMenuItem(
                      value: EventStatus.open,
                      child: Text('Open (visible to creatives)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      context.read<CreateEventCubit>().setStatus(v);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<CreateEventCubit, CreateEventState>(
                buildWhen: (a, b) =>
                    a.isSaving != b.isSaving || a.status != b.status,
                builder: (context, state) {
                  final label = state.status == EventStatus.open
                      ? 'Publish'
                      : 'Save';
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: state.isSaving ? null : () => _save(context),
                      child: state.isSaving
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: LoadingAnimationWidget.stretchedDots(
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 24,
                              ),
                            )
                          : Text(
                              label,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<CreateEventCubit>();
    final state = cubit.state;
    final initial = state.date ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      cubit.setDate(picked);
    }
  }

  TimeOfDay? _parseTime(String s) {
    if (s.isEmpty) return null;
    s = s.trim();
    final parts = s.split(RegExp(r'[:\s]')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      var m = int.tryParse(parts[1]);
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return TimeOfDay(hour: h, minute: m);
      }
      if (h != null && m != null && h >= 1 && h <= 12 && m >= 0 && m <= 59) {
        final pm =
            parts.length >= 3 &&
            (parts[2].toUpperCase().startsWith('P') ||
                parts[2].toUpperCase() == 'PM');
        final hour = pm ? (h == 12 ? 12 : h + 12) : (h == 12 ? 0 : h);
        return TimeOfDay(hour: hour, minute: m);
      }
    }
    return null;
  }

  String _timeToStorage(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeForDisplay(String stored) {
    if (stored.isEmpty) return 'Select time';
    final t = _parseTime(stored);
    if (t == null) return stored;
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final cubit = context.read<CreateEventCubit>();
    final state = cubit.state;
    final initial =
        _parseTime(state.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      cubit.setStartTime(_timeToStorage(picked));
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final cubit = context.read<CreateEventCubit>();
    final state = cubit.state;
    final initial =
        _parseTime(state.endTime) ?? const TimeOfDay(hour: 17, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      cubit.setEndTime(_timeToStorage(picked));
    }
  }

  Future<void> _useCurrentLocation(BuildContext context) async {
    final cubit = context.read<CreateEventCubit>();
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled && context.mounted) {
        showToast(context, 'Location services are disabled', isError: true);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          showToast(context, 'Location permission denied', isError: true);
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final addr = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      cubit.setLocationFromPlace(
        address: addr,
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      if (context.mounted) {
        showToast(
          context,
          'Could not get location: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickOnMap(BuildContext context, CreateEventState state) async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLat: state.locationLat,
          initialLng: state.locationLng,
        ),
      ),
    );
    if (result != null && context.mounted) {
      context.read<CreateEventCubit>().setLocationFromPlace(
        address: result.address,
        lat: result.lat,
        lng: result.lng,
      );
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

  Future<void> _addEventImage(BuildContext context) async {
    final cubit = context.read<CreateEventCubit>();
    final user = sl<AuthRedirectNotifier>().user;
    if (user == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    cubit.setUploadingImage(true);
    try {
      final url = await sl<PortfolioStorageDataSource>().uploadPortfolioMedia(
        file,
        user.id,
        isVideo: false,
      );
      if (context.mounted) {
        cubit.addImageUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        cubit.setImageError(e.toString().replaceAll('Exception:', '').trim());
      }
    }
  }

  Future<void> _save(BuildContext context) async {
    final eventId = await context.read<CreateEventCubit>().save();
    if (eventId != null && context.mounted) {
      context.go(AppRoutes.eventDetail(eventId));
    } else if (eventId == null && context.mounted) {
      final cubit = context.read<CreateEventCubit>();
      if (cubit.state.error == null) {
        context.go(AppRoutes.bookings);
      }
    }
  }
}

class _EventImagesSection extends StatelessWidget {
  const _EventImagesSection({
    required this.imageUrls,
    required this.isUploading,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  final List<String> imageUrls;
  final bool isUploading;
  final VoidCallback onAddImage;
  final void Function(String url) onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...imageUrls.map(
              (url) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(24, 24),
                      ),
                      onPressed: () => onRemoveImage(url),
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: LoadingAnimationWidget.stretchedDots(
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              )
            else
              InkWell(
                onTap: onAddImage,
                borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppBorders.chipRadius),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
