import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkstage/data/repositories/saved_creatives_repository_impl.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('SavedCreativesRepositoryImpl', () {
    late MockProfileRepository profileRepository;
    late MockFirebaseFirestore firestore;
    late SavedCreativesRepositoryImpl repo;

    setUp(() {
      profileRepository = MockProfileRepository();
      firestore = MockFirebaseFirestore();
      repo = SavedCreativesRepositoryImpl(
        profileRepository,
        firestore: firestore,
      );
    });

    test('toggleSaved returns early when ids are empty', () async {
      await repo.toggleSaved('', 'c1');
      await repo.toggleSaved('u1', '');
      verifyNever(() => profileRepository.getProfilesByUserIds(any()));
    });

    test(
      'watchSavedCreativeIds returns empty set when ownerUserId empty',
      () async {
        final ids = await repo.watchSavedCreativeIds('').first;
        expect(ids, <String>{});
      },
    );

    test(
      'getSavedProfiles returns empty list when ownerUserId empty',
      () async {
        final profiles = await repo.getSavedProfiles('');
        expect(profiles, isEmpty);
      },
    );
  });
}
