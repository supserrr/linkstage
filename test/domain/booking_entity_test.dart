import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/booking_entity.dart';

void main() {
  test('statusFromKey covers all statuses', () {
    expect(BookingEntity.statusFromKey('pending'), BookingStatus.pending);
    expect(BookingEntity.statusFromKey('invited'), BookingStatus.invited);
    expect(BookingEntity.statusFromKey('accepted'), BookingStatus.accepted);
    expect(BookingEntity.statusFromKey('declined'), BookingStatus.declined);
    expect(BookingEntity.statusFromKey('completed'), BookingStatus.completed);
    expect(BookingEntity.statusFromKey('x'), null);
  });

  test('props', () {
    final t = DateTime.utc(2025);
    final a = BookingEntity(
      id: '1',
      eventId: 'e',
      creativeId: 'c',
      plannerId: 'p',
      status: BookingStatus.accepted,
      agreedPrice: 100,
      createdAt: t,
      plannerConfirmedAt: t,
      creativeConfirmedAt: t,
      wasInvitation: true,
    );
    expect(a, a);
  });
}
