import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkstage/presentation/bloc/messages/messages_page_cubit.dart';
import 'package:linkstage/presentation/bloc/messages/messages_page_state.dart';

void main() {
  group('MessagesPageCubit', () {
    blocTest<MessagesPageCubit, MessagesPageState>(
      'setSearchQuery updates state',
      build: MessagesPageCubit.new,
      act: (c) => c.setSearchQuery('hello'),
      expect: () => [
        isA<MessagesPageState>().having(
          (s) => s.searchQuery,
          'searchQuery',
          'hello',
        ),
      ],
    );

    blocTest<MessagesPageCubit, MessagesPageState>(
      'bumpRefresh increments nonce',
      build: MessagesPageCubit.new,
      act: (c) => c.bumpRefresh(),
      expect: () => [
        isA<MessagesPageState>().having(
          (s) => s.refreshNonce,
          'refreshNonce',
          1,
        ),
      ],
    );

    blocTest<MessagesPageCubit, MessagesPageState>(
      'setFilter updates filter',
      build: MessagesPageCubit.new,
      act: (c) => c.setFilter(MessagesChatFilter.unread),
      verify: (c) {
        expect(c.state.filter, MessagesChatFilter.unread);
      },
    );

    blocTest<MessagesPageCubit, MessagesPageState>(
      'setFilter supports favorites and all',
      build: MessagesPageCubit.new,
      act: (c) => c
        ..setFilter(MessagesChatFilter.favorites)
        ..setFilter(MessagesChatFilter.all),
      expect: () => [
        isA<MessagesPageState>().having(
          (s) => s.filter,
          'filter',
          MessagesChatFilter.favorites,
        ),
        isA<MessagesPageState>().having(
          (s) => s.filter,
          'filter',
          MessagesChatFilter.all,
        ),
      ],
    );
  });
}
