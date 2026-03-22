import '../../../domain/entities/collaboration_entity.dart';

class PlannerCollaborationsTabState {
  const PlannerCollaborationsTabState({
    this.collaborations = const [],
    this.targetNames = const {},
    this.targetPhotoUrls = const {},
    this.loading = true,
    this.error,
  });

  final List<CollaborationEntity> collaborations;
  final Map<String, String> targetNames;
  final Map<String, String?> targetPhotoUrls;
  final bool loading;
  final String? error;

  PlannerCollaborationsTabState copyWith({
    List<CollaborationEntity>? collaborations,
    Map<String, String>? targetNames,
    Map<String, String?>? targetPhotoUrls,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PlannerCollaborationsTabState(
      collaborations: collaborations ?? this.collaborations,
      targetNames: targetNames ?? this.targetNames,
      targetPhotoUrls: targetPhotoUrls ?? this.targetPhotoUrls,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
