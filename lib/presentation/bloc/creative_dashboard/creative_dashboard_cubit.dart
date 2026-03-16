import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/event_date_utils.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/followed_planners_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/saved_creatives_repository.dart';
import '../../../domain/services/event_recommendation.dart';
import 'creative_dashboard_state.dart';

/// Delay before showing loading UI. If Firestore cache responds first, we never show loading.
const Duration _deferredLoadingDelay = Duration(milliseconds: 150);
const String _savedEventIdsKey = 'creative_saved_event_ids';

/// Cubit for the creative home dashboard.
/// Loads profile, open events, and applicant counts per event.
class CreativeDashboardCubit extends Cubit<CreativeDashboardState> {
  CreativeDashboardCubit(
    this._profileRepository,
    this._eventRepository,
    this._bookingRepository,
    this._collaborationRepository,
    this._savedCreativesRepository,
    this._followedPlannersRepository,
    this._prefs,
    this._userId,
  ) : super(const CreativeDashboardState()) {
    load();
  }

  final ProfileRepository _profileRepository;
  final EventRepository _eventRepository;
  final BookingRepository _bookingRepository;
  final CollaborationRepository _collaborationRepository;
  final SavedCreativesRepository _savedCreativesRepository;
  final FollowedPlannersRepository _followedPlannersRepository;
  final SharedPreferences _prefs;
  final String _userId;

  void setFilter(CreativeHomeFilter filter) {
    emit(state.copyWith(homeFilter: filter));
  }

  Future<void> toggleSavedCreative(String creativeUserId) async {
    await _savedCreativesRepository.toggleSaved(_userId, creativeUserId);
    final savedIds = await _savedCreativesRepository
        .watchSavedCreativeIds(_userId)
        .first;
    final savedProfiles =
        await _savedCreativesRepository.getSavedProfiles(_userId);
    emit(state.copyWith(
      savedCreativeIds: savedIds,
      savedCreatives: savedProfiles,
    ));
  }

  void toggleSavedEvent(String eventId) {
    final current = Set<String>.from(state.savedEventIds);
    final wasRemoving = current.contains(eventId);
    if (wasRemoving) {
      current.remove(eventId);
    } else {
      current.add(eventId);
    }
    _persistSavedEventIds(current);
    final newSavedEvents = wasRemoving
        ? state.savedEvents.where((e) => e.id != eventId).toList()
        : state.savedEvents;
    emit(state.copyWith(savedEventIds: current, savedEvents: newSavedEvents));
  }

  Set<String> _loadSavedEventIds() {
    final list = _prefs.getStringList(_savedEventIdsKey);
    return list != null ? Set<String>.from(list) : <String>{};
  }

  Future<void> _migrateFollowedPlannersFromPrefs() async {
    final list =
        _prefs.getStringList(AppConstants.creativeFollowedPlannerIdsKey);
    if (list == null || list.isEmpty) return;
    for (final plannerId in list) {
      if (plannerId.isNotEmpty) {
        await _followedPlannersRepository.addFollow(_userId, plannerId);
      }
    }
    await _prefs.remove(AppConstants.creativeFollowedPlannerIdsKey);
  }

  Future<void> _persistSavedEventIds(Set<String> ids) async {
    await _prefs.setStringList(_savedEventIdsKey, ids.toList());
  }

  Timer? _loadingDeferTimer;
  int _loadId = 0;

  Future<void> load() async {
    _loadingDeferTimer?.cancel();
    final loadId = ++_loadId;
    try {
      await _migrateFollowedPlannersFromPrefs();

      final savedEventIds = _loadSavedEventIds();

      // Phase 1: Parallel fetch of all independent data.
      final profileFuture = _profileRepository.getProfileByUserId(_userId);
      final openEventsFuture =
          _eventRepository.fetchOpenEvents(limit: 20);
      final followedPlannerIdsFuture =
          _followedPlannersRepository.watchFollowedPlannerIds(_userId).first;
      final pendingBookingsFuture =
          _bookingRepository.getPendingBookingsByCreativeId(_userId);
      final acceptedBookingsFuture =
          _bookingRepository.getAcceptedBookingsByCreativeId(_userId);
      final invitedBookingsFuture =
          _bookingRepository.getInvitedBookingsByCreativeId(_userId);
      final pendingCollaborationsFuture =
          _collaborationRepository.getCollaborationsByTargetUserId(
        _userId,
        status: CollaborationStatus.pending,
      );
      final completedBookingsFuture =
          _bookingRepository.getCompletedBookingsByCreativeId(_userId);
      final savedCreativeIdsFuture =
          _savedCreativesRepository.watchSavedCreativeIds(_userId).first;
      final savedCreativesFuture =
          _savedCreativesRepository.getSavedProfiles(_userId);
      final fellowCreativesFuture = _profileRepository
          .getProfiles(
            limit: 20,
            excludeUserId: _userId,
            onlyCreativeAccounts: true,
          )
          .first
          .then(
            (all) =>
                all.where((p) => p.userId != _userId).take(20).toList(),
          )
          .catchError((_) => <ProfileEntity>[]);

      _loadingDeferTimer = Timer(_deferredLoadingDelay, () {
        if (loadId == _loadId && !isClosed) {
          _loadingDeferTimer = null;
          emit(state.copyWith(isLoading: true, error: null));
        }
      });

      final results = await Future.wait([
        profileFuture,
        openEventsFuture,
        pendingBookingsFuture,
        acceptedBookingsFuture,
        invitedBookingsFuture,
        pendingCollaborationsFuture,
        completedBookingsFuture,
        savedCreativeIdsFuture,
        savedCreativesFuture,
        fellowCreativesFuture,
        followedPlannerIdsFuture,
      ]);

      final profile = results[0] as ProfileEntity?;
      final openEvents = (results[1] as List<EventEntity>)
          .where(EventDateUtils.isUpcomingEvent)
          .toList();
      final pendingBookings = results[2] as List<BookingEntity>;
      final acceptedBookings = results[3] as List<BookingEntity>;
      final invitedBookings = results[4] as List<BookingEntity>;
      final pendingCollaborations =
          results[5] as List<CollaborationEntity>;
      final completedBookings = results[6] as List<BookingEntity>;
      final savedCreativeIds = results[7] as Set<String>;
      final savedCreatives = results[8] as List<ProfileEntity>;
      final fellowCreatives = results[9] as List<ProfileEntity>;
      final followedPlannerIds = results[10] as Set<String>;
      final acceptedEventIds =
          acceptedBookings.map((b) => b.eventId).toSet();

      // Phase 2: Batch fetch pending counts and saved events (depends on phase 1).
      final openEventIds = openEvents.map((e) => e.id).toSet();
      final idsForCounts = openEvents.map((e) => e.id).toList();
      final idsForSavedEvents = savedEventIds
          .where((id) => !openEventIds.contains(id))
          .toList();

      final countsFuture =
          idsForCounts.isEmpty
              ? Future<Map<String, int>>.value({})
              : _bookingRepository.getPendingBookingsCountByEventIds(
                  idsForCounts,
                );
      final savedEventsExtraFuture =
          idsForSavedEvents.isEmpty
              ? Future<List<EventEntity>>.value([])
              : _eventRepository.getEventsByIds(idsForSavedEvents);

      final counts = await countsFuture;
      final savedEventsExtra = await savedEventsExtraFuture;

      final savedEvents = <EventEntity>[
        ...openEvents.where((e) => savedEventIds.contains(e.id)),
        ...savedEventsExtra,
      ];

      // Use applied event IDs from pending bookings (avoids N+1 hasPendingBookingForEvent).
      final appliedEventIds =
          pendingBookings.map((b) => b.eventId).toSet();
      final notApplied =
          openEvents.where((e) => !appliedEventIds.contains(e.id)).toList();
      notApplied.sort((a, b) {
        final aFromFollowed = followedPlannerIds.contains(a.plannerId);
        final bFromFollowed = followedPlannerIds.contains(b.plannerId);
        if (aFromFollowed != bFromFollowed) {
          return aFromFollowed ? -1 : 1;
        }
        final scoreA = scoreEventForCreative(a, profile);
        final scoreB = scoreEventForCreative(b, profile);
        if (scoreB != scoreA) return scoreB.compareTo(scoreA);
        final dateA = a.date ?? DateTime(0);
        final dateB = b.date ?? DateTime(0);
        return dateA.compareTo(dateB);
      });
      const topN = 10;
      final recommendedForYouEvents = notApplied.take(topN).toList();

      // Recent events: events from followed planners first, then newest first by date.
      final recentEventsOrdered = List<EventEntity>.from(openEvents)
        ..sort((a, b) {
          final aFromFollowed = followedPlannerIds.contains(a.plannerId);
          final bFromFollowed = followedPlannerIds.contains(b.plannerId);
          if (aFromFollowed != bFromFollowed) {
            return aFromFollowed ? -1 : 1;
          }
          final da = a.date ?? DateTime(0);
          final db = b.date ?? DateTime(0);
          return db.compareTo(da);
        });

      final notificationCount = pendingBookings.length +
          invitedBookings.length +
          pendingCollaborations.length;

      _loadingDeferTimer?.cancel();
      _loadingDeferTimer = null;
      emit(state.copyWith(
        profile: profile,
        notificationCount: notificationCount,
        openEvents: recentEventsOrdered,
        fellowCreatives: fellowCreatives,
        pendingCountByEventId: counts,
        savedEventIds: savedEventIds,
        savedEvents: savedEvents,
        savedCreativeIds: savedCreativeIds,
        savedCreatives: savedCreatives,
        recommendedForYouEvents: recommendedForYouEvents,
        applicationsCount: pendingBookings.length,
        gigsCount: completedBookings.length,
        followedPlannersCount: followedPlannerIds.length,
        acceptedEventIds: acceptedEventIds,
        isLoading: false,
      ));
    } catch (e, st) {
      _loadingDeferTimer?.cancel();
      _loadingDeferTimer = null;
      if (kDebugMode) {
        debugPrint(
          '[CreativeDashboard] load failed: $e\nStack: $st',
        );
      }
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }
}
