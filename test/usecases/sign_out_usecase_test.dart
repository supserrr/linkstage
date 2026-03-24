import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/usecases/auth/sign_out_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates to repository', () async {
    final auth = MockAuthRepository();
    when(() => auth.signOut()).thenAnswer((_) async => {});
    await SignOutUseCase(auth).call();
    verify(() => auth.signOut()).called(1);
  });
}
