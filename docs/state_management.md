# State Management and Firestore Integration

## Overview

LinkStage uses **Bloc** for state management. All Firestore read and write operations are handled through a dedicated service layer. The UI never queries Firestore directly; it consumes state from Blocs/Cubits that subscribe to repository streams or invoke repository methods.

## Architecture

### Data Flow

```
UI (BlocBuilder) <-> Bloc/Cubit <-> Repository <-> Data Source <-> Firestore
```

- **Data sources** (`lib/data/datasources/`): Access Firestore. Expose streams or futures.
- **Repositories** (`lib/data/repositories/`, `lib/domain/repositories/`): Domain contracts and implementations that delegate to data sources.
- **Blocs/Cubits** (`lib/presentation/bloc/`): Subscribe to repository streams or call repository methods. Emit state for the UI.
- **UI** (`lib/presentation/pages/`, `lib/presentation/widgets/`): Uses `BlocProvider` and `BlocBuilder`. No Firestore imports.

### Rules

1. **No Firestore in presentation**: `cloud_firestore` and `FirebaseFirestore` must not be imported in `lib/presentation/`.
2. **Streams for listings**: List screens (events, profiles, bookings, dashboard) use Firestore `snapshots()` streams for real-time updates.
3. **One-time calls for mutations**: Create, update, delete operations use `Future`-based repository methods. The corresponding streams emit updated data automatically.
4. **Loading and error states**: All BlocBuilder usages handle loading, error, and empty states explicitly.

## Examples

### ProfilesBloc (Stream)

`ProfilesBloc` subscribes to `ProfileRepository.getProfiles()` stream. When filters change, it cancels the previous subscription and starts a new one.

### MyEventsCubit (Stream)

`MyEventsCubit` subscribes to `EventRepository.getEventsByPlannerId()` stream. The events list updates in real time when events are added, edited, or deleted. Mutations (`updateStatus`, `delete`) call the repository; the stream emits the new data. `load()` is used only for retry on error.

### PlannerDashboardCubit (Combined Streams)

`PlannerDashboardCubit` subscribes to both `EventRepository.getEventsByPlannerId()` and `BookingRepository.watchPendingBookingsByPlannerId()`. It combines both streams to build dashboard state (events, applicants count, recent activity). The dashboard updates when events or pending bookings change.

## Dependency Injection

Blocs and Cubits are created via `BlocProvider` in pages. Repositories and data sources are registered in `lib/core/di/injection.dart` using GetIt. Data sources use `FirebaseFirestore.instance` by default and can be overridden for tests.

## Chat (chatview_connect)

Chat is implemented via the **chatview** and **chatview_connect** packages. Chat data and real-time streams are handled inside the packages (Firestore and Firebase Storage); the app does not use a custom ConversationRepository or Bloc for chat.

- **Current user**: Set when the Messages tab is built: `ChatViewConnect.instance.setCurrentUserId(currentUser.id)` (from `AuthRepository.currentUser`).
- **Screens**: `MessagesPage` shows `ChatList` (list of conversations); tapping a chat opens `ChatPage` at `/messages/chat/:chatId`. Opening a chat with a specific user (e.g. from profile "Contact planner") uses `/messages/with/:userId` and creates or finds the 1:1 room.
- **Firestore**: Chat uses a separate `chat_users` collection (and package-default chats/messages collections) so it does not clash with the existing `users` collection. See [Chat](chat.md) for details.

## Future Features

- **BookingsPage (creatives)**: When real gig data is shown, use `BookingsCubit` with `BookingRepository.watchCompletedBookingsByCreativeId()` stream.
