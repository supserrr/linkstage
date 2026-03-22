enum MessagesChatFilter { all, unread, favorites }

class MessagesPageState {
  const MessagesPageState({
    this.searchQuery = '',
    this.filter = MessagesChatFilter.all,
    this.refreshNonce = 0,
  });

  final String searchQuery;
  final MessagesChatFilter filter;
  final int refreshNonce;

  MessagesPageState copyWith({
    String? searchQuery,
    MessagesChatFilter? filter,
    int? refreshNonce,
  }) {
    return MessagesPageState(
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      refreshNonce: refreshNonce ?? this.refreshNonce,
    );
  }
}
