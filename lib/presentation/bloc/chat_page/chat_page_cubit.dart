import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import 'chat_page_state.dart';

class ChatPageCubit extends Cubit<ChatPageState> {
  ChatPageCubit() : super(const ChatPageState());

  void setError(Object e) => emit(state.copyWith(error: e));

  void clearError() => emit(state.copyWith(clearError: true));

  void setChatSession({
    required String resolvedChatId,
    String? otherUserId,
    String? otherUserName,
    UserRole? otherUserRole,
    String? otherUserPhotoUrl,
  }) {
    emit(
      state.copyWith(
        clearError: true,
        resolvedChatId: resolvedChatId,
        otherUserId: otherUserId ?? state.otherUserId,
        otherUserName: otherUserName ?? state.otherUserName,
        otherUserRole: otherUserRole ?? state.otherUserRole,
        otherUserPhotoUrl: otherUserPhotoUrl ?? state.otherUserPhotoUrl,
      ),
    );
  }

  void bumpStreamRefresh() {
    emit(state.copyWith(streamRefreshNonce: state.streamRefreshNonce + 1));
  }

  void syncScrollAtBottom(int currentMessageCount) {
    if (state.showNewMessagesBanner ||
        state.lastSeenMessageCount != currentMessageCount) {
      emit(
        state.copyWith(
          showNewMessagesBanner: false,
          lastSeenMessageCount: currentMessageCount,
        ),
      );
    }
  }

  void scrollToNewMessagesConsumed(int currentMessageCount) {
    emit(
      state.copyWith(
        showNewMessagesBanner: false,
        lastSeenMessageCount: currentMessageCount,
      ),
    );
  }

  void afterMessagesLayout({
    required ScrollController scrollController,
    required int messageCount,
    required double atBottomThreshold,
  }) {
    if (!scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (!scrollController.hasClients) return;
      final atBottom = scrollController.position.pixels <= atBottomThreshold;
      final lastSeen = state.lastSeenMessageCount;
      final showBanner = state.showNewMessagesBanner;
      if (messageCount > lastSeen && !atBottom) {
        if (!showBanner) {
          emit(state.copyWith(showNewMessagesBanner: true));
        }
      } else if (atBottom) {
        emit(state.copyWith(lastSeenMessageCount: messageCount));
      }
    });
  }
}
