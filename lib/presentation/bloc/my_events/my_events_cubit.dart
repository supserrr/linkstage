import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'my_events_state.dart';

/// Cubit for my events list (event planners).
/// Subscribes to Firestore streams for events and pending bookings.
class MyEventsCubit extends Cubit<MyEventsState> {
  MyEventsCubit(
    this._eventRepository,
    this._bookingRepository,
    this._collaborationRepository,
    this._plannerId,
  ) : super(const MyEventsState()) {
    _subscribe();
  }

  final EventRepository _eventRepository;
  final BookingRepository _bookingRepository;
  final CollaborationRepository _collaborationRepository;
  final String _plannerId;
  StreamSubscription<List<EventEntity>>? _eventsSubscription;
  StreamSubscription<List<BookingEntity>>? _bookingsSubscription;
  List<EventEntity> _latestEvents = [];
  List<BookingEntity> _latestBookings = [];

  void _subscribe() {
    _eventsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _latestEvents = [];
    _latestBookings = [];
    emit(state.copyWith(isLoading: true, error: null));

    _eventsSubscription = _eventRepository
        .getEventsByPlannerId(_plannerId)
        .listen(
          (events) {
            _latestEvents = events;
            _emitMerged();
          },
          onError: (e) => emit(state.copyWith(
            isLoading: false,
            error: e.toString().replaceAll('Exception:', '').trim(),
          )),
        );

    _bookingsSubscription = _bookingRepository
        .watchPendingBookingsByPlannerId(_plannerId)
        .listen(
          (bookings) {
            _latestBookings = bookings;
            _emitMerged();
          },
          onError: (e) => emit(state.copyWith(
            isLoading: false,
            error: e.toString().replaceAll('Exception:', '').trim(),
          )),
        );
  }

  void _emitMerged() {
    final pendingCountByEventId = <String, int>{};
    for (final b in _latestBookings) {
      pendingCountByEventId[b.eventId] =
          (pendingCountByEventId[b.eventId] ?? 0) + 1;
    }
    emit(state.copyWith(
      events: _latestEvents,
      pendingCountByEventId: pendingCountByEventId,
      isLoading: false,
      error: null,
    ));
  }

  /// Retry stream subscription on error.
  void load() {
    _subscribe();
  }

  /// Toggle publish state: draft <-> open. No-op for booked/completed.
  /// When marking event as completed, cascades to complete all accepted bookings.
  /// Stream will emit updated data automatically.
  Future<void> updateStatus(String eventId, EventStatus newStatus) async {
    try {
      if (newStatus == EventStatus.completed) {
        await _bookingRepository.completeAcceptedBookingsForEvent(eventId);
        await _collaborationRepository.completeAcceptedCollaborationsForEvent(eventId);
      }
      await _eventRepository.updateEventStatus(eventId, newStatus);
      if (newStatus == EventStatus.open) {
        EventEntity? event;
        for (final e in _latestEvents) {
          if (e.id == eventId) {
            event = e;
            break;
          }
        }
        if (event != null) {
          final planner = await sl<UserRepository>().getUser(_plannerId);
          final plannerName =
              planner?.displayName ?? planner?.username ?? planner?.email ?? 'Someone';
          sl<PushNotificationService>().notifyFollowersOfPlannerEvent(
            eventId: event.id,
            plannerId: _plannerId,
            eventTitle: event.title,
            plannerName: plannerName,
          );
        }
      }
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// Delete an event. Stream will emit updated data automatically.
  Future<void> delete(String eventId) async {
    try {
      await _eventRepository.deleteEvent(eventId);
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    return super.close();
  }
}
