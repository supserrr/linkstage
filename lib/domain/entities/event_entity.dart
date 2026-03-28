import 'package:equatable/equatable.dart';

/// Event status.
enum EventStatus { draft, open, booked, completed }

/// Who can see the event location on cards and detail (planner always sees full location).
enum LocationVisibility {
  /// Shown to everyone.
  public,

  /// Hidden from everyone except the planner.
  private,

  /// Shown only to the planner and creatives with an accepted booking for this event.
  acceptedCreatives,
}

/// Domain entity for an event.
class EventEntity extends Equatable {
  const EventEntity({
    required this.id,
    required this.plannerId,
    required this.title,
    this.date,
    this.location = '',
    this.description = '',
    this.status = EventStatus.draft,
    this.imageUrls = const [],
    this.eventType = '',
    this.budget,
    this.startTime = '',
    this.endTime = '',
    this.venueName = '',
    this.showOnProfile = true,
    this.locationVisibility = LocationVisibility.public,
  });

  final String id;
  final String plannerId;
  final String title;
  final DateTime? date;
  final String location;
  final String description;
  final EventStatus status;
  final List<String> imageUrls;
  final String eventType;
  final double? budget;
  final String startTime;
  final String endTime;
  final String venueName;
  final bool showOnProfile;
  final LocationVisibility locationVisibility;

  static LocationVisibility? locationVisibilityFromKey(String? key) {
    switch (key) {
      case 'public':
        return LocationVisibility.public;
      case 'private':
        return LocationVisibility.private;
      case 'acceptedCreatives':
        return LocationVisibility.acceptedCreatives;
      default:
        return null;
    }
  }

  String get locationVisibilityKey {
    switch (locationVisibility) {
      case LocationVisibility.public:
        return 'public';
      case LocationVisibility.private:
        return 'private';
      case LocationVisibility.acceptedCreatives:
        return 'acceptedCreatives';
    }
  }

  static EventStatus? statusFromKey(String? key) {
    switch (key) {
      case 'draft':
        return EventStatus.draft;
      case 'open':
        return EventStatus.open;
      case 'booked':
        return EventStatus.booked;
      case 'completed':
        return EventStatus.completed;
      default:
        return null;
    }
  }

  String get statusKey {
    switch (status) {
      case EventStatus.draft:
        return 'draft';
      case EventStatus.open:
        return 'open';
      case EventStatus.booked:
        return 'booked';
      case EventStatus.completed:
        return 'completed';
    }
  }

  @override
  List<Object?> get props => [
    id,
    plannerId,
    title,
    date,
    location,
    description,
    status,
    imageUrls,
    eventType,
    budget,
    startTime,
    endTime,
    venueName,
    showOnProfile,
    locationVisibility,
  ];
}
