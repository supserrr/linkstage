import '../../entities/profile_entity.dart';
import '../../entities/user_entity.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/user_repository.dart';

/// Validates username: 3–20 chars, alphanumeric + underscore.
bool _isValidUsername(String s) {
  if (s.length < 3 || s.length > 20) return false;
  return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s);
}

/// Result of change username attempt.
sealed class ChangeUsernameResult {}

class ChangeUsernameSuccess extends ChangeUsernameResult {}

class ChangeUsernameCooldown extends ChangeUsernameResult {
  ChangeUsernameCooldown(this.nextChangeDate);
  final DateTime nextChangeDate;
}

class ChangeUsernameInvalid extends ChangeUsernameResult {
  ChangeUsernameInvalid(this.message);
  final String message;
}

class ChangeUsernameTaken extends ChangeUsernameResult {}

/// Use case: change username with 30-day cooldown and profile migration.
class ChangeUsernameUseCase {
  ChangeUsernameUseCase(this._userRepository, this._profileRepository);

  final UserRepository _userRepository;
  final ProfileRepository _profileRepository;

  static const int cooldownDays = 30;

  /// Returns null if valid and available.
  Future<String?> validate(String username, {String? excludeUserId}) async {
    if (!_isValidUsername(username)) {
      return 'Username must be 3–20 characters, letters, numbers, underscores only.';
    }
    final available = await _userRepository.checkUsernameAvailable(
      username,
      excludeUserId: excludeUserId,
    );
    return available ? null : 'This username is taken.';
  }

  Future<ChangeUsernameResult> call(UserEntity user, String newUsername) async {
    if (!_isValidUsername(newUsername)) {
      return ChangeUsernameInvalid(
        'Username must be 3–20 characters, letters, numbers, underscores only.',
      );
    }
    final now = DateTime.now();
    final lastChange = user.lastUsernameChangeAt;
    if (lastChange != null) {
      final nextAllowed = lastChange.add(const Duration(days: cooldownDays));
      if (now.isBefore(nextAllowed)) {
        return ChangeUsernameCooldown(nextAllowed);
      }
    }
    final normalized = newUsername.toLowerCase();
    final currentUsername = user.username;
    if (currentUsername != null && currentUsername.toLowerCase() == normalized) {
      return ChangeUsernameInvalid('This is already your username.');
    }

    final available = await _userRepository.checkUsernameAvailable(
      newUsername,
      excludeUserId: user.id,
    );
    if (!available) return ChangeUsernameTaken();

    final profile = await _profileRepository.getProfileByUserId(user.id);
    if (profile == null) {
      return ChangeUsernameInvalid('Profile not found.');
    }

    final newProfile = ProfileEntity(
      id: normalized,
      userId: user.id,
      username: normalized,
      bio: profile.bio,
      category: profile.category,
      priceRange: profile.priceRange,
      location: profile.location,
      portfolioUrls: profile.portfolioUrls,
      rating: profile.rating,
      reviewCount: profile.reviewCount,
      displayName: profile.displayName,
    );

    try {
      await _userRepository.changeUsernameAtomic(
        user.id,
        normalized,
        currentUsername,
        newProfile,
        now,
      );
    } on StateError {
      return ChangeUsernameTaken();
    }

    return ChangeUsernameSuccess();
  }
}
