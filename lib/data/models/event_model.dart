import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event_entity.dart';

/// Firestore model for event document.
class EventModel {
  EventModel({
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

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['date'] as Timestamp?;
    final imageUrlsRaw = data['imageUrls'];
    final imageUrls = imageUrlsRaw is List
        ? (imageUrlsRaw)
              .map((e) => e is String ? e : e.toString())
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    final budgetRaw = data['budget'];
    final budget = budgetRaw is num ? budgetRaw.toDouble() : null;

    final showOnProfileRaw = data['showOnProfile'];
    final showOnProfile = showOnProfileRaw is bool
        ? showOnProfileRaw
        : (showOnProfileRaw == false ? false : true);

    final locationVisibilityRaw = data['locationVisibility'] as String?;
    final locationVisibility =
        EventEntity.locationVisibilityFromKey(locationVisibilityRaw) ??
        LocationVisibility.public;

    return EventModel(
      id: doc.id,
      plannerId: data['plannerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      date: ts?.toDate(),
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status:
          EventEntity.statusFromKey(data['status'] as String?) ??
          EventStatus.draft,
      imageUrls: imageUrls,
      eventType: data['eventType'] as String? ?? '',
      budget: budget,
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      venueName: data['venueName'] as String? ?? '',
      showOnProfile: showOnProfile,
      locationVisibility: locationVisibility,
    );
  }

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

  Map<String, dynamic> toFirestore() {
    return {
      'plannerId': plannerId,
      'title': title,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'location': location,
      'description': description,
      'status': _statusKey,
      'imageUrls': imageUrls,
      'eventType': eventType,
      if (budget != null) 'budget': budget,
      if (startTime.isNotEmpty) 'startTime': startTime,
      if (endTime.isNotEmpty) 'endTime': endTime,
      if (venueName.isNotEmpty) 'venueName': venueName,
      'showOnProfile': showOnProfile,
      'locationVisibility': _locationVisibilityKey,
    };
  }

  String get _locationVisibilityKey {
    switch (locationVisibility) {
      case LocationVisibility.public:
        return 'public';
      case LocationVisibility.private:
        return 'private';
      case LocationVisibility.acceptedCreatives:
        return 'acceptedCreatives';
    }
  }

  String get _statusKey {
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

  EventEntity toEntity() {
    return EventEntity(
      id: id,
      plannerId: plannerId,
      title: title,
      date: date,
      location: location,
      description: description,
      status: status,
      imageUrls: imageUrls,
      eventType: eventType,
      budget: budget,
      startTime: startTime,
      endTime: endTime,
      venueName: venueName,
      showOnProfile: showOnProfile,
      locationVisibility: locationVisibility,
    );
  }
}
