import '../../../domain/entities/event_entity.dart';

/// State for create event form.
class CreateEventState {
  const CreateEventState({
    this.title = '',
    this.date,
    this.location = '',
    this.locationLat,
    this.locationLng,
    this.description = '',
    this.imageUrls = const [],
    this.status = EventStatus.draft,
    this.eventType = '',
    this.budget,
    this.startTime = '',
    this.endTime = '',
    this.venueName = '',
    this.locationVisibility = LocationVisibility.public,
    this.isSaving = false,
    this.isUploadingImage = false,
    this.error,
  });

  final String title;
  final DateTime? date;
  final String location;

  /// Latitude from place picker (for opening in maps).
  final double? locationLat;

  /// Longitude from place picker (for opening in maps).
  final double? locationLng;
  final String description;
  final List<String> imageUrls;
  final EventStatus status;
  final String eventType;
  final double? budget;
  final String startTime;
  final String endTime;
  final String venueName;
  final LocationVisibility locationVisibility;
  final bool isSaving;
  final bool isUploadingImage;
  final String? error;

  CreateEventState copyWith({
    String? title,
    DateTime? date,
    String? location,
    double? locationLat,
    double? locationLng,
    String? description,
    List<String>? imageUrls,
    EventStatus? status,
    String? eventType,
    double? budget,
    String? startTime,
    String? endTime,
    String? venueName,
    LocationVisibility? locationVisibility,
    bool? isSaving,
    bool? isUploadingImage,
    String? error,
  }) {
    return CreateEventState(
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      eventType: eventType ?? this.eventType,
      budget: budget ?? this.budget,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venueName: venueName ?? this.venueName,
      locationVisibility: locationVisibility ?? this.locationVisibility,
      isSaving: isSaving ?? this.isSaving,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      error: error,
    );
  }
}
