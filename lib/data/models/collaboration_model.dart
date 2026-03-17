import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/collaboration_entity.dart';

/// Firestore model for collaboration document.
class CollaborationModel {
  CollaborationModel({
    required this.id,
    required this.requesterId,
    required this.targetUserId,
    required this.description,
    this.status = CollaborationStatus.pending,
    this.title,
    this.eventId,
    this.createdAt,
    this.budget,
    this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.eventType,
    this.plannerConfirmedAt,
    this.creativeConfirmedAt,
  });

  factory CollaborationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp?;
    final dateTs = data['date'] as Timestamp?;
    final budgetVal = data['budget'];
    final plannerTs = data['plannerConfirmedAt'] as Timestamp?;
    final creativeTs = data['creativeConfirmedAt'] as Timestamp?;
    return CollaborationModel(
      id: doc.id,
      requesterId: data['requesterId'] as String? ?? '',
      targetUserId: data['targetUserId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: CollaborationEntity.statusFromKey(data['status'] as String?) ??
          CollaborationStatus.pending,
      title: data['title'] as String?,
      eventId: data['eventId'] as String?,
      createdAt: ts?.toDate(),
      budget: budgetVal != null ? (budgetVal is num ? budgetVal.toDouble() : null) : null,
      date: dateTs?.toDate(),
      startTime: data['startTime'] as String?,
      endTime: data['endTime'] as String?,
      location: data['location'] as String?,
      eventType: data['eventType'] as String?,
      plannerConfirmedAt: plannerTs?.toDate(),
      creativeConfirmedAt: creativeTs?.toDate(),
    );
  }

  final String id;
  final String requesterId;
  final String targetUserId;
  final String description;
  final CollaborationStatus status;
  final String? title;
  final String? eventId;
  final DateTime? createdAt;
  final double? budget;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? eventType;
  final DateTime? plannerConfirmedAt;
  final DateTime? creativeConfirmedAt;

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'targetUserId': targetUserId,
      'description': description,
      'status': _statusKey,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (eventId != null) 'eventId': eventId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (budget != null) 'budget': budget,
      if (date != null) 'date': Timestamp.fromDate(date!),
      if (startTime != null && startTime!.isNotEmpty) 'startTime': startTime,
      if (endTime != null && endTime!.isNotEmpty) 'endTime': endTime,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (eventType != null && eventType!.isNotEmpty) 'eventType': eventType,
    };
  }

  String get _statusKey {
    switch (status) {
      case CollaborationStatus.pending:
        return 'pending';
      case CollaborationStatus.accepted:
        return 'accepted';
      case CollaborationStatus.declined:
        return 'declined';
      case CollaborationStatus.completed:
        return 'completed';
    }
  }

  CollaborationEntity toEntity() {
    return CollaborationEntity(
      id: id,
      requesterId: requesterId,
      targetUserId: targetUserId,
      description: description,
      status: status,
      title: title,
      eventId: eventId,
      createdAt: createdAt,
      budget: budget,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      eventType: eventType,
      plannerConfirmedAt: plannerConfirmedAt,
      creativeConfirmedAt: creativeConfirmedAt,
    );
  }
}
