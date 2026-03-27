import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../domain/entities/event_entity.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/event_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'create_event_state.dart';

/// Cubit for create/edit event form.
class CreateEventCubit extends Cubit<CreateEventState> {
  CreateEventCubit(
    this._eventRepository,
    this._bookingRepository,
    this._plannerId, {
    EventEntity? initialEvent,
    this.invitedCreativeId = '',
  })  : _editingEvent = initialEvent,
        super(initialEvent != null ? _stateFromEvent(initialEvent) : const CreateEventState());

  static CreateEventState _stateFromEvent(EventEntity e) {
    return CreateEventState(
      title: e.title,
      date: e.date,
      location: e.location,
      description: e.description,
      imageUrls: e.imageUrls,
      status: e.status,
      eventType: e.eventType,
      budget: e.budget,
      startTime: e.startTime,
      endTime: e.endTime,
      venueName: e.venueName,
      locationVisibility: e.locationVisibility,
    );
  }

  final EventRepository _eventRepository;
  final BookingRepository _bookingRepository;
  final String _plannerId;
  final EventEntity? _editingEvent;
  final String invitedCreativeId;

  void setTitle(String value) => emit(state.copyWith(title: value, error: null));

  void setDate(DateTime? value) => emit(state.copyWith(date: value, error: null));

  void setLocation(String value) =>
      emit(state.copyWith(location: value, error: null));

  /// Set location from place picker result (address + coordinates).
  void setLocationFromPlace({
    required String address,
    required double lat,
    required double lng,
  }) =>
      emit(state.copyWith(
        location: address,
        locationLat: lat,
        locationLng: lng,
        error: null,
      ));

  void setDescription(String value) =>
      emit(state.copyWith(description: value, error: null));

  void addImageUrl(String url) =>
      emit(state.copyWith(
        imageUrls: [...state.imageUrls, url],
        isUploadingImage: false,
        error: null,
      ));

  void removeImageUrl(String url) =>
      emit(state.copyWith(
        imageUrls: state.imageUrls.where((u) => u != url).toList(),
        error: null,
      ));

  void setUploadingImage(bool value) =>
      emit(state.copyWith(isUploadingImage: value, error: null));

  void setImageError(String message) =>
      emit(state.copyWith(isUploadingImage: false, error: message));

  void setStatus(EventStatus value) =>
      emit(state.copyWith(status: value, error: null));

  void setEventType(String value) =>
      emit(state.copyWith(eventType: value, error: null));

  void setBudget(double? value) =>
      emit(state.copyWith(budget: value, error: null));

  void setStartTime(String value) =>
      emit(state.copyWith(startTime: value, error: null));

  void setEndTime(String value) =>
      emit(state.copyWith(endTime: value, error: null));

  void setVenueName(String value) =>
      emit(state.copyWith(venueName: value, error: null));

  void setLocationVisibility(LocationVisibility value) =>
      emit(state.copyWith(locationVisibility: value, error: null));

  /// Returns the created event ID on create, null on edit, or null on failure.
  Future<String?> save() async {
    final title = state.title.trim();
    if (title.isEmpty) {
      emit(state.copyWith(error: 'Title is required'));
      return null;
    }

    emit(state.copyWith(isSaving: true, error: null));
    try {
      if (_editingEvent != null) {
        final updated = EventEntity(
          id: _editingEvent.id,
          plannerId: _plannerId,
          title: title,
          date: state.date,
          location: state.location.trim(),
          description: state.description.trim(),
          status: state.status,
          imageUrls: state.imageUrls,
          eventType: state.eventType.trim(),
          budget: state.budget,
          startTime: state.startTime.trim(),
          endTime: state.endTime.trim(),
          venueName: state.venueName.trim(),
          showOnProfile: _editingEvent.showOnProfile,
          locationVisibility: state.locationVisibility,
        );
        await _eventRepository.updateEvent(updated);
        if (state.status == EventStatus.open &&
            _editingEvent.status != EventStatus.open) {
          final planner = await sl<UserRepository>().getUser(_plannerId);
          final plannerName =
              planner?.displayName ?? planner?.username ?? planner?.email ?? 'Someone';
          sl<PushNotificationService>().notifyFollowersOfPlannerEvent(
            eventId: _editingEvent.id,
            plannerId: _plannerId,
            eventTitle: title,
            plannerName: plannerName,
          );
        }
        emit(state.copyWith(isSaving: false));
        return null; // Edit: caller can navigate to events list
      } else {
        final event = await _eventRepository.createEvent(
          plannerId: _plannerId,
          title: title,
          date: state.date,
          location: state.location.trim(),
          description: state.description.trim(),
          status: state.status,
          imageUrls: state.imageUrls,
          eventType: state.eventType.trim(),
          budget: state.budget,
          startTime: state.startTime.trim(),
          endTime: state.endTime.trim(),
          venueName: state.venueName.trim(),
          locationVisibility: state.locationVisibility,
        );
        if (state.status == EventStatus.open) {
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
        if (invitedCreativeId.isNotEmpty) {
          await _bookingRepository.createInvitation(
            eventId: event.id,
            creativeId: invitedCreativeId,
            plannerId: _plannerId,
          );
          final planner = await sl<UserRepository>().getUser(_plannerId);
          final plannerName =
              planner?.displayName ?? planner?.username ?? planner?.email ?? 'Someone';
          sl<PushNotificationService>().notifyUser(
            targetUserId: invitedCreativeId,
            title: 'Invitation to ${event.title}',
            body: '$plannerName invited you',
            data: {
              'route': '/bookings',
              'eventId': event.id,
              'type': 'booking_invitation',
            },
          );
        }
        emit(state.copyWith(isSaving: false));
        return event.id; // Create: return new event ID for navigation
      }
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      ));
      return null;
    }
  }
}
