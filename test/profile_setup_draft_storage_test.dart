import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_draft_storage.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('saveDraft loadDraft clearDraft round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = ProfileSetupDraftStorage(prefs);

    final state = ProfileSetupState(
      username: 'u',
      displayName: 'D',
      bio: 'B',
      location: 'L',
      category: ProfileCategory.dj,
      priceRange: r'$$',
    );
    await storage.saveDraft('user-1', 2, state);

    final loaded = storage.loadDraft('user-1');
    expect(loaded?.step, 2);
    expect(loaded?.state.username, 'u');
    expect(loaded?.state.category, ProfileCategory.dj);

    await storage.clearDraft('user-1');
    expect(storage.loadDraft('user-1'), isNull);
  });

  test('loadDraft returns null on bad json', () async {
    SharedPreferences.setMockInitialValues({
      'profile_setup_draft_bad': '{not json',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = ProfileSetupDraftStorage(prefs);
    expect(storage.loadDraft('bad'), isNull);
  });
}
