import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:linkstage/core/services/push_notification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  group('PushNotificationService', () {
    late MockFirebaseAuth auth;
    late MockUser user;

    setUp(() {
      auth = MockFirebaseAuth();
      user = MockUser();
    });

    test('returns early when currentUser is null', () async {
      when(() => auth.currentUser).thenReturn(null);

      var postCalls = 0;
      final svc = PushNotificationService(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async {
          postCalls++;
          return http.Response('', 200);
        },
      );

      await svc.notifyUser(
        targetUserId: 't1',
        title: 'hi',
        body: 'b',
        data: const {'k': 'v'},
      );
      expect(postCalls, 0);
    });

    test('returns early when token is empty', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(false)).thenAnswer((_) async => '');

      var postCalls = 0;
      final svc = PushNotificationService(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async {
          postCalls++;
          return http.Response('', 200);
        },
      );

      await svc.syncAcceptedEventId(creativeId: 'c1', eventId: 'e1', add: true);
      expect(postCalls, 0);
    });

    test('returns early when token is null', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(false)).thenAnswer((_) async => null);

      var postCalls = 0;
      final svc = PushNotificationService(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async {
          postCalls++;
          return http.Response('', 200);
        },
      );

      await svc.notifyFollowersOfPlannerEvent(
        eventId: 'e1',
        plannerId: 'p1',
        eventTitle: 'T',
        plannerName: 'P',
      );
      expect(postCalls, 0);
    });

    test(
      'posts JSON body with Authorization header when token present',
      () async {
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.getIdToken(false)).thenAnswer((_) async => 'token123');

        Uri? gotUrl;
        Map<String, String>? gotHeaders;
        Object? gotBody;
        final svc = PushNotificationService(
          firebaseAuth: auth,
          httpPost: (url, {headers, body}) async {
            gotUrl = url;
            gotHeaders = headers;
            gotBody = body;
            return http.Response('ok', 200);
          },
        );

        await svc.notifyFollowersOfPlannerEvent(
          eventId: 'e1',
          plannerId: 'p1',
          eventTitle: 'T',
          plannerName: 'P',
        );

        expect(
          gotUrl.toString(),
          contains('/functions/v1/notify-planner-event-published'),
        );
        expect(gotHeaders, isNotNull);
        expect(gotHeaders!['Authorization'], 'Bearer token123');
        expect(gotHeaders!['Content-Type'], 'application/json');
        expect(gotBody, isA<String>());
        expect(gotBody as String, contains('"eventId":"e1"'));
      },
    );

    test('does not throw when server responds >=400', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(false)).thenAnswer((_) async => 'token123');

      final svc = PushNotificationService(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) async => http.Response('bad', 500),
      );

      await svc.notifyUser(
        targetUserId: 't1',
        title: 'hi',
        body: 'b',
        data: const {'k': 'v'},
      );
      await svc.syncAcceptedEventId(
        creativeId: 'c1',
        eventId: 'e1',
        add: false,
      );
    });

    test('does not throw when httpPost throws', () async {
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken(false)).thenAnswer((_) async => 'token123');

      final svc = PushNotificationService(
        firebaseAuth: auth,
        httpPost: (_, {headers, body}) => throw Exception('net'),
      );

      await svc.notifyFollowersOfPlannerEvent(
        eventId: 'e1',
        plannerId: 'p1',
        eventTitle: 'T',
        plannerName: 'P',
      );
    });
  });
}
