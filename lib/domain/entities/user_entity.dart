import 'package:equatable/equatable.dart';

/// User role in the platform.
enum UserRole { eventPlanner, creativeProfessional }

/// Profile visibility option (Firestore: everyone | connections_only | only_me).
enum ProfileVisibility { everyone, connectionsOnly, onlyMe }

/// Who can message the user (Firestore: everyone | worked_with | no_one).
enum WhoCanMessage { everyone, workedWith, noOne }

/// Domain entity representing a user.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.emailVerified = false,
    this.username,
    this.displayName,
    this.photoUrl,
    this.role,
    this.lastUsernameChangeAt,
    this.profileVisibility,
    this.whoCanMessage,
    this.showOnlineStatus = true,
    this.lastSeen,
  });

  final String id;
  final String email;
  final bool emailVerified;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final UserRole? role;
  final DateTime? lastUsernameChangeAt;
  final ProfileVisibility? profileVisibility;
  final WhoCanMessage? whoCanMessage;
  final bool showOnlineStatus;
  final DateTime? lastSeen;

  String get roleKey {
    switch (role) {
      case UserRole.eventPlanner:
        return 'event_planner';
      case UserRole.creativeProfessional:
        return 'creative_professional';
      case null:
        return '';
    }
  }

  static UserRole? roleFromKey(String? key) {
    switch (key) {
      case 'event_planner':
        return UserRole.eventPlanner;
      case 'creative_professional':
        return UserRole.creativeProfessional;
      default:
        return null;
    }
  }

  static ProfileVisibility? profileVisibilityFromKey(String? key) {
    switch (key) {
      case 'everyone':
        return ProfileVisibility.everyone;
      case 'connections_only':
        return ProfileVisibility.connectionsOnly;
      case 'only_me':
        return ProfileVisibility.onlyMe;
      default:
        return null;
    }
  }

  static String profileVisibilityToKey(ProfileVisibility v) {
    switch (v) {
      case ProfileVisibility.everyone:
        return 'everyone';
      case ProfileVisibility.connectionsOnly:
        return 'connections_only';
      case ProfileVisibility.onlyMe:
        return 'only_me';
    }
  }

  static WhoCanMessage? whoCanMessageFromKey(String? key) {
    switch (key) {
      case 'everyone':
        return WhoCanMessage.everyone;
      case 'worked_with':
        return WhoCanMessage.workedWith;
      case 'no_one':
        return WhoCanMessage.noOne;
      default:
        return null;
    }
  }

  static String whoCanMessageToKey(WhoCanMessage v) {
    switch (v) {
      case WhoCanMessage.everyone:
        return 'everyone';
      case WhoCanMessage.workedWith:
        return 'worked_with';
      case WhoCanMessage.noOne:
        return 'no_one';
    }
  }

  @override
  List<Object?> get props => [
        id,
        email,
        emailVerified,
        username,
        displayName,
        photoUrl,
        role,
        lastUsernameChangeAt,
        profileVisibility,
        whoCanMessage,
        showOnlineStatus,
        lastSeen,
      ];
}
