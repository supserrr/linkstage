import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/domain/repositories/auth_repository.dart';
import 'package:linkstage/domain/usecases/auth/sign_in_with_email_link_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('delegates signInWithEmailLink', () async {
    final auth = MockAuthRepository();
    const u = UserEntity(id: '1', email: 'a@b.com');
    when(
      () => auth.signInWithEmailLink(any(), any()),
    ).thenAnswer((_) async => u);
    final out = await SignInWithEmailLinkUseCase(auth).call(
      'a@b.com',
      'https://link',
    );
    expect(out, u);
  });
}
