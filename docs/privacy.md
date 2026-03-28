# Privacy Settings

Privacy settings are stored in Firestore and enforced across the app. Users control profile visibility, who can message them, and whether their online status is shown.

## Firestore Schema

### Users collection

Added fields on `users/{userId}`:

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `profileVisibility` | string | `everyone`, `connections_only`, `only_me` | Who can see the profile in search and discovery |
| `whoCanMessage` | string | `everyone`, `worked_with`, `no_one` | Who can start a conversation |
| `showOnlineStatus` | boolean | - | Whether last-seen is visible to others |
| `lastSeen` | timestamp | - | Last activity timestamp (optional) |

### Denormalization

`profileVisibility` is denormalized into `profiles` and `planner_profiles` so search queries can filter without joining users.

## Profile visibility filtering

- **everyone**: Profile appears in search for all authenticated users.
- **connections_only**: Profile appears only to users who have worked together (completed booking or collaboration).
- **only_me**: Profile is excluded from search.

`ProfileRepositoryImpl` and `PlannerProfileRepositoryImpl` apply this filtering when fetching profiles. For `connections_only`, `UserRepository.hasWorkedWith(userId1, userId2)` is called (checks both booking and collaboration history).

## Who can message

`ConversationRepositoryImpl.getOrCreateOneToOneChat` calls `UserRepository.canSendMessageTo(senderId, recipientId)` before creating or returning a chat. If the recipient has `whoCanMessage == 'no_one'`, or `worked_with` and `hasWorkedWith` is false, the operation fails. The chat page shows a toast and pops.

## hasWorkedWith logic

Two users have worked together if:

- There is a completed booking (`status == 'completed'`) where one is planner and one is creative, or
- There is a collaboration (`status == 'accepted'`) where one is requester and one is target.

`UserRepository.hasWorkedWith` queries both `BookingRepository` and `CollaborationRepository`.

## Settings sync

`SettingsCubit` persists privacy settings to SharedPreferences and Firestore. When the user changes profile visibility, who can message, or show online status, `UserRepository.updatePrivacySettings` is called. When profile visibility changes, `ProfileRepository.upsertProfile` or `PlannerProfileRepository.upsertPlannerProfile` updates the denormalized field.

On settings page load, `loadFromBackend(userId)` fetches the user from Firestore and syncs state.

## Last seen

`UserRemoteDataSource.updateLastSeen(userId)` writes `lastSeen: serverTimestamp()` to the user document. Call when the app goes to background or when the user sends a message (debounced). Chat UI can display "last active" if the other user has `showOnlineStatus == true`.

## Event location privacy

Event planners can set **location visibility** when creating or editing an event: `public`, `private`, or `acceptedCreatives`. The planner always sees full location; others see placeholders when visibility is restricted.

### Enforcement

- **Client-side**: The app uses `event_location_utils.dart` to decide what to display. Cards and event detail show real address only when the viewer is the planner, or visibility is `public`, or (for `acceptedCreatives`) the viewer has an accepted booking for that event.
- **Firestore**: The `location` field remains in the event document. Firestore rules cannot mask individual fields; they allow or deny full-document read. Therefore, any authenticated user who can read the event document receives the raw location. True server-side hiding would require storing location in a separate collection with stricter read rules.
- **Denormalization**: When a booking is accepted, the app invokes the Supabase Edge Function `sync-accepted-event-id`, which writes `users/{creativeId}/accepted_event_ids/{eventId}` to Firestore. When a booking is removed from accepted (e.g. declined after acceptance), the function deletes that doc. This enables future rule-based checks and is used by the app for client-side location visibility logic.
- **Validation**: Firestore rules reject event create/update if `locationVisibility` is present and not one of `public`, `private`, `acceptedCreatives`.
