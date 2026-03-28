# Chat

Chat is implemented with the [chatview](https://pub.dev/packages/chatview) and [chatview_connect](https://pub.dev/packages/chatview_connect) packages, using Firebase (Firestore and Storage) as the backend.

## Setup

- **Initialization**: In `main.dart`, after Firebase is initialized, `ChatViewConnect.initialize(ChatViewCloudService.firebase, ...)` is called with:
  - `FirestoreChatCollectionNameConfig(users: 'chat_users')` so chat user documents live in a `chat_users` collection and do not clash with the app’s existing `users` collection.
  - `ChatUserConfig(idKey: 'id', nameKey: 'displayName', profilePhotoKey: 'photoUrl')` to align with common user document fields.
- **Current user ID**: Not set in `main()`. It is set when the user is authenticated and the Messages UI is built: `ChatViewConnect.instance.setCurrentUserId(currentUser.id)` in `MessagesPage` (from `AuthRepository.currentUser`).

## Routes

- **List**: `/messages` — Shows the chat list (Chat tab). Uses `ChatList` with `ChatListManager` from `ChatViewConnect.instance.getChatListManager(...)`.
- **Thread by chat id**: `/messages/chat/:chatId` — Opens an existing chat (e.g. from the list). Uses `ChatViewConnect.instance.getChatRoomManager(chatRoomId: chatId, ...)`.
- **Thread by user (1:1)**: `/messages/with/:userId` — Opens or creates a 1:1 chat with another user (e.g. from profile “Contact planner”). Uses `getChatRoomManager(currentUser: ..., otherUsers: [other], chatRoomType: ChatRoomType.oneToOne, ...)`.

Helpers: `AppRoutes.chat(chatId)` and `AppRoutes.chatWithUser(userId)`.

## Data and security

- **Firestore**: Chat uses the collections configured for chatview_connect (e.g. `chat_users`, and the package’s default chats/messages collections). The app’s main `users` collection is unchanged.
- **Firebase Storage**: Used by the package for chat media (e.g. images). Ensure Storage is enabled and rules allow authenticated uploads for the paths used by the package (see package documentation).
- **Security**: Restrict read/write to authenticated users and to the chat rooms they belong to, following the package’s documented Firestore and Storage rules.

## Entry points

- **Chat tab**: Bottom nav “Chat” opens the Messages tab (`MessagesPage`) with the chat list.
- **Profile**: “Contact planner” on a planner’s profile navigates to `AppRoutes.chatWithUser(plannerUserId)` so the user can start or continue a 1:1 chat with that planner.
