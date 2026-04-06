import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/usecases/auth/send_sign_in_link_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates sendSignInLinkToEmail', () async {
    final auth = MockAuthRepository();
    when(() => auth.sendSignInLinkToEmail(any())).thenAnswer((_) async => {});
    await SendSignInLinkUseCase(auth).call('a@b.com');
    verify(() => auth.sendSignInLinkToEmail('a@b.com')).called(1);
  });
}
