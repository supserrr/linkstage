import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit() : super(const BookingsState());

  Future<void> load() async {
    final user = sl<AuthRedirectNotifier>().user;
    if (user?.id == null || user?.role != UserRole.creativeProfessional) {
      emit(
        state.copyWith(loading: false, clearError: true, clearConfirming: true),
      );
      return;
    }
    emit(
      state.copyWith(loading: true, clearError: true, clearConfirming: true),
    );
    try {
      final collaborations = await sl<CollaborationRepository>()
          .getCollaborationsByTargetUserId(user!.id);
      final invited = await sl<BookingRepository>()
          .getInvitedBookingsByCreativeId(user.id);
      final pending = await sl<BookingRepository>()
          .getPendingBookingsByCreativeId(user.id);
      final accepted = await sl<BookingRepository>()
          .getAcceptedBookingsByCreativeId(user.id);
      final completed = await sl<BookingRepository>()
          .getCompletedBookingsByCreativeId(user.id);
      final eventRepo = sl<EventRepository>();
      final eventIds = {
        ...invited.map((b) => b.eventId),
        ...pending.map((b) => b.eventId),
        ...accepted.map((b) => b.eventId),
        ...completed.map((b) => b.eventId),
      };
      final events = <String, EventEntity?>{};
      for (final id in eventIds) {
        events[id] = await eventRepo.getEventById(id);
      }
      final requesterIds = collaborations
          .map((c) => c.requesterId)
          .toSet()
          .toList();
      final requesterNames = <String, String>{};
      final requesterPhotoUrls = <String, String?>{};
      final requesterRoles = <String, UserRole?>{};
      for (final id in requesterIds) {
        final u = await sl<UserRepository>().getUser(id);
        requesterNames[id] = u?.displayName ?? u?.email ?? 'Someone';
        requesterPhotoUrls[id] = u?.photoUrl;
        requesterRoles[id] = u?.role;
      }
      final filtered = collaborations
          .where((c) => c.status != CollaborationStatus.declined)
          .toList();
      final sorted = List<CollaborationEntity>.from(filtered)
        ..sort((a, b) {
          final order = {
            CollaborationStatus.pending: 0,
            CollaborationStatus.accepted: 1,
            CollaborationStatus.completed: 2,
          };
          final diff = (order[a.status] ?? 2) - (order[b.status] ?? 2);
          if (diff != 0) return diff;
          final da = a.createdAt ?? DateTime(0);
          final db = b.createdAt ?? DateTime(0);
          return db.compareTo(da);
        });
      emit(
        BookingsState(
          invited: invited,
          applications: pending,
          accepted: accepted,
          completed: completed,
          collaborations: sorted,
          events: events,
          requesterNames: requesterNames,
          requesterPhotoUrls: requesterPhotoUrls,
          requesterRoles: requesterRoles,
          loading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void setConfirmingBookingId(String id) {
    emit(state.copyWith(confirmingBookingId: id));
  }

  void clearConfirmingBookingId() {
    emit(state.copyWith(clearConfirming: true));
  }
}
