import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/profile_entity.dart';
import 'profile_setup_state.dart';

const _keyPrefix = 'profile_setup_draft_';

/// Persists and restores profile setup draft for resume-on-return.
class ProfileSetupDraftStorage {
  ProfileSetupDraftStorage(this._prefs);

  final SharedPreferences _prefs;

  String _key(String userId) => '$_keyPrefix$userId';

  /// Saves draft state for the given user.
  Future<void> saveDraft(
    String userId,
    int currentStep,
    ProfileSetupState state,
  ) async {
    final map = <String, dynamic>{
      'currentStep': currentStep,
      'username': state.username,
      'photoUrl': state.photoUrl,
      'displayName': state.displayName,
      'bio': state.bio,
      'location': state.location,
      'category': _categoryToKey(state.category),
      'priceRange': state.priceRange,
    };
    await _prefs.setString(_key(userId), jsonEncode(map));
  }

  /// Loads draft for the given user. Returns null if none exists.
  ({int step, ProfileSetupState state})? loadDraft(String userId) {
    final jsonStr = _prefs.getString(_key(userId));
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final step = (map['currentStep'] as num?)?.toInt() ?? 0;
      final categoryKey = map['category'] as String?;
      final state = ProfileSetupState(
        username: map['username'] as String?,
        photoUrl: map['photoUrl'] as String?,
        displayName: map['displayName'] as String? ?? '',
        bio: map['bio'] as String? ?? '',
        location: map['location'] as String? ?? '',
        category: categoryKey != null && categoryKey.isNotEmpty
            ? _keyToCategory(categoryKey)
            : null,
        priceRange: map['priceRange'] as String? ?? '',
        isLoading: false,
      );
      return (step: step, state: state);
    } catch (_) {
      return null;
    }
  }

  /// Removes draft for the given user.
  Future<void> clearDraft(String userId) async {
    await _prefs.remove(_key(userId));
  }

  static String _categoryToKey(ProfileCategory? c) {
    if (c == null) return '';
    switch (c) {
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

  static ProfileCategory? _keyToCategory(String? key) {
    switch (key) {
      case 'dj':
        return ProfileCategory.dj;
      case 'photographer':
        return ProfileCategory.photographer;
      case 'decorator':
        return ProfileCategory.decorator;
      case 'content_creator':
        return ProfileCategory.contentCreator;
      default:
        return null;
    }
  }
}
