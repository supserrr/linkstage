import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/collaboration_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'planner_collaborations_tab_state.dart';

class PlannerCollaborationsTabCubit
    extends Cubit<PlannerCollaborationsTabState> {
  PlannerCollaborationsTabCubit(
    this._collaborationRepository,
    this._userRepository,
  ) : super(const PlannerCollaborationsTabState());

  final CollaborationRepository _collaborationRepository;
  final UserRepository _userRepository;

  Future<void> load(String plannerId) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final list = await _collaborationRepository
          .getCollaborationsByRequesterId(plannerId);
      final targetIds = list.map((c) => c.targetUserId).toSet().toList();
      final usersMap = targetIds.isEmpty
          ? <String, UserEntity>{}
          : await _userRepository.getUsersByIds(targetIds);
      final names = <String, String>{};
      final photoUrls = <String, String?>{};
      for (final id in targetIds) {
        final u = usersMap[id];
        names[id] = u?.displayName ?? u?.email ?? 'Creative';
        photoUrls[id] = u?.photoUrl;
      }
      emit(
        PlannerCollaborationsTabState(
          collaborations: list,
          targetNames: names,
          targetPhotoUrls: photoUrls,
          loading: false,
          error: null,
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
}
