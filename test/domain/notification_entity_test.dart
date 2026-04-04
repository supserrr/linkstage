import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/notification_entity.dart';

void main() {
  test('props', () {
    final t = DateTime.utc(2025);
    final n = NotificationEntity(
      id: '1',
      type: NotificationType.bookingAccepted,
      title: 'T',
      createdAt: t,
      route: '/r',
    );
    expect(
      n,
      NotificationEntity(
        id: '1',
        type: NotificationType.bookingAccepted,
        title: 'T',
        createdAt: t,
        route: '/r',
      ),
    );
  });
}
