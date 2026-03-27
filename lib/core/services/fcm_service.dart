import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../di/injection.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../domain/repositories/auth_repository.dart';
import '../router/app_router.dart';

/// Handles FCM token registration and push notification events.
/// Respects notificationsEnabled from settings (caller checks before init).
class FcmService {
  FcmService(
    this._userRemoteDataSource,
    this._authRepository,
  );

  final UserRemoteDataSource _userRemoteDataSource;
  final AuthRepository _authRepository;

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS)
    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Create Android notification channel (recommended)
    if (Platform.isAndroid) {
      // Channel is typically created in native AndroidManifest
      // or via flutter_local_notifications. For basic FCM, the default channel works.
    }

    final service = sl<FcmService>();

    // Token refresh listener
    messaging.onTokenRefresh.listen((token) {
      service._onToken(token);
    });

    // Get initial token
    final token = await messaging.getToken();
    if (token != null) {
      service._onToken(token);
    }

    // Foreground message handler (must be top-level or static for background)
    FirebaseMessaging.onMessage.listen(service._onForegroundMessage);

    // Background/terminated: opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(service._onMessageOpenedApp);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      service._handleNotificationPayload(initial);
    }
  }

  Future<void> _onToken(String token) async {
    final user = _authRepository.currentUser;
    if (user == null) return;
    // Token registration - caller ensures notificationsEnabled (SettingsCubit)
    await _userRemoteDataSource.setFcmToken(user.id, token);
  }

  void _onForegroundMessage(RemoteMessage message) {
    // App is in foreground - can show in-app banner or update UI
    // For now we rely on the notification tray (if displayed by system)
    // and real-time Firestore for in-app updates
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleNotificationPayload(message);
  }

  static bool _isAllowedRoute(String route) {
    if (route.startsWith('/event/') && route.contains('/applicants')) return true;
    if (route == '/bookings') return true;
    if (route == '/collaboration/detail') return true;
    if (route == '/notifications') return true;
    if (route.startsWith('/event/') && !route.contains('/applicants')) return true;
    if (route.startsWith('/messages/chat/')) return true;
    if (route.startsWith('/messages/with/')) return true;
    return false;
  }

  void _handleNotificationPayload(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    final route = data['route'] as String?;
    if (route == null || route.isEmpty) return;
    if (!_isAllowedRoute(route)) return;

    AppRouter.router.go(route);
  }

  /// Call when user logs in and notifications are enabled. Registers token.
  Future<void> registerTokenIfNeeded() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _userRemoteDataSource.setFcmToken(user.id, token);
    }
  }

  /// Call when user disables notifications or logs out. Removes token.
  Future<void> unregisterToken() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _userRemoteDataSource.removeFcmToken(user.id, token);
    }
  }
}
