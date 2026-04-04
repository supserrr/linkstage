import 'profile_entity.dart';
import 'user_entity.dart';

/// Extension to get Firestore key for [UserRole].
extension UserRoleX on UserRole {
  String get roleKey {
    switch (this) {
      case UserRole.eventPlanner:
        return 'event_planner';
      case UserRole.creativeProfessional:
        return 'creative_professional';
    }
  }
}

/// Extension to get Firestore key for [ProfileCategory].
extension ProfileCategoryX on ProfileCategory {
  String get categoryKey {
    switch (this) {
      case ProfileCategory.dj:
        return 'dj';
      case ProfileCategory.photographer:
        return 'photographer';
      case ProfileCategory.decorator:
        return 'decorator';
      case ProfileCategory.contentCreator:
        return 'content_creator';
    }
  }
}
