import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/notification_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/notification_repository.dart';
import 'package:linkstage/presentation/bloc/notifications/notifications_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserRole.eventPlanner);
  });

  test('hasLoaded becomes true after empty debounce', () async {
    final repo = MockNotificationRepository();
    when(
      () => repo.watchNotifications('u1', UserRole.eventPlanner),
    ).thenAnswer((_) => Stream.value(<NotificationEntity>[]));
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    final cubit = NotificationsCubit(repo, 'u1', UserRole.eventPlanner);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(cubit.state.hasLoaded, true);
    expect(cubit.state.notifications, isEmpty);
    await cubit.close();
  });

  test('emits error when notifications stream fails', () async {
    final controller = StreamController<List<NotificationEntity>>.broadcast();
    final repo = MockNotificationRepository();
    when(
      () => repo.watchNotifications('u1', UserRole.eventPlanner),
    ).thenAnswer((_) => controller.stream);
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    final cubit = NotificationsCubit(repo, 'u1', UserRole.eventPlanner);
    controller.addError(Exception('stream'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.error, isNotNull);
    await cubit.close();
    await controller.close();
  });

  test('emits error when read ids stream fails', () async {
    final notifController =
        StreamController<List<NotificationEntity>>.broadcast();
    final readController = StreamController<Set<String>>.broadcast();
    final repo = MockNotificationRepository();
    when(
      () => repo.watchNotifications('u1', UserRole.eventPlanner),
    ).thenAnswer((_) => notifController.stream);
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => readController.stream);

    final cubit = NotificationsCubit(repo, 'u1', UserRole.eventPlanner);
    notifController.add(<NotificationEntity>[]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    readController.addError(Exception('read ids'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.error, isNotNull);
    await cubit.close();
    await notifController.close();
    await readController.close();
  });

  test('load re-subscribes without throwing', () async {
    final repo = MockNotificationRepository();
    when(
      () => repo.watchNotifications('u1', UserRole.eventPlanner),
    ).thenAnswer((_) => Stream.value(<NotificationEntity>[]));
    when(
      () => repo.watchReadNotificationIds('u1'),
    ).thenAnswer((_) => Stream.value(<String>{}));

    final cubit = NotificationsCubit(repo, 'u1', UserRole.eventPlanner);
    cubit.load();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.close();
  });
}
