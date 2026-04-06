import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

typedef HttpPost =
    Future<http.Response> Function(
      Uri url, {
      Map<String, String>? headers,
      Object? body,
    });

/// Calls Supabase Edge Functions with the signed-in user's ID token after
/// domain writes (bookings, collabs, planner publish) so the backend can fan out FCM.
class PushNotificationService {
  PushNotificationService({FirebaseAuth? firebaseAuth, HttpPost? httpPost})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _httpPost = httpPost ?? http.post;

  final FirebaseAuth _auth;
  final HttpPost _httpPost;

  static const String _functionName = 'send-push-notification';
  static const String _plannerEventFunctionName =
      'notify-planner-event-published';
  static const String _syncAcceptedEventIdFunctionName =
      'sync-accepted-event-id';

  /// Notify followers of a planner when the planner publishes an event.
  /// Fire-and-forget; errors are logged, not thrown.
  Future<void> notifyFollowersOfPlannerEvent({
    required String eventId,
    required String plannerId,
    required String eventTitle,
    required String plannerName,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;

      final token = await firebaseUser.getIdToken(false);
      if (token == null || token.isEmpty) return;

      final url = Uri.parse(
        '${SupabaseConfig.url}/functions/v1/$_plannerEventFunctionName',
      );

      final bodyJson = {
        'eventId': eventId,
        'plannerId': plannerId,
        'eventTitle': eventTitle,
        'plannerName': plannerName,
      };

      final response = await _httpPost(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyJson),
      );

      if (response.statusCode >= 400) {
        developer.log(
          'PushNotificationService.notifyFollowersOfPlannerEvent: ${response.statusCode} ${response.body}',
          name: 'PushNotificationService',
        );
      }
    } catch (e, st) {
      developer.log(
        'PushNotificationService.notifyFollowersOfPlannerEvent error: $e',
        name: 'PushNotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Notify a user with a push. Fire-and-forget; errors are logged, not thrown.
  Future<void> notifyUser({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;

      final token = await firebaseUser.getIdToken(false);
      if (token == null || token.isEmpty) return;

      final url = Uri.parse(
        '${SupabaseConfig.url}/functions/v1/$_functionName',
      );

      final bodyJson = {
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'data': data,
      };

      final response = await _httpPost(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyJson),
      );

      if (response.statusCode >= 400) {
        developer.log(
          'PushNotificationService: ${response.statusCode} ${response.body}',
          name: 'PushNotificationService',
        );
      }
    } catch (e, st) {
      developer.log(
        'PushNotificationService error: $e',
        name: 'PushNotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Sync accepted_event_ids in Firestore when a booking is accepted or removed.
  /// Enables event location visibility for accepted creatives.
  /// Fire-and-forget; errors are logged, not thrown.
  Future<void> syncAcceptedEventId({
    required String creativeId,
    required String eventId,
    required bool add,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;

      final token = await firebaseUser.getIdToken(false);
      if (token == null || token.isEmpty) return;

      final url = Uri.parse(
        '${SupabaseConfig.url}/functions/v1/$_syncAcceptedEventIdFunctionName',
      );

      final bodyJson = {
        'creativeId': creativeId,
        'eventId': eventId,
        'action': add ? 'add' : 'remove',
      };

      final response = await _httpPost(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyJson),
      );

      if (response.statusCode >= 400) {
        developer.log(
          'PushNotificationService.syncAcceptedEventId: ${response.statusCode} ${response.body}',
          name: 'PushNotificationService',
        );
      }
    } catch (e, st) {
      developer.log(
        'PushNotificationService.syncAcceptedEventId error: $e',
        name: 'PushNotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }
}
