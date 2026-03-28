import '../../../domain/entities/collaboration_entity.dart';
import '../../../domain/entities/event_entity.dart';

/// Item for past event (from completed booking).
class PastEventItem {
  const PastEventItem({
    required this.bookingId,
    required this.event,
    required this.plannerName,
    this.plannerPhotoUrl,
  });

  /// Booking ID; used for visibility preference.
  final String bookingId;
  final EventEntity event;
  final String plannerName;
  final String? plannerPhotoUrl;
}

/// Item for past collaboration.
class PastCollaborationItem {
  const PastCollaborationItem({
    required this.collaboration,
    this.event,
    required this.plannerId,
    required this.plannerName,
    this.plannerPhotoUrl,
  });

  final CollaborationEntity collaboration;
  final EventEntity? event;
  final String plannerId;
  final String plannerName;
  final String? plannerPhotoUrl;
}

/// State for Creative Past Work page.
class CreativePastWorkState {
  const CreativePastWorkState({
    this.creativeName,
    this.creativePhotoUrl,
    this.pastEvents = const [],
    this.pastCollaborations = const [],
    this.hiddenIds = const {},
    this.isLoading = false,
    this.error,
  });

  final String? creativeName;
  final String? creativePhotoUrl;
  final List<PastEventItem> pastEvents;
  final List<PastCollaborationItem> pastCollaborations;
  /// IDs (booking or collaboration) hidden from public view.
  final Set<String> hiddenIds;
  final bool isLoading;
  final String? error;

  CreativePastWorkState copyWith({
    String? creativeName,
    String? creativePhotoUrl,
    List<PastEventItem>? pastEvents,
    List<PastCollaborationItem>? pastCollaborations,
    Set<String>? hiddenIds,
    bool? isLoading,
    String? error,
  }) {
    return CreativePastWorkState(
      creativeName: creativeName ?? this.creativeName,
      creativePhotoUrl: creativePhotoUrl ?? this.creativePhotoUrl,
      pastEvents: pastEvents ?? this.pastEvents,
      pastCollaborations: pastCollaborations ?? this.pastCollaborations,
      hiddenIds: hiddenIds ?? this.hiddenIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
