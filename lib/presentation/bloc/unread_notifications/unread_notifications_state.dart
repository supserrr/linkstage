/// State for unread notifications count (used by dashboard badge).
class UnreadNotificationsState {
  const UnreadNotificationsState({this.unreadCount = 0});

  final int unreadCount;
}
