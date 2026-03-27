import '../../../domain/entities/event_entity.dart';

/// State for my events list.
class MyEventsState {
  const MyEventsState({
    this.events = const [],
    this.pendingCountByEventId = const {},
    this.isLoading = false,
    this.error,
  });

  final List<EventEntity> events;
  final Map<String, int> pendingCountByEventId;
  final bool isLoading;
  final String? error;

  MyEventsState copyWith({
    List<EventEntity>? events,
    Map<String, int>? pendingCountByEventId,
    bool? isLoading,
    String? error,
  }) {
    return MyEventsState(
      events: events ?? this.events,
      pendingCountByEventId:
          pendingCountByEventId ?? this.pendingCountByEventId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
