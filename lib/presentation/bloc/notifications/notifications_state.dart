import '../../../domain/entities/notification_entity.dart';

/// State for the notifications page.
class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.readIds = const {},
    this.hasLoaded = false,
    this.error,
  });

  final List<NotificationEntity> notifications;
  final Set<String> readIds;

  /// True once we've received at least one emission from the stream.
  /// Skeleton shows until then; empty state only when hasLoaded and empty.
  final bool hasLoaded;
  final String? error;

  bool isRead(NotificationEntity n) => readIds.contains(n.id);

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    Set<String>? readIds,
    bool? hasLoaded,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      readIds: readIds ?? this.readIds,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: error,
    );
  }
}
