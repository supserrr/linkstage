import '../entities/notification_entity.dart';
import '../entities/user_entity.dart';

/// Repository for aggregating and streaming in-app notifications
/// from bookings and collaborations.
abstract class NotificationRepository {
  /// Real-time stream of notifications for the given user.
  Stream<List<NotificationEntity>> watchNotifications(
    String userId,
    UserRole role,
  );

  /// Mark a notification as read.
  Future<void> markAsRead(String userId, String notificationId);

  /// Mark all given notifications as read.
  Future<void> markAllAsRead(String userId, List<String> notificationIds);

  /// Stream of notification IDs the user has marked as read.
  Stream<Set<String>> watchReadNotificationIds(String userId);
}
