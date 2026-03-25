import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/creative_past_work_preferences_remote_datasource.dart';
import 'package:linkstage/data/repositories/creative_past_work_preferences_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockCreativePastWorkPreferencesRemoteDataSource extends Mock
    implements CreativePastWorkPreferencesRemoteDataSource {}

void main() {
  group('CreativePastWorkPreferencesRepositoryImpl', () {
    late MockCreativePastWorkPreferencesRemoteDataSource remote;
    late CreativePastWorkPreferencesRepositoryImpl repo;

    setUp(() {
      remote = MockCreativePastWorkPreferencesRemoteDataSource();
      repo = CreativePastWorkPreferencesRepositoryImpl(remote);
    });

    test('setItemVisibility(show=true) removes hidden id', () async {
      when(() => remote.removeHiddenId(any(), any())).thenAnswer((_) async {});

      await repo.setItemVisibility('u1', 'item1', true);

      verify(() => remote.removeHiddenId('u1', 'item1')).called(1);
      verifyNever(() => remote.addHiddenId(any(), any()));
    });

    test('setItemVisibility(show=false) adds hidden id', () async {
      when(() => remote.addHiddenId(any(), any())).thenAnswer((_) async {});

      await repo.setItemVisibility('u1', 'item1', false);

      verify(() => remote.addHiddenId('u1', 'item1')).called(1);
      verifyNever(() => remote.removeHiddenId(any(), any()));
    });
  });
}
