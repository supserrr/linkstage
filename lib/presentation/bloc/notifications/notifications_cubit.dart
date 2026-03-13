import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'notifications_state.dart';

/// Delay before treating empty result as confirmed. Must be long enough that
/// streams emitting in sequence never cause an empty flash when notifications exist.
const Duration _emptyDebounceDelay = Duration(milliseconds: 600);

/// Cubit for the notifications page. Subscribes to real-time notification stream.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._notificationRepository, this._userId, this._role)
      : super(const NotificationsState()) {
    _subscribe();
  }

  final NotificationRepository _notificationRepository;
  final String _userId;
  final UserRole _role;

  StreamSubscription<List<NotificationEntity>>? _subscription;
  StreamSubscription<Set<String>>? _readIdsSubscription;
  Timer? _emptyDebounceTimer;

  List<NotificationEntity> _notifications = [];
  Set<String> _readIds = const {};

  void _subscribe() {
    _subscription?.cancel();
    _readIdsSubscription?.cancel();
    _emptyDebounceTimer?.cancel();
    if (!state.hasLoaded) {
      emit(const NotificationsState());
    }

    _subscription = _notificationRepository
        .watchNotifications(_userId, _role)
        .listen(
          (notifications) {
            _notifications = notifications;
            _emitMerged();
          },
          onError: (e) {
            _emptyDebounceTimer?.cancel();
            emit(state.copyWith(
              hasLoaded: true,
              error: e.toString().replaceAll('Exception:', '').trim(),
            ));
          },
        );

    _readIdsSubscription = _notificationRepository
        .watchReadNotificationIds(_userId)
        .listen((readIds) {
      _readIds = readIds;
      _emitMerged();
    });
  }

  void _emitMerged() {
    if (_notifications.isNotEmpty) {
      _emptyDebounceTimer?.cancel();
      _emptyDebounceTimer = null;
      emit(state.copyWith(
        notifications: _notifications,
        readIds: _readIds,
        hasLoaded: true,
        error: null,
      ));
      return;
    }
    _emptyDebounceTimer?.cancel();
    _emptyDebounceTimer = Timer(_emptyDebounceDelay, () {
      if (!isClosed) {
        _emptyDebounceTimer = null;
        emit(state.copyWith(
          notifications: _notifications,
          readIds: _readIds,
          hasLoaded: true,
          error: null,
        ));
      }
    });
  }

  /// Re-subscribe to refresh (e.g. on pull-to-refresh).
  void load() {
    _subscribe();
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(_userId, notificationId);
  }

  /// Mark all current notifications as read.
  Future<void> markAllAsRead() async {
    final ids = state.notifications.map((n) => n.id).toList();
    if (ids.isEmpty) return;
    await _notificationRepository.markAllAsRead(_userId, ids);
  }

  @override
  Future<void> close() {
    _emptyDebounceTimer?.cancel();
    _subscription?.cancel();
    _readIdsSubscription?.cancel();
    return super.close();
  }
}
