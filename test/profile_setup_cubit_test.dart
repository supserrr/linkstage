import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkstage/domain/entities/profile_entity.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/repositories/profile_repository.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/domain/usecases/user/upsert_user_usecase.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_cubit.dart';
import 'package:linkstage/presentation/bloc/onboarding/profile_setup_state.dart';
import 'package:linkstage/data/datasources/portfolio_storage_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockUpsertUserUseCase extends Mock implements UpsertUserUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockPortfolioStorageDataSource extends Mock
    implements PortfolioStorageDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const UserEntity(id: 'fb', email: 'fb@test.com'));
    registerFallbackValue(
      const ProfileEntity(id: 'pfb', userId: 'fb', username: 'fb'),
    );
    registerFallbackValue(XFile('dummy'));
  });

  final baseUser = UserEntity(
    id: 'u1',
    email: 'u1@test.com',
    role: UserRole.creativeProfessional,
  );

  ProfileSetupCubit buildCubit({
    UserEntity? user,
    ProfileSetupState? initialDraft,
    UpsertUserUseCase? upsert,
    ProfileRepository? profileRepo,
    UserRepository? userRepo,
    PortfolioStorageDataSource? storage,
    AuthRepository? authRepo,
  }) {
    return ProfileSetupCubit(
      user ?? baseUser,
      upsert ?? MockUpsertUserUseCase(),
      profileRepo ?? MockProfileRepository(),
      userRepo ?? MockUserRepository(),
      storage ?? MockPortfolioStorageDataSource(),
      authRepo ?? MockAuthRepository(),
      initialDraft: initialDraft,
    );
  }

  test('initial draft skips user display name load', () {
    final draft = ProfileSetupState.initial().copyWith(
      isLoading: false,
      username: 'x',
    );
    final c = buildCubit(initialDraft: draft);
    expect(c.state.username, 'x');
    expect(c.state.isLoading, false);
  });

  test('setters update state', () {
    final c = buildCubit();
    c.setUsername('alice');
    c.setDisplayName('Alice');
    c.setBio('bio');
    c.setLocation('NYC');
    c.setCategory(ProfileCategory.photographer);
    c.setPriceRange(r'$$');
    expect(c.state.username, 'alice');
    expect(c.state.displayName, 'Alice');
    expect(c.state.bio, 'bio');
    expect(c.state.location, 'NYC');
    expect(c.state.category, ProfileCategory.photographer);
    expect(c.state.priceRange, r'$$');
  });

  test('setPhoto and clearPhotoAndError', () {
    final c = buildCubit();
    final f = XFile('p');
    c.setPhoto(f);
    expect(c.state.photoFile, f);
    c.clearPhotoAndError();
    expect(c.state.photoFile, isNull);
    expect(c.state.photoUrl, isNull);
    expect(c.state.photoUploadError, isNull);
  });

  test('uploadSelectedPhoto returns true when photoUrl already set', () async {
    final c2 = ProfileSetupCubit(
      baseUser,
      MockUpsertUserUseCase(),
      MockProfileRepository(),
      MockUserRepository(),
      MockPortfolioStorageDataSource(),
      MockAuthRepository(),
      initialDraft: ProfileSetupState.initial().copyWith(
        isLoading: false,
        photoUrl: 'https://u',
        username: 'a',
      ),
    );
    expect(await c2.uploadSelectedPhoto(), true);
  });

  test('uploadSelectedPhoto no-op when no file and no url', () async {
    final c = buildCubit();
    expect(await c.uploadSelectedPhoto(), false);
  });

  test('uploadSelectedPhoto fails when user id empty', () async {
    final auth = MockAuthRepository();
    when(() => auth.currentUser).thenReturn(null);
    final c = ProfileSetupCubit(
      UserEntity(id: '', email: 'e@test.com'),
      MockUpsertUserUseCase(),
      MockProfileRepository(),
      MockUserRepository(),
      MockPortfolioStorageDataSource(),
      auth,
    );
    c.setPhoto(XFile('p'));
    expect(await c.uploadSelectedPhoto(), false);
    expect(c.state.photoUploadError, contains('sign in'));
  });

  test('uploadSelectedPhoto success', () async {
    final auth = MockAuthRepository();
    final storage = MockPortfolioStorageDataSource();
    when(() => auth.currentUser).thenReturn(baseUser);
    when(
      () => storage.uploadProfilePhoto(any(), any()),
    ).thenAnswer((_) async => 'https://new');
    final c = ProfileSetupCubit(
      baseUser,
      MockUpsertUserUseCase(),
      MockProfileRepository(),
      MockUserRepository(),
      storage,
      auth,
    );
    c.setPhoto(XFile('p'));
    expect(await c.uploadSelectedPhoto(), true);
    expect(c.state.photoUrl, 'https://new');
    expect(c.state.isUploadingPhoto, false);
  });

  test('uploadSelectedPhoto maps storage error', () async {
    final auth = MockAuthRepository();
    final storage = MockPortfolioStorageDataSource();
    when(() => auth.currentUser).thenReturn(baseUser);
    when(
      () => storage.uploadProfilePhoto(any(), any()),
    ).thenThrow(Exception('  boom  '));
    final c = ProfileSetupCubit(
      baseUser,
      MockUpsertUserUseCase(),
      MockProfileRepository(),
      MockUserRepository(),
      storage,
      auth,
    );
    c.setPhoto(XFile('p'));
    expect(await c.uploadSelectedPhoto(), false);
    expect(c.state.photoUploadError, isNotEmpty);
    expect(c.state.isUploadingPhoto, false);
  });

  test('checkUsernameAvailable short username', () async {
    final ur = MockUserRepository();
    final c = ProfileSetupCubit(
      baseUser,
      MockUpsertUserUseCase(),
      MockProfileRepository(),
      ur,
      MockPortfolioStorageDataSource(),
      MockAuthRepository(),
    );
    expect(await c.checkUsernameAvailable('ab'), false);
    verifyNever(() => ur.checkUsernameAvailable(any()));
  });

  test('checkUsernameAvailable delegates', () async {
    final ur = MockUserRepository();
    when(() => ur.checkUsernameAvailable('abc')).thenAnswer((_) async => true);
    final c = ProfileSetupCubit(
      baseUser,
      MockUpsertUserUseCase(),
      MockProfileRepository(),
      ur,
      MockPortfolioStorageDataSource(),
      MockAuthRepository(),
    );
    expect(await c.checkUsernameAvailable('abc'), true);
  });

  test('submit requires username', () async {
    final c = buildCubit();
    await c.submit();
    expect(c.state.error, 'Username is required');
  });

  test('submit success', () async {
    final upsert = MockUpsertUserUseCase();
    final profileRepo = MockProfileRepository();
    when(() => upsert(any())).thenAnswer((_) async {});
    when(() => profileRepo.upsertProfile(any())).thenAnswer((_) async {});
    final c = ProfileSetupCubit(
      baseUser,
      upsert,
      profileRepo,
      MockUserRepository(),
      MockPortfolioStorageDataSource(),
      MockAuthRepository(),
    );
    c.setUsername('Alice');
    await c.submit();
    expect(c.state.success, true);
    expect(c.state.isLoading, false);
  });

  test('submit failure emits error message', () async {
    final upsert = MockUpsertUserUseCase();
    when(() => upsert(any())).thenThrow(Exception('nope'));
    final c = ProfileSetupCubit(
      baseUser,
      upsert,
      MockProfileRepository(),
      MockUserRepository(),
      MockPortfolioStorageDataSource(),
      MockAuthRepository(),
    );
    c.setUsername('bob');
    await c.submit();
    expect(c.state.success, false);
    expect(c.state.error, contains('nope'));
  });
}
