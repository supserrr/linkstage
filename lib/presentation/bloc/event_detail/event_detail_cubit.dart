import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/planner_profile_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'event_detail_state.dart';

/// Cubit for event detail page.
class EventDetailCubit extends Cubit<EventDetailState> {
  EventDetailCubit(
    this._eventRepository,
    this._bookingRepository,
    this._userRepository,
    this._plannerProfileRepository,
    this._eventId,
    this._currentUserId,
    this._isCreative,
  ) : super(const EventDetailState()) {
    load();
  }

  final EventRepository _eventRepository;
  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;
  final PlannerProfileRepository _plannerProfileRepository;
  final String _eventId;
  final String _currentUserId;
  final bool _isCreative;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final event = await _eventRepository.getEventById(_eventId);
      if (event == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Event not found',
        ));
        return;
      }

      final applicationCount =
          await _bookingRepository.getPendingBookingsCountByEventId(_eventId);
      final pendingBookings =
          await _bookingRepository.getPendingBookingsByEventId(_eventId);
      final applicantPhotoUrls =
          await _fetchApplicantPhotoUrls(pendingBookings);
      UserEntity? planner;
      try {
        planner = await _userRepository.getUser(event.plannerId);
      } catch (_) {
        planner = null;
      }

      final plannerProfile = await _plannerProfileRepository.getPlannerProfile(event.plannerId);

      bool hasApplied = false;
      bool hasAcceptedBooking = false;
      if (_isCreative) {
        hasApplied = await _bookingRepository.hasPendingBookingForEvent(
          _eventId,
          _currentUserId,
        );
        final acceptedForEvent =
            await _bookingRepository.getAcceptedBookingsByEventId(_eventId);
        hasAcceptedBooking = acceptedForEvent
            .any((b) => b.creativeId == _currentUserId);
      }

      emit(state.copyWith(
        event: event,
        planner: planner,
        plannerProfile: plannerProfile,
        applicationCount: applicationCount,
        applicantPhotoUrls: applicantPhotoUrls,
        hasApplied: hasApplied,
        hasAcceptedBooking: hasAcceptedBooking,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  Future<void> applyToCollaborate() async {
    final event = state.event;
    if (event == null || state.hasApplied || state.isApplying) return;

    emit(state.copyWith(isApplying: true, error: null));
    try {
      final booking = await _bookingRepository.createBooking(
        eventId: event.id,
        creativeId: _currentUserId,
        plannerId: event.plannerId,
      );
      final newCount =
          await _bookingRepository.getPendingBookingsCountByEventId(_eventId);
      final pendingBookings =
          await _bookingRepository.getPendingBookingsByEventId(_eventId);
      final applicantPhotoUrls =
          await _fetchApplicantPhotoUrls(pendingBookings);
      emit(state.copyWith(
        hasApplied: true,
        applicationCount: newCount,
        applicantPhotoUrls: applicantPhotoUrls,
        isApplying: false,
        error: null,
      ));

      final creative = await _userRepository.getUser(_currentUserId);
      final creativeName = _displayName(creative, _currentUserId);
      sl<PushNotificationService>().notifyUser(
        targetUserId: event.plannerId,
        title: 'New application for ${event.title}',
        body: '$creativeName applied',
        data: {
          'route': '/event/${event.id}/applicants',
          'bookingId': booking.id,
          'eventId': event.id,
          'type': 'booking_new_application',
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isApplying: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  Future<List<String?>> _fetchApplicantPhotoUrls(
    List<BookingEntity> pendingBookings,
  ) async {
    final urls = <String?>[];
    for (var i = 0; i < pendingBookings.length && i < 5; i++) {
      try {
        final user =
            await _userRepository.getUser(pendingBookings[i].creativeId);
        urls.add(user?.photoUrl);
      } catch (_) {
        urls.add(null);
      }
    }
    return urls;
  }

  String _displayName(UserEntity? user, String fallbackId) {
    if (user == null) return 'Someone';
    return user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : (user.username?.trim().isNotEmpty == true
            ? '@${user.username}'
            : user.email.split('@').firstOrNull ?? 'Someone');
  }
}
