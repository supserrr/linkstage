import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'unread_notifications_state.dart';

/// Cubit that exposes unread notification count for dashboard badge.
class UnreadNotificationsCubit extends Cubit<UnreadNotificationsState> {
  UnreadNotificationsCubit(
    this._notificationRepository,
    this._userId,
    this._role,
  ) : super(const UnreadNotificationsState()) {
    _subscribe();
  }

  final NotificationRepository _notificationRepository;
  final String _userId;
  final UserRole _role;

  StreamSubscription<List<NotificationEntity>>? _subscription;
  StreamSubscription<Set<String>>? _readIdsSubscription;

  List<NotificationEntity> _notifications = [];
  Set<String> _readIds = const {};

  void _subscribe() {
    _subscription?.cancel();
    _readIdsSubscription?.cancel();

    _subscription = _notificationRepository
        .watchNotifications(_userId, _role)
        .listen((notifications) {
      _notifications = notifications;
      _emitCount();
    }, onError: (_) {
      emit(const UnreadNotificationsState(unreadCount: 0));
    });

    _readIdsSubscription = _notificationRepository
        .watchReadNotificationIds(_userId)
        .listen((readIds) {
      _readIds = readIds;
      _emitCount();
    });
  }

  void _emitCount() {
    final unreadCount =
        _notifications.where((n) => !_readIds.contains(n.id)).length;
    emit(UnreadNotificationsState(unreadCount: unreadCount));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _readIdsSubscription?.cancel();
    return super.close();
  }
}
