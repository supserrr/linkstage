import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/presentation/bloc/profiles/profiles_bloc.dart';
import 'package:linkstage/presentation/bloc/profiles/profiles_state.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repo;

  setUp(() {
    repo = MockProfileRepository();
  });

  test('emits loaded when stream emits profiles', () async {
    const p = ProfileEntity(id: 'u1', userId: 'u1', username: 'alice');
    when(
      () => repo.getProfiles(excludeUserId: 'self'),
    ).thenAnswer((_) => Stream.value([p]));

    final bloc = ProfilesBloc(repo, excludeUserId: 'self');
    bloc.add(ProfilesLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(bloc.state.status, ProfilesStatus.loaded);
    expect(bloc.state.profiles.length, 1);
    expect(bloc.state.profiles.first.username, 'alice');
    await bloc.close();
  });

  test('search query changes filter list in state', () async {
    const p = ProfileEntity(id: 'u1', userId: 'u1', username: 'bob');
    when(() => repo.getProfiles()).thenAnswer((_) => Stream.value([p]));

    final bloc = ProfilesBloc(repo);
    bloc.add(ProfilesLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    bloc.add(ProfilesSearchQueryChanged('zzz'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.searchQuery, 'zzz');
    expect(bloc.state.filteredProfiles, isEmpty);
    await bloc.close();
  });
}
