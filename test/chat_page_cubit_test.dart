import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/domain/entities/user_entity.dart';
import 'package:linkstage/presentation/bloc/chat_page/chat_page_cubit.dart';

void main() {
  group('ChatPageCubit', () {
    test('setError and clearError', () {
      final cubit = ChatPageCubit();
      cubit.setError('e');
      expect(cubit.state.error, 'e');
      cubit.clearError();
      expect(cubit.state.error, isNull);
      cubit.close();
    });

    test('setChatSession updates fields', () {
      final cubit = ChatPageCubit();
      cubit.setChatSession(
        resolvedChatId: 'c1',
        otherUserId: 'u1',
        otherUserName: 'Bob',
        otherUserRole: UserRole.creativeProfessional,
        otherUserPhotoUrl: 'http://p',
      );
      expect(cubit.state.resolvedChatId, 'c1');
      expect(cubit.state.otherUserId, 'u1');
      expect(cubit.state.otherUserName, 'Bob');
      expect(cubit.state.otherUserRole, UserRole.creativeProfessional);
      expect(cubit.state.otherUserPhotoUrl, 'http://p');
      cubit.close();
    });

    test('bumpStreamRefresh increments nonce', () {
      final cubit = ChatPageCubit();
      expect(cubit.state.streamRefreshNonce, 0);
      cubit.bumpStreamRefresh();
      expect(cubit.state.streamRefreshNonce, 1);
      cubit.close();
    });

    test('syncScrollAtBottom updates last seen when count changes', () {
      final cubit = ChatPageCubit();
      cubit.syncScrollAtBottom(5);
      expect(cubit.state.lastSeenMessageCount, 5);
      cubit.close();
    });

    test('scrollToNewMessagesConsumed updates last seen', () {
      final cubit = ChatPageCubit();
      cubit.scrollToNewMessagesConsumed(3);
      expect(cubit.state.lastSeenMessageCount, 3);
      expect(cubit.state.showNewMessagesBanner, isFalse);
      cubit.close();
    });
  });
}
