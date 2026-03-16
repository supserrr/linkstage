import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entity_extensions.dart';
import '../../domain/entities/user_entity.dart';

/// Firestore model for user document.
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.photoUrl,
    this.role,
    this.createdAt,
    this.lastUsernameChangeAt,
    this.profileVisibility,
    this.whoCanMessage,
    this.showOnlineStatus = true,
    this.lastSeen,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final ts = data['lastUsernameChangeAt'] as Timestamp?;
    final lastSeenTs = data['lastSeen'] as Timestamp?;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: UserEntity.roleFromKey(data['role'] as String?),
      createdAt: data['createdAt'] as Timestamp?,
      lastUsernameChangeAt: ts,
      profileVisibility:
          UserEntity.profileVisibilityFromKey(data['profileVisibility'] as String?),
      whoCanMessage:
          UserEntity.whoCanMessageFromKey(data['whoCanMessage'] as String?),
      showOnlineStatus: data['showOnlineStatus'] as bool? ?? true,
      lastSeen: lastSeenTs,
    );
  }

  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final UserRole? role;
  final Timestamp? createdAt;
  final Timestamp? lastUsernameChangeAt;
  final ProfileVisibility? profileVisibility;
  final WhoCanMessage? whoCanMessage;
  final bool showOnlineStatus;
  final Timestamp? lastSeen;

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role?.roleKey,
      'lastUsernameChangeAt': lastUsernameChangeAt,
      'profileVisibility':
          profileVisibility != null
              ? UserEntity.profileVisibilityToKey(profileVisibility!)
              : null,
      'whoCanMessage':
          whoCanMessage != null
              ? UserEntity.whoCanMessageToKey(whoCanMessage!)
              : null,
      'showOnlineStatus': showOnlineStatus,
      'lastSeen': lastSeen,
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      emailVerified: true,
      username: username,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      lastUsernameChangeAt: lastUsernameChangeAt?.toDate(),
      profileVisibility: profileVisibility,
      whoCanMessage: whoCanMessage,
      showOnlineStatus: showOnlineStatus,
      lastSeen: lastSeen?.toDate(),
    );
  }
}
