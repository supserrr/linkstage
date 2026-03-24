import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/user_repository.dart';
import 'package:linkstage/domain/usecases/user/upsert_user_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const UserEntity(id: 'fallback', email: 'f@f.com'),
    );
  });

  test('delegates upsertUser', () async {
    final repo = MockUserRepository();
    when(() => repo.upsertUser(any())).thenAnswer((_) async => {});
    const u = UserEntity(id: '1', email: 'a@b.com');
    await UpsertUserUseCase(repo).call(u);
    verify(() => repo.upsertUser(u)).called(1);
  });
}
