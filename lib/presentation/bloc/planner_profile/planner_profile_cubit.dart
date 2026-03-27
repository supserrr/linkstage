import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/planner_profile_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/planner_profile_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'planner_profile_state.dart';

/// Cubit for planner profile edit flow.
class PlannerProfileCubit extends Cubit<PlannerProfileState> {
  PlannerProfileCubit(
    this._userRepository,
    this._eventRepository,
    this._bookingRepository,
    this._collaborationRepository,
    this._profileRepository,
    this._plannerProfileRepository,
    String plannerId, {
    String? viewingUserId,
  })  : _plannerId = plannerId,
        _viewingUserId = viewingUserId,
        super(const PlannerProfileState()) {
    load(plannerId);
  }

  final UserRepository _userRepository;
  final String _plannerId;
  final String? _viewingUserId;
  final EventRepository _eventRepository;
  final BookingRepository _bookingRepository;
  final CollaborationRepository _collaborationRepository;
  final ProfileRepository _profileRepository;
  final PlannerProfileRepository _plannerProfileRepository;

  Future<void> load(String plannerId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = await _userRepository.getUser(plannerId);
      final plannerProfile =
          await _plannerProfileRepository.getPlannerProfile(plannerId) ??
              PlannerProfileEntity(userId: plannerId);
      final events = await _eventRepository.fetchEventsByPlannerId(plannerId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pastEvents = events
          .where((e) =>
              e.status == EventStatus.completed ||
              (e.date != null && e.date!.isBefore(today)))
          .toList();
      final currentEvents = events
          .where((e) =>
              e.status != EventStatus.completed &&
              (e.date == null || !e.date!.isBefore(today)))
          .toList();
      // Only completed bookings and completed collaborations count as "worked with".
      final completedBookings = await _bookingRepository
          .getCompletedBookingsByPlannerId(plannerId);
      final collabsAsTarget = await _collaborationRepository
          .getCollaborationsByTargetUserId(plannerId,
              status: CollaborationStatus.completed);
      final collabsAsRequester = await _collaborationRepository
          .getCollaborationsByRequesterId(plannerId,
              status: CollaborationStatus.completed);
      final creativeIds = <String>{
        ...completedBookings.map((b) => b.creativeId),
        ...collabsAsTarget.map((c) => c.requesterId),
        ...collabsAsRequester.map((c) => c.targetUserId),
      }.toList();
      final creatives = <ProfileEntity>[];
      for (final id in creativeIds.take(10)) {
        final p = await _profileRepository.getProfileByUserId(id);
        if (p != null) creatives.add(p);
      }
      var acceptedEventIdsForViewer = <String>{};
      final viewerId = _viewingUserId;
      if (viewerId != null &&
          viewerId.isNotEmpty &&
          viewerId != plannerId) {
        final accepted =
            await _bookingRepository.getAcceptedBookingsByCreativeId(viewerId);
        acceptedEventIdsForViewer =
            accepted.map((b) => b.eventId).toSet();
      }
      emit(state.copyWith(
        user: user,
        plannerProfile: plannerProfile,
        events: events,
        currentEvents: currentEvents,
        pastEvents: pastEvents,
        recentCreatives: creatives,
        acceptedEventIdsForViewer: acceptedEventIdsForViewer,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  void setBio(String value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: value,
          location: p.location,
          eventTypes: p.eventTypes,
          languages: p.languages,
          portfolioUrls: p.portfolioUrls,
          displayName: p.displayName,
          role: p.role,
        ),
      ));
    }
  }

  void setDisplayName(String value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: p.bio,
          location: p.location,
          eventTypes: p.eventTypes,
          languages: p.languages,
          portfolioUrls: p.portfolioUrls,
          displayName: value.isEmpty ? null : value,
          role: p.role,
        ),
      ));
    }
  }

  void setLocation(String value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: p.bio,
          location: value,
          eventTypes: p.eventTypes,
          languages: p.languages,
          portfolioUrls: p.portfolioUrls,
          displayName: p.displayName,
          role: p.role,
        ),
      ));
    }
  }

  void setEventTypes(List<String> value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: p.bio,
          location: p.location,
          eventTypes: value,
          languages: p.languages,
          portfolioUrls: p.portfolioUrls,
          displayName: p.displayName,
          role: p.role,
        ),
      ));
    }
  }

  void setLanguages(List<String> value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: p.bio,
          location: p.location,
          eventTypes: p.eventTypes,
          languages: value,
          portfolioUrls: p.portfolioUrls,
          displayName: p.displayName,
          role: p.role,
        ),
      ));
    }
  }

  void setPortfolioUrls(List<String> value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: p.bio,
          location: p.location,
          eventTypes: p.eventTypes,
          languages: p.languages,
          portfolioUrls: value,
          displayName: p.displayName,
          role: p.role,
        ),
      ));
    }
  }

  void setRole(String? value) {
    final p = state.plannerProfile;
    if (p != null) {
      emit(state.copyWith(
        plannerProfile: PlannerProfileEntity(
          userId: p.userId,
          bio: p.bio,
          location: p.location,
          eventTypes: p.eventTypes,
          languages: p.languages,
          portfolioUrls: p.portfolioUrls,
          displayName: p.displayName,
          role: value?.trim().isEmpty == true ? null : value?.trim(),
        ),
      ));
    }
  }

  Future<void> save() async {
    final p = state.plannerProfile;
    if (p == null) return;
    final dn = p.displayName?.trim();
    final normalizedDisplay =
        (dn == null || dn.isEmpty) ? null : dn;
    final pSave = PlannerProfileEntity(
      userId: p.userId,
      bio: p.bio,
      location: p.location,
      eventTypes: p.eventTypes,
      languages: p.languages,
      portfolioUrls: p.portfolioUrls,
      displayName: normalizedDisplay,
      role: p.role,
      photoUrl: p.photoUrl,
      profileVisibility: p.profileVisibility,
    );
    emit(state.copyWith(isSaving: true, error: null));
    try {
      await _plannerProfileRepository.upsertPlannerProfile(pSave);
      final u = state.user;
      if (u != null) {
        await _userRepository.upsertUser(UserEntity(
          id: u.id,
          email: u.email,
          emailVerified: u.emailVerified,
          username: u.username,
          displayName: normalizedDisplay,
          photoUrl: u.photoUrl,
          role: u.role,
          lastUsernameChangeAt: u.lastUsernameChangeAt,
          profileVisibility: u.profileVisibility,
          whoCanMessage: u.whoCanMessage,
          showOnlineStatus: u.showOnlineStatus,
          lastSeen: u.lastSeen,
        ));
      }
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// Reload user and related data (e.g. after profile photo update).
  Future<void> refresh() => load(_plannerId);

  /// Toggle whether a past event is shown on the planner's public profile.
  Future<void> setEventShowOnProfile(EventEntity event, bool show) async {
    final updated = EventEntity(
      id: event.id,
      plannerId: event.plannerId,
      title: event.title,
      date: event.date,
      location: event.location,
      description: event.description,
      status: event.status,
      imageUrls: event.imageUrls,
      eventType: event.eventType,
      budget: event.budget,
      startTime: event.startTime,
      endTime: event.endTime,
      venueName: event.venueName,
      showOnProfile: show,
      locationVisibility: event.locationVisibility,
    );
    try {
      await _eventRepository.updateEvent(updated);
      await load(_plannerId);
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }
}
