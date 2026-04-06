import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'event_applicants_state.dart';

class EventApplicantsCubit extends Cubit<EventApplicantsState> {
  EventApplicantsCubit(String eventId)
    : super(EventApplicantsState(eventId: eventId)) {
    load();
  }

  Future<void> load() async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearAccepting: true,
        clearRejecting: true,
        clearCompleting: true,
      ),
    );
    try {
      final event = await sl<EventRepository>().getEventById(state.eventId);
      if (event == null) {
        emit(state.copyWith(loading: false, error: 'Event not found'));
        return;
      }
      final invited = await sl<BookingRepository>().getInvitedBookingsByEventId(
        state.eventId,
      );
      final pending = await sl<BookingRepository>().getPendingBookingsByEventId(
        state.eventId,
      );
      final accepted = await sl<BookingRepository>()
          .getAcceptedBookingsByEventId(state.eventId);
      final completed = await sl<BookingRepository>()
          .getCompletedBookingsByEventId(state.eventId);
      final allBookings = [...invited, ...pending, ...accepted, ...completed];
      final users = <String, UserEntity>{};
      for (final b in allBookings) {
        final u = await sl<UserRepository>().getUser(b.creativeId);
        if (u != null) users[b.creativeId] = u;
      }
      final plannerId = sl<AuthRedirectNotifier>().user?.id ?? '';
      final hasReviewed = <String, bool>{};
      for (final b in completed) {
        final review = await sl<ReviewRepository>()
            .getReviewByBookingAndReviewer(b.id, plannerId);
        hasReviewed[b.id] = review != null;
      }
      emit(
        state.copyWith(
          event: event,
          applicants: allBookings,
          creativeUsers: users,
          hasReviewedByBookingId: hasReviewed,
          loading: false,
          clearError: true,
        ),
      );
      await _persistPlannerHomeActivityAck(allBookings, plannerId);
      plannerHomeActivityAckRevision.value++;
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString().replaceAll('Exception:', '').trim(),
        ),
      );
    }
  }

  void setAcceptingBookingId(String id) {
    emit(state.copyWith(acceptingBookingId: id));
  }

  void clearAcceptingBookingId() {
    emit(state.copyWith(clearAccepting: true));
  }

  void setRejectingBookingId(String id) {
    emit(state.copyWith(rejectingBookingId: id));
  }

  void clearRejectingBookingId() {
    emit(state.copyWith(clearRejecting: true));
  }

  void setCompletingBookingId(String id) {
    emit(state.copyWith(completingBookingId: id));
  }

  void clearCompletingBookingId() {
    emit(state.copyWith(clearCompleting: true));
  }

  void markReviewedForBooking(String bookingId) {
    final m = Map<String, bool>.from(state.hasReviewedByBookingId);
    m[bookingId] = true;
    emit(state.copyWith(hasReviewedByBookingId: m));
  }
}

/// Marks invitation outcome rows as seen for planner home (creative accepted or
/// declined an invite). Pending applications stay in recent activity until
/// declined or accepted regardless of viewing the applicants list.
Future<void> _persistPlannerHomeActivityAck(
  List<BookingEntity> allBookings,
  String plannerId,
) async {
  if (plannerId.isEmpty) return;
  final toAck = <String>{};
  for (final b in allBookings) {
    if (b.wasInvitation == true &&
        (b.status == BookingStatus.accepted ||
            b.status == BookingStatus.declined)) {
      toAck.add(b.id);
    }
  }
  if (toAck.isEmpty) return;
  final prefs = sl<SharedPreferences>();
  final key = AppConstants.plannerHomeActivityAckBookingsKey(plannerId);
  final existing = prefs.getStringList(key) ?? [];
  final merged = {...existing, ...toAck}.toList();
  const maxIds = 500;
  if (merged.length > maxIds) {
    merged.removeRange(0, merged.length - maxIds);
  }
  await prefs.setStringList(key, merged);
}
