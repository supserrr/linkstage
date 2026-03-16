import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';

/// Firestore model for booking document.
class BookingModel {
  BookingModel({
    required this.id,
    required this.eventId,
    required this.creativeId,
    required this.plannerId,
    this.status = BookingStatus.pending,
    this.agreedPrice,
    this.createdAt,
    this.plannerConfirmedAt,
    this.creativeConfirmedAt,
    this.wasInvitation,
  });

  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp?;
    final plannerTs = data['plannerConfirmedAt'] as Timestamp?;
    final creativeTs = data['creativeConfirmedAt'] as Timestamp?;
    return BookingModel(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      creativeId: data['creativeId'] as String? ?? '',
      plannerId: data['plannerId'] as String? ?? '',
      status: BookingEntity.statusFromKey(data['status'] as String?) ??
          BookingStatus.pending,
      agreedPrice: (data['agreedPrice'] as num?)?.toDouble(),
      createdAt: ts?.toDate(),
      plannerConfirmedAt: plannerTs?.toDate(),
      creativeConfirmedAt: creativeTs?.toDate(),
      wasInvitation: data['wasInvitation'] as bool?,
    );
  }

  final String id;
  final String eventId;
  final String creativeId;
  final String plannerId;
  final BookingStatus status;
  final double? agreedPrice;
  final DateTime? createdAt;
  final DateTime? plannerConfirmedAt;
  final DateTime? creativeConfirmedAt;
  final bool? wasInvitation;

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'creativeId': creativeId,
      'plannerId': plannerId,
      'status': _statusKey,
      if (agreedPrice != null) 'agreedPrice': agreedPrice,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (wasInvitation != null) 'wasInvitation': wasInvitation,
    };
  }

  String get _statusKey {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.invited:
        return 'invited';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.declined:
        return 'declined';
      case BookingStatus.completed:
        return 'completed';
    }
  }

  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      eventId: eventId,
      creativeId: creativeId,
      plannerId: plannerId,
      status: status,
      agreedPrice: agreedPrice,
      createdAt: createdAt,
      plannerConfirmedAt: plannerConfirmedAt,
      creativeConfirmedAt: creativeConfirmedAt,
      wasInvitation: wasInvitation,
    );
  }
}
