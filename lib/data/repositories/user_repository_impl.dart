import '../../domain/entities/collaboration_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/collaboration_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

/// Implementation of [UserRepository] using Firestore.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(
    this._remote,
    this._bookingRepository,
    this._collaborationRepository,
  );

  final UserRemoteDataSource _remote;
  final BookingRepository _bookingRepository;
  final CollaborationRepository _collaborationRepository;

  @override
  Future<bool> hasWorkedWith(String userId1, String userId2) async {
    if (userId1.isEmpty || userId2.isEmpty) return false;

    final completedByCreative1 = await _bookingRepository
        .getCompletedBookingsByCreativeId(userId1);
    if (completedByCreative1.any((b) => b.plannerId == userId2)) return true;

    final completedByCreative2 = await _bookingRepository
        .getCompletedBookingsByCreativeId(userId2);
    if (completedByCreative2.any((b) => b.plannerId == userId1)) return true;

    final collabsTarget1 = await _collaborationRepository
        .getCollaborationsByTargetUserId(userId1, status: CollaborationStatus.completed);
    if (collabsTarget1.any((c) => c.requesterId == userId2)) return true;

    final collabsTarget2 = await _collaborationRepository
        .getCollaborationsByTargetUserId(userId2, status: CollaborationStatus.completed);
    if (collabsTarget2.any((c) => c.requesterId == userId1)) return true;

    final collabsRequester1 = await _collaborationRepository
        .getCollaborationsByRequesterId(userId1, status: CollaborationStatus.completed);
    if (collabsRequester1.any((c) => c.targetUserId == userId2)) return true;

    final collabsRequester2 = await _collaborationRepository
        .getCollaborationsByRequesterId(userId2, status: CollaborationStatus.completed);
    if (collabsRequester2.any((c) => c.targetUserId == userId1)) return true;

    return false;
  }

  @override
  Future<bool> canSendMessageTo(String senderId, String recipientId) async {
    if (senderId.isEmpty || recipientId.isEmpty) return false;
    if (senderId == recipientId) return true;
    final recipient = await _remote.getUser(recipientId);
    if (recipient == null) return true;
    final wcm = recipient.whoCanMessage ?? WhoCanMessage.everyone;
    if (wcm == WhoCanMessage.noOne) return false;
    if (wcm == WhoCanMessage.everyone) return true;
    if (wcm == WhoCanMessage.workedWith) {
      return hasWorkedWith(senderId, recipientId);
    }
    return true;
  }

  @override
  Future<void> updatePrivacySettings(
    String userId, {
    ProfileVisibility? profileVisibility,
    WhoCanMessage? whoCanMessage,
    bool? showOnlineStatus,
  }) =>
      _remote.updatePrivacySettings(
        userId,
        profileVisibility: profileVisibility,
        whoCanMessage: whoCanMessage,
        showOnlineStatus: showOnlineStatus,
      );

  @override
  Future<void> updateLastSeen(String userId) =>
      _remote.updateLastSeen(userId);

  @override
  Future<UserEntity?> getUser(String userId) => _remote.getUser(userId);

  @override
  Future<Map<String, UserEntity>> getUsersByIds(List<String> ids) =>
      _remote.getUsersByIds(ids);

  @override
  Future<void> upsertUser(UserEntity user) => _remote.upsertUser(user);

  @override
  Future<void> updateRole(String userId, UserRole role) =>
      _remote.updateRole(userId, role);

  @override
  Future<bool> checkUsernameAvailable(String username, {String? excludeUserId}) =>
      _remote.checkUsernameAvailable(username, excludeUserId: excludeUserId);

  @override
  Future<void> updateUsername(
    String userId,
    String newUsername,
    DateTime lastUsernameChangeAt,
  ) =>
      _remote.updateUsername(userId, newUsername, lastUsernameChangeAt);

  @override
  Future<void> changeUsernameAtomic(
    String userId,
    String newUsername,
    String? oldUsername,
    ProfileEntity newProfileData,
    DateTime lastUsernameChangeAt,
  ) =>
      _remote.changeUsernameAtomic(
        userId,
        newUsername,
        oldUsername,
        newProfileData,
        lastUsernameChangeAt,
      );

  @override
  Stream<UserEntity?> watchUser(String userId) => _remote.watchUser(userId);
}
