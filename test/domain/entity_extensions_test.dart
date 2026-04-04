import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/entity_extensions.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';

void main() {
  group('UserRoleX', () {
    test('roleKey maps planner and creative', () {
      expect(UserRole.eventPlanner.roleKey, 'event_planner');
      expect(UserRole.creativeProfessional.roleKey, 'creative_professional');
    });
  });

  group('ProfileCategoryX', () {
    test('categoryKey maps all categories', () {
      expect(ProfileCategory.dj.categoryKey, 'dj');
      expect(ProfileCategory.photographer.categoryKey, 'photographer');
      expect(ProfileCategory.decorator.categoryKey, 'decorator');
      expect(ProfileCategory.contentCreator.categoryKey, 'content_creator');
    });
  });
}
