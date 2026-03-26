import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/planner_profile_entity.dart';
import 'package:linkstage/presentation/bloc/following/following_page_cubit.dart';

void main() {
  group('FollowingPageCubit', () {
    test('setLoading and setSuccess', () {
      final cubit = FollowingPageCubit();
      cubit.setLoading();
      expect(cubit.state.loading, isTrue);
      expect(cubit.state.error, isNull);

      cubit.setSuccess([
        const PlannerProfileEntity(userId: 'p1', displayName: 'A'),
      ]);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.planners, hasLength(1));
      expect(cubit.state.planners.single.userId, 'p1');
      cubit.close();
    });

    test('setError clears loading', () {
      final cubit = FollowingPageCubit();
      cubit.setLoading();
      cubit.setError('failed');
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.error, 'failed');
      cubit.close();
    });
  });
}
