import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/fcm_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'firebase_options.dart';
import 'presentation/bloc/settings/settings_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Background message received - system handles notification display
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR', defaultValue: false)) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
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
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[AuthLink] Error handling initial link: $e');
    }
  }
}

void _listenForAuthLinks() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((Uri? uri) async {
    if (uri != null) {
      await _completeSignInWithEmailLink(uri.toString());
    }
  }).onError((Object e) {
    if (kDebugMode) {
      debugPrint('[AuthLink] Stream error: $e');
    }
  });
}

Future<void> _completeSignInWithEmailLink(String link) async {
  try {
    final auth = sl<AuthRepository>();
    if (!auth.isSignInWithEmailLink(link)) return;
    final email = auth.pendingEmailForLinkSignIn;
    if (email == null || email.isEmpty) return;
    await auth.signInWithEmailLink(email, link);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[AuthLink] Error completing sign-in: $e');
    }
  }
}
