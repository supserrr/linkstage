import 'package:linkstage/domain/entities/booking_entity.dart';
import 'package:linkstage/domain/entities/collaboration_entity.dart';
import 'package:linkstage/domain/entities/event_entity.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';

/// Stable test defaults; override fields via copyWith-style params where needed.
BookingEntity fakeBooking({
  String id = 'booking-test-1',
  String eventId = 'event-test-1',
  String creativeId = 'creative-test-1',
  String plannerId = 'planner-test-1',
  BookingStatus status = BookingStatus.pending,
}) {
  return BookingEntity(
    id: id,
    eventId: eventId,
    creativeId: creativeId,
    plannerId: plannerId,
    status: status,
    createdAt: DateTime.utc(2026, 1, 15),
  );
}

EventEntity fakeEvent({
  String id = 'event-test-1',
  String plannerId = 'planner-test-1',
  String title = 'Test Gig',
}) {
  return EventEntity(id: id, plannerId: plannerId, title: title);
}

CollaborationEntity fakeCollaboration({
  String id = 'collab-test-1',
  String requesterId = 'requester-test-1',
  String targetUserId = 'creative-test-1',
  CollaborationStatus status = CollaborationStatus.pending,
}) {
  return CollaborationEntity(
    id: id,
    requesterId: requesterId,
    targetUserId: targetUserId,
    description: 'Test proposal',
    status: status,
    createdAt: DateTime.utc(2026, 2, 1),
  );
}

ProfileEntity fakeProfile({
  String id = 'profile-test-1',
  String userId = 'user-test-1',
  String displayName = 'Test Creative',
}) {
  return ProfileEntity(id: id, userId: userId, displayName: displayName);
}

UserEntity fakeUser({
  String id = 'user-test-1',
  String email = 'user@test.com',
  UserRole? role = UserRole.creativeProfessional,
}) {
  return UserEntity(id: id, email: email, role: role);
}
