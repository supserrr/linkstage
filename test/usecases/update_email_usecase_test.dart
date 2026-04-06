import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/usecases/auth/update_email_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates updateEmail', () async {
    final auth = MockAuthRepository();
    when(() => auth.updateEmail(any())).thenAnswer((_) async => {});
    await UpdateEmailUseCase(auth).call('new@b.com');
    verify(() => auth.updateEmail('new@b.com')).called(1);
  });
}
