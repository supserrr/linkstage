import 'package:flutter_bloc/flutter_bloc.dart';

import 'messages_page_state.dart';

class MessagesPageCubit extends Cubit<MessagesPageState> {
  MessagesPageCubit() : super(const MessagesPageState());

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setFilter(MessagesChatFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void bumpRefresh() {
    emit(state.copyWith(refreshNonce: state.refreshNonce + 1));
  }
}
