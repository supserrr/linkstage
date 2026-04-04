import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'firebase_options.dart';
import 'presentation/bloc/settings/settings_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background message received - system handles notification display
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppTheme.preloadFonts();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Font preload failed: $e');
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable persistence so Firestore serves cached data first (instant loads).
    // Must be set before any other Firestore operations.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    final useAuthEmulator = const bool.fromEnvironment(
      'USE_AUTH_EMULATOR',
      defaultValue: false,
    );
    final useFirestoreEmulator = const bool.fromEnvironment(
      'USE_FIRESTORE_EMULATOR',
      defaultValue: false,
    );

    if (useAuthEmulator) {
      const customHost = String.fromEnvironment('AUTH_EMULATOR_HOST');
      final host = customHost.isEmpty ? 'localhost' : customHost;
      const authEmulatorPort = 9099;
      await FirebaseAuth.instance.useAuthEmulator(host, authEmulatorPort);
      if (kDebugMode) {
        debugPrint(
          'Firebase Auth emulator: $host:$authEmulatorPort '
          '(run: firebase emulators:start --only auth, or include auth in suite)',
        );
      }
    }
    // Auth emulator tokens are not valid on production Firestore; rules see no user → permission-denied.
    if (useFirestoreEmulator || useAuthEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      if (kDebugMode && useAuthEmulator) {
        debugPrint(
          'Firebase Firestore emulator: localhost:8080 '
          '(enabled with auth emulator so signed-in writes match security rules)',
        );
      }
    }
  } on UnimplementedError catch (_) {
    if (kDebugMode) {
      debugPrint(
        'Firebase not configured. Run: dart run flutterfire_cli:flutterfire configure',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init failed: $e');
    }
  }

  await initInjection();

  await _handleInitialAuthLink();
  _listenForAuthLinks();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await FcmService.initialize();
    final fcm = sl<FcmService>();
    final auth = sl<AuthRepository>();
    final settings = sl<SettingsCubit>();
    if (auth.currentUser != null && settings.state.notificationsEnabled) {
      await fcm.registerTokenIfNeeded();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('FCM init failed: $e');
    }
  }

  runApp(const LinkStageApp());
}

Future<void> _handleInitialAuthLink() async {
  try {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();
    if (uri != null) {
      await _completeSignInWithEmailLink(uri.toString());
    }
  } catch (e, st) {
    developer.log(
      'Error handling initial link: $e',
      name: 'linkstage.auth',
      error: e,
      stackTrace: st,
    );
  }
}

void _listenForAuthLinks() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream
      .listen((Uri? uri) async {
        if (uri != null) {
          await _completeSignInWithEmailLink(uri.toString());
        }
      })
      .onError((Object e, StackTrace st) {
        developer.log(
          'Auth link stream error: $e',
          name: 'linkstage.auth',
          error: e,
          stackTrace: st,
        );
      });
}

Future<void> _completeSignInWithEmailLink(String link) async {
  try {
    final auth = sl<AuthRepository>();
    if (!auth.isSignInWithEmailLink(link)) return;
    final email = auth.pendingEmailForLinkSignIn;
    if (email == null || email.isEmpty) {
      developer.log(
        'Email link opened but no pending email in storage. '
        'Use the same device/app session after "Send sign-in link", or open the link in the browser and use "Open in app".',
        name: 'linkstage.auth',
      );
      return;
    }
    await auth.signInWithEmailLink(email, link);
  } catch (e, st) {
    developer.log(
      'Error completing email link sign-in: $e',
      name: 'linkstage.auth',
      error: e,
      stackTrace: st,
    );
  }
}
