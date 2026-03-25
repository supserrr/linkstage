import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/data/datasources/creative_past_work_preferences_remote_datasource.dart';

void main() {
  test('getHiddenIds empty when no doc', () async {
    final fake = FakeFirebaseFirestore();
    final ds = CreativePastWorkPreferencesRemoteDataSource(firestore: fake);
    expect(await ds.getHiddenIds('u1'), isEmpty);
  });

  test('setHiddenIds getHiddenIds round trip', () async {
    final fake = FakeFirebaseFirestore();
    final ds = CreativePastWorkPreferencesRemoteDataSource(firestore: fake);

    await ds.setHiddenIds('u1', ['a', 'b']);
    expect(await ds.getHiddenIds('u1'), ['a', 'b']);
  });

  test('addHiddenId and removeHiddenId', () async {
    final fake = FakeFirebaseFirestore();
    final ds = CreativePastWorkPreferencesRemoteDataSource(firestore: fake);

    await ds.addHiddenId('u1', 'x');
    await ds.addHiddenId('u1', 'x');
    expect(await ds.getHiddenIds('u1'), ['x']);

    await ds.removeHiddenId('u1', 'x');
    expect(await ds.getHiddenIds('u1'), isEmpty);
  });
}
