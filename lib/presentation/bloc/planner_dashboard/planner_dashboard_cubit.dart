import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/event_date_utils.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'planner_dashboard_state.dart';

/// Delay before showing loading UI. If Firestore cache responds first, we never show loading.
const Duration _deferredLoadingDelay = Duration(milliseconds: 150);

/// Cubit for the event planner home dashboard.
/// Subscribes to Firestore streams for events and booking activity.
class PlannerDashboardCubit extends Cubit<PlannerDashboardState> {
  PlannerDashboardCubit(
    this._eventRepository,
    this._bookingRepository,
    this._userRepository,
    this._prefs,
    this._plannerId,
  ) : super(const PlannerDashboardState()) {
    _subscribe();
  }

  final EventRepository _eventRepository;
  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;
  final SharedPreferences _prefs;
  final String _plannerId;

  StreamSubscription<List<EventEntity>>? _eventsSubscription;
  StreamSubscription<List<BookingEntity>>? _bookingsSubscription;
  StreamSubscription<List<BookingEntity>>? _acceptedInvitesSubscription;
  StreamSubscription<List<BookingEntity>>? _declinedInvitesSubscription;
  StreamSubscription<List<BookingEntity>>? _acceptedApplicationsSubscription;
  Timer? _loadingDeferTimer;
  int _subscribeId = 0;
  List<EventEntity> _latestEvents = [];
  List<BookingEntity> _latestPending = [];
  List<BookingEntity> _latestAcceptedInvites = [];
  List<BookingEntity> _latestDeclinedInvites = [];
  List<BookingEntity> _latestAcceptedApplications = [];
  int _emitSequence = 0;
  bool _hasEmittedData = false;

  static const int _recentActivityLimit = 10;

  Set<String> _acknowledgedBookingIds() {
    final key = AppConstants.plannerHomeActivityAckBookingsKey(_plannerId);
    final list = _prefs.getStringList(key);
    if (list == null || list.isEmpty) return {};
    return Set<String>.from(list);
  }

  static DateTime _sortTimeForActivity(
    BookingEntity b,
    PlannerHomeActivityKind kind,
  ) {
    switch (kind) {
      case PlannerHomeActivityKind.invitationAccepted:
      case PlannerHomeActivityKind.applicationAccepted:
        return b.creativeConfirmedAt ??
            b.plannerConfirmedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
      case PlannerHomeActivityKind.creativeApplication:
      case PlannerHomeActivityKind.invitationDeclined:
        return b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  void _subscribe() {
    _eventsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _acceptedInvitesSubscription?.cancel();
    _declinedInvitesSubscription?.cancel();
    _acceptedApplicationsSubscription?.cancel();
    _loadingDeferTimer?.cancel();
    _hasEmittedData = false;
    _latestEvents = [];
    _latestPending = [];
    _latestAcceptedInvites = [];
    _latestDeclinedInvites = [];
    _latestAcceptedApplications = [];
    final subscribeId = ++_subscribeId;

    _loadingDeferTimer = Timer(_deferredLoadingDelay, () {
      if (subscribeId == _subscribeId && !_hasEmittedData && !isClosed) {
        _loadingDeferTimer = null;
        emit(state.copyWith(isLoading: true, error: null));
      }
    });

    _eventsSubscription = _eventRepository
        .getEventsByPlannerId(_plannerId)
        .listen(
          (events) {
            _latestEvents = events;
            _rebuildAndEmit();
          },
          onError: (e) {
            _loadingDeferTimer?.cancel();
            _loadingDeferTimer = null;
            emit(
              state.copyWith(
                isLoading: false,
                error: e.toString().replaceAll('Exception:', '').trim(),
              ),
            );
          },
        );

    _bookingsSubscription = _bookingRepository
        .watchPendingBookingsByPlannerId(_plannerId)
        .listen(
          (bookings) {
            _latestPending = bookings;
            _rebuildAndEmit();
          },
          onError: (e) {
            _loadingDeferTimer?.cancel();
            _loadingDeferTimer = null;
            emit(
              state.copyWith(
                isLoading: false,
                error: e.toString().replaceAll('Exception:', '').trim(),
              ),
            );
          },
        );

    _acceptedInvitesSubscription = _bookingRepository
        .watchAcceptedInvitationBookingsByPlannerId(_plannerId)
        .listen(
          (bookings) {
            _latestAcceptedInvites = bookings;
            _rebuildAndEmit();
          },
          onError: (e) {
            _loadingDeferTimer?.cancel();
            _loadingDeferTimer = null;
            emit(
              state.copyWith(
                isLoading: false,
                error: e.toString().replaceAll('Exception:', '').trim(),
              ),
            );
          },
        );

    _declinedInvitesSubscription = _bookingRepository
        .watchDeclinedInvitationBookingsByPlannerId(_plannerId)
        .listen(
          (bookings) {
            _latestDeclinedInvites = bookings;
            _rebuildAndEmit();
          },
          onError: (e) {
            _loadingDeferTimer?.cancel();
            _loadingDeferTimer = null;
            emit(
              state.copyWith(
                isLoading: false,
                error: e.toString().replaceAll('Exception:', '').trim(),
              ),
            );
          },
        );

    _acceptedApplicationsSubscription = _bookingRepository
        .watchAcceptedApplicationBookingsByPlannerId(_plannerId)
        .listen(
          (bookings) {
            _latestAcceptedApplications = bookings;
            _rebuildAndEmit();
          },
          onError: (e) {
            _loadingDeferTimer?.cancel();
            _loadingDeferTimer = null;
            emit(
              state.copyWith(
                isLoading: false,
                error: e.toString().replaceAll('Exception:', '').trim(),
              ),
            );
          },
        );
  }

  Future<void> _rebuildAndEmit() async {
    final seq = ++_emitSequence;
    final events = List<EventEntity>.from(_latestEvents);
    final pendingBookings = List<BookingEntity>.from(_latestPending);
    final acceptedInvites = List<BookingEntity>.from(_latestAcceptedInvites);
    final declinedInvites = List<BookingEntity>.from(_latestDeclinedInvites);
    final acceptedApplications =
        List<BookingEntity>.from(_latestAcceptedApplications);

    final eventById = {for (final e in events) e.id: e};
    final pendingCountByEventId = <String, int>{};
    for (final b in pendingBookings) {
      pendingCountByEventId[b.eventId] =
          (pendingCountByEventId[b.eventId] ?? 0) + 1;
    }

    final upcomingEvents = events
        .where(EventDateUtils.isUpcomingEvent)
        .toList();

    final ackIds = _acknowledgedBookingIds();

    final candidates = <({
      BookingEntity b,
      PlannerHomeActivityKind kind,
      DateTime sortAt,
    })>[];

    for (final b in pendingBookings) {
      final event = eventById[b.eventId];
      if (event == null || EventDateUtils.isPastEvent(event)) continue;
      candidates.add((
        b: b,
        kind: PlannerHomeActivityKind.creativeApplication,
        sortAt: _sortTimeForActivity(b, PlannerHomeActivityKind.creativeApplication),
      ));
    }

    for (final b in acceptedInvites) {
      if (ackIds.contains(b.id)) continue;
      final event = eventById[b.eventId];
      if (event == null || EventDateUtils.isPastEvent(event)) continue;
      candidates.add((
        b: b,
        kind: PlannerHomeActivityKind.invitationAccepted,
        sortAt: _sortTimeForActivity(b, PlannerHomeActivityKind.invitationAccepted),
      ));
    }

    for (final b in declinedInvites) {
      if (ackIds.contains(b.id)) continue;
      final event = eventById[b.eventId];
      if (event == null || EventDateUtils.isPastEvent(event)) continue;
      candidates.add((
        b: b,
        kind: PlannerHomeActivityKind.invitationDeclined,
        sortAt: _sortTimeForActivity(b, PlannerHomeActivityKind.invitationDeclined),
      ));
    }

    for (final b in acceptedApplications) {
      final event = eventById[b.eventId];
      if (event == null || EventDateUtils.isPastEvent(event)) continue;
      candidates.add((
        b: b,
        kind: PlannerHomeActivityKind.applicationAccepted,
        sortAt: _sortTimeForActivity(
          b,
          PlannerHomeActivityKind.applicationAccepted,
        ),
      ));
    }

    candidates.sort((a, b) => b.sortAt.compareTo(a.sortAt));
    final top = candidates.take(_recentActivityLimit).toList();

    final creativeIds = top.map((c) => c.b.creativeId).toSet().toList();
    final usersMap = creativeIds.isEmpty
        ? <String, UserEntity>{}
        : await _userRepository.getUsersByIds(creativeIds);

    final recentActivities = <PlannerDashboardActivityItem>[];
    for (final c in top) {
      final b = c.b;
      final user = usersMap[b.creativeId];
      final creativeName =
          user?.displayName ??
          user?.username ??
          user?.email.split('@').firstOrNull ??
          'Someone';
      final event = eventById[b.eventId];
      final eventTitle = event?.title ?? 'Event';
      final createdAt = c.sortAt;
      recentActivities.add(
        PlannerDashboardActivityItem(
          kind: c.kind,
          eventId: b.eventId,
          creativeName: creativeName,
          eventTitle: eventTitle,
          createdAt: createdAt,
        ),
      );
    }

    if (seq != _emitSequence) return;
    _loadingDeferTimer?.cancel();
    _loadingDeferTimer = null;
    _hasEmittedData = true;
    emit(
      state.copyWith(
        events: upcomingEvents,
        applicantsCount: pendingBookings.length,
        eventsCount: upcomingEvents.length,
        unreadCount: 0,
        recentActivities: recentActivities,
        pendingCountByEventId: pendingCountByEventId,
        isLoading: false,
      ),
    );
  }

  /// Retry stream subscriptions on error.
  void load() {
    _subscribe();
  }

  /// Rebuild recent activity after acknowledgements were saved (e.g. viewed applicants).
  void refreshAfterAcknowledgements() {
    if (!isClosed) _rebuildAndEmit();
  }

  @override
  Future<void> close() {
    _loadingDeferTimer?.cancel();
    _eventsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _acceptedInvitesSubscription?.cancel();
    _declinedInvitesSubscription?.cancel();
    _acceptedApplicationsSubscription?.cancel();
    return super.close();
  }
}
