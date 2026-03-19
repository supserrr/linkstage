import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/event_date_utils.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/creative_past_work_preferences_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'creative_past_work_state.dart';

/// Cubit for Creative Past Work page: loads completed bookings (past events)
/// and completed collaborations for a creative.
/// When [viewerUserId] != [profileUserId], filters by creative's visibility preferences.
class CreativePastWorkCubit extends Cubit<CreativePastWorkState> {
  CreativePastWorkCubit(
    this._bookingRepository,
    this._collaborationRepository,
    this._eventRepository,
    this._userRepository,
    this._profileRepository,
    this._preferencesRepository,
    this._profileUserId,
    this._viewerUserId,
  ) : super(const CreativePastWorkState()) {
    load();
  }

  final BookingRepository _bookingRepository;
  final CollaborationRepository _collaborationRepository;
  final EventRepository _eventRepository;
  final UserRepository _userRepository;
  final ProfileRepository _profileRepository;
  final CreativePastWorkPreferencesRepository _preferencesRepository;
  final String _profileUserId;
  final String _viewerUserId;

  bool get _isViewingOwn => _viewerUserId == _profileUserId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final profile = await _profileRepository.getProfileByUserId(
        _profileUserId,
      );
      final creativeName = profile?.displayName;
      final creativePhotoUrl = profile?.photoUrl;

      final completedBookings = await _bookingRepository
          .getCompletedBookingsByCreativeId(_profileUserId);
      final acceptedBookings = await _bookingRepository
          .getAcceptedBookingsByCreativeId(_profileUserId);

      // Past events: completed bookings + accepted bookings for past events
      // (creative may have worked but planner hasn't marked gig completed yet)
      final pastEventBookings = <BookingEntity>[];
      final seenEventIds = <String>{};
      for (final b in completedBookings) {
        if (seenEventIds.add(b.eventId)) {
          pastEventBookings.add(b);
        }
      }
      for (final b in acceptedBookings) {
        if (seenEventIds.contains(b.eventId)) continue;
        final event = await _eventRepository.getEventById(b.eventId);
        if (event != null && EventDateUtils.isPastEvent(event)) {
          seenEventIds.add(b.eventId);
          pastEventBookings.add(b);
        }
      }

      final collaborationsAsTarget = await _collaborationRepository
          .getCollaborationsByTargetUserId(
            _profileUserId,
            status: CollaborationStatus.completed,
          );
      final collaborationsAsRequester = await _collaborationRepository
          .getCollaborationsByRequesterId(
            _profileUserId,
            status: CollaborationStatus.completed,
          );

      final hiddenIds = (await _preferencesRepository.getHiddenIds(
        _profileUserId,
      )).toSet();

      final plannerIds = <String>{};
      for (final b in pastEventBookings) {
        plannerIds.add(b.plannerId);
      }
      for (final c in collaborationsAsTarget) {
        plannerIds.add(c.requesterId);
      }
      for (final c in collaborationsAsRequester) {
        plannerIds.add(c.targetUserId);
      }

      final userMap = <String, String?>{};
      final photoMap = <String, String?>{};
      for (final id in plannerIds) {
        final user = await _userRepository.getUser(id);
        userMap[id] = user?.displayName ?? 'Unknown';
        photoMap[id] = user?.photoUrl;
      }

      final pastEvents = <PastEventItem>[];
      for (final b in pastEventBookings) {
        if (!_isViewingOwn && hiddenIds.contains(b.id)) continue;
        final event = await _eventRepository.getEventById(b.eventId);
        if (event != null) {
          pastEvents.add(
            PastEventItem(
              bookingId: b.id,
              event: event,
              plannerName: userMap[b.plannerId] ?? 'Unknown',
              plannerPhotoUrl: photoMap[b.plannerId],
            ),
          );
        }
      }
      pastEvents.sort((a, b) {
        final da = a.event.date ?? DateTime(1970);
        final db = b.event.date ?? DateTime(1970);
        return db.compareTo(da);
      });

      final pastCollaborations = <PastCollaborationItem>[];
      final seenCollabIds = <String>{};
      for (final c in collaborationsAsTarget) {
        if (!_isViewingOwn && hiddenIds.contains(c.id)) continue;
        if (seenCollabIds.add(c.id)) {
          EventEntity? event;
          if (c.eventId != null) {
            event = await _eventRepository.getEventById(c.eventId!);
          }
          pastCollaborations.add(
            PastCollaborationItem(
              collaboration: c,
              event: event,
              plannerId: c.requesterId,
              plannerName: userMap[c.requesterId] ?? 'Unknown',
              plannerPhotoUrl: photoMap[c.requesterId],
            ),
          );
        }
      }
      for (final c in collaborationsAsRequester) {
        if (!_isViewingOwn && hiddenIds.contains(c.id)) continue;
        if (seenCollabIds.add(c.id)) {
          EventEntity? event;
          if (c.eventId != null) {
            event = await _eventRepository.getEventById(c.eventId!);
          }
          pastCollaborations.add(
            PastCollaborationItem(
              collaboration: c,
              event: event,
              plannerId: c.targetUserId,
              plannerName: userMap[c.targetUserId] ?? 'Unknown',
              plannerPhotoUrl: photoMap[c.targetUserId],
            ),
          );
        }
      }
      pastCollaborations.sort((a, b) {
        final da = a.collaboration.createdAt ?? DateTime(1970);
        final db = b.collaboration.createdAt ?? DateTime(1970);
        return db.compareTo(da);
      });

      emit(
        state.copyWith(
          creativeName: creativeName,
          creativePhotoUrl: creativePhotoUrl,
          pastEvents: pastEvents,
          pastCollaborations: pastCollaborations,
          hiddenIds: hiddenIds,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Toggle visibility for an item (creative config). Only when viewing own.
  Future<void> setItemVisibility(String itemId, bool show) async {
    if (!_isViewingOwn) return;
    try {
      await _preferencesRepository.setItemVisibility(
        _profileUserId,
        itemId,
        show,
      );
      final updated = Set<String>.from(state.hiddenIds);
      if (show) {
        updated.remove(itemId);
      } else {
        updated.add(itemId);
      }
      emit(state.copyWith(hiddenIds: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
