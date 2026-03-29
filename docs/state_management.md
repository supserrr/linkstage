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
5. **Avoid `setState` for feature state**: Prefer small feature-scoped Cubits (e.g. filters, upload flags, step index) or existing domain Blocs/Cubits. Modal bottom sheets may still use `StatefulBuilder` for ephemeral form state inside the sheet.

### Local / page-scoped Cubits (examples)

| Cubit | Role |
| ----- | ---- |
| `CreativeExploreCubit` / `UnifiedExploreCubit` | Explore tabs, filters, discoverable events, planner list (`explore_page.dart`) |
| `MessagesPageCubit` | Chat list search query, filter chips, refresh nonce |
| `LocationPickerCubit` | Map selection + geocoding |
| `FollowingPageCubit` | Followed planners list load/error |
| `PlannerCollaborationsTabCubit` | Planner “Collaborations” tab on My Events |
| `LoginFormCubit` | Toggle email-link vs Google entry |
| `ProfilePhotoUploadCubit` | Profile / portfolio upload busy flag |
| `UsernameStepCubit` | Username availability check UI |
| `ProfileSetupFlowCubit` | Profile setup `PageView` index |
| `CreativePastWorkCubit` | Past work `configMode` for visibility editing |
| `EventApplicantsCubit` | Planner applicants list, accept/reject/complete IDs, reviews map |
| `BookingsCubit` | Creative gigs + collaborations lists, maps, confirming completion ID |
| `SendCollaborationFormCubit` | Proposal form: submitting flag, event type, date, times |
| `CollaborationDetailUiCubit` | Detail overrides (status, creative confirmed), review flag, confirming completion |
| `ChatPageCubit` | Chat header/session fields, new-messages banner, scroll sync |

Modal bottom sheets and dialogs may still use `StatefulBuilder` for ephemeral UI (e.g. star rating in a sheet).

## Examples

### ProfilesBloc (Stream)

`ProfilesBloc` subscribes to `ProfileRepository.getProfiles()` stream. When filters change, it cancels the previous subscription and starts a new one.

### MyEventsCubit (Stream)

`MyEventsCubit` subscribes to `EventRepository.getEventsByPlannerId()` stream. The events list updates in real time when events are added, edited, or deleted. Mutations (`updateStatus`, `delete`) call the repository; the stream emits the new data. `load()` is used only for retry on error.

### PlannerDashboardCubit (Combined Streams)

`PlannerDashboardCubit` subscribes to both `EventRepository.getEventsByPlannerId()` and `BookingRepository.watchPendingBookingsByPlannerId()`. It combines both streams to build dashboard state (events, applicants count, recent activity). The dashboard updates when events or pending bookings change.

## Dependency Injection

Blocs and Cubits are created via `BlocProvider` in pages. Repositories and data sources are registered in `lib/core/di/injection.dart` using GetIt. Data sources use `FirebaseFirestore.instance` by default and can be overridden for tests.

## Chat (custom UI)

Chat uses `ConversationRepository` streams (`watchMessages`, `watchConversations`) and `ChatPage` with `ChatPageCubit` for session UI state (resolved chat id, other user display, new-message banner). See [Chat](chat.md) for collection layout.

## Future work

- **Optional**: Extract tiny Cubits for other `StatefulBuilder`-only flows if they grow beyond modal-local state.
