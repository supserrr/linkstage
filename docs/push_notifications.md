# Push Notifications

Push notifications are sent via Firebase Cloud Messaging (FCM) when booking or collaboration events occur. The client registers FCM tokens in Firestore. Notifications are sent by a **Supabase Edge Function** that the Flutter app invokes via HTTP after writing to Firestore.

## Architecture

- **Client-triggered flow**: The app performs a Firestore write (e.g. create booking, update collaboration status), then immediately calls the Supabase Edge Function `send-push-notification` with the notification payload.
- **Edge Function**: Verifies the caller via Firebase ID token, fetches FCM tokens from Firestore, and sends notifications using the FCM HTTP v1 API.
- **Firebase**: Stores `device_tokens` under `users/{userId}/device_tokens`; FCM delivers the notification to the user's device.

## Client setup

- **Dependency**: `firebase_messaging` in `pubspec.yaml`.
- **Service**: `FcmService` in `lib/core/services/fcm_service.dart` handles token registration and message handling.
- **PushNotificationService**: `lib/core/services/push_notification_service.dart` calls the Edge Function after Firestore writes. Fire-and-forget; errors are logged.
- **Initialization**: In `main.dart`, after `initInjection()`, `FcmService.initialize()` is called. This sets up:
  - Token refresh listener
  - `FirebaseMessaging.onMessage` (foreground)
  - `FirebaseMessaging.onMessageOpenedApp` (background tap)
  - `getInitialMessage` (terminated tap)
- **Background handler**: `FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)` with a top-level function (required for background messages).

## Token storage

Tokens are stored in `users/{userId}/device_tokens/{docId}`. Each document has `token` (string) and `updatedAt` (timestamp). Doc ID is derived from the token hash to support multiple devices.

- **Registration**: On login (and when `notificationsEnabled` is true), `FcmService.registerTokenIfNeeded()` writes the token to Firestore.
- **Unregistration**: When the user disables notifications (`SettingsCubit.setNotificationsEnabled(false)`) or signs out (`AuthBloc`), `FcmService.unregisterToken()` removes the token from Firestore. If the user has no tokens, the Edge Function sends nothing (Option A: no `notificationsEnabled` check in the Edge Function).

## Supabase Edge Function: send-push-notification

Located in `supabase/functions/send-push-notification/index.ts`.

**Request**: `POST` with `Authorization: Bearer <Firebase ID token>`, JSON body:

```json
{
  "targetUserId": "string",
  "title": "string",
  "body": "string",
  "data": { "route": "...", "type": "...", "bookingId": "...", ... }
}
```

**Flow**:

1. Verify Firebase ID token (jose + Firebase JWKS)
2. Fetch FCM tokens from Firestore: `users/{targetUserId}/device_tokens` via Firestore REST API
3. For each token, call FCM HTTP v1 API: `POST https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`
4. Uses Firebase service account (`client_email` + `private_key`) for OAuth2 and Firestore/FCM access

**Secrets** (set via `supabase secrets set`):

- `FIREBASE_PROJECT_ID` (default: linkstage-rw)
- `FIREBASE_CLIENT_EMAIL` – from Firebase service account JSON
- `FIREBASE_PRIVATE_KEY` – from Firebase service account JSON (escape newlines as `\n`)

**Deploy**:

```bash
supabase functions deploy send-push-notification --project-ref rfpltplxqwwobcgjscbd
```

**config.toml**: `[functions.send-push-notification]` has `verify_jwt = false` because the function verifies the Firebase token in `Authorization`.

## Supabase Edge Function: notify-planner-event-published

Located in `supabase/functions/notify-planner-event-published/index.ts`.

**Request**: `POST` with `Authorization: Bearer <Firebase ID token>`, JSON body:

```json
{
  "eventId": "string",
  "plannerId": "string",
  "eventTitle": "string",
  "plannerName": "string"
}
```

**Flow**:

1. Verify Firebase ID token (jose + Firebase JWKS)
2. Get Google access token (same as send-push-notification)
3. Run Firestore collection group query on `followed_planners` where field `plannerId` equals the given planner ID to get follower user IDs
4. For each follower: create doc in `users/{followerId}/planner_new_event_notifications/{eventId}` (in-app notification)
5. For each follower: fetch FCM tokens and send push notification

**Secrets**: Same as `send-push-notification` (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY).

**Deploy**:

```bash
supabase functions deploy notify-planner-event-published --project-ref rfpltplxqwwobcgjscbd
```

**config.toml**: `[functions.notify-planner-event-published]` has `verify_jwt = false`.

**Firestore index**: Collection group index on `followed_planners` for `plannerId` (see `firestore.indexes.json`).

## Supabase Edge Function: sync-accepted-event-id

Located in `supabase/functions/sync-accepted-event-id/index.ts`.

Maintains `users/{creativeId}/accepted_event_ids/{eventId}` in Firestore for event location visibility. Called from the app when a booking is accepted or removed from accepted.

**Request**: `POST` with `Authorization: Bearer <Firebase ID token>`, JSON body:

```json
{
  "creativeId": "string",
  "eventId": "string",
  "action": "add" | "remove"
}
```

**Flow**:

1. Verify Firebase ID token (jose + Firebase JWKS)
2. Get Google access token (Firestore scope)
3. If action `add`: PATCH `users/{creativeId}/accepted_event_ids/{eventId}` with `createdAt`
4. If action `remove`: DELETE that document

**Secrets**: Same as `send-push-notification` (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY).

**Deploy**:

```bash
supabase functions deploy sync-accepted-event-id --project-ref rfpltplxqwwobcgjscbd
```

**config.toml**: `[functions.sync-accepted-event-id]` has `verify_jwt = false`.

**Call sites**: `EventApplicantsPage._accept` (add), `EventApplicantsPage._reject` when booking was accepted (remove), `BookingsPage._acceptInvitation` (add), `BookingsPage._declineInvitation` when booking was accepted (remove).

## Call sites and notification types

| Location | Event | Target | Title / Body / Route |
|----------|-------|--------|----------------------|
| `CreateEventCubit` | Create event with status=open | Followers | "{plannerName} posted a new event" – "{eventTitle}" – `/event/{eventId}` (via `notify-planner-event-published`) |
| `CreateEventCubit` | Update event to status=open (newly published) | Followers | Same as above |
| `MyEventsCubit` | updateStatus to open | Followers | Same as above |
| `EventDetailCubit` | Creative applies (createBooking) | Planner | "New application for {eventTitle}" – "{creativeName} applied" – `/event/{eventId}/applicants` |
| `CreateEventCubit` | Planner invites (createInvitation) | Creative | "Invitation to {eventTitle}" – "{plannerName} invited you" – `/bookings` |
| `EventApplicantsPage` | Accept booking | Creative | "Application accepted" – "Your application for {eventTitle} has been accepted" – `/bookings` |
| `EventApplicantsPage` | Decline booking / Cancel invitation | Creative | "Application declined" / "Invitation cancelled" – `/bookings` |
| `BookingsPage` | Accept invitation | Planner | "Invitation accepted" – "{creativeName} accepted your invitation to {eventTitle}" – `/event/{eventId}/applicants` |
| `BookingsPage` | Decline invitation | Planner | "Invitation declined" – "{creativeName} declined your invitation to {eventTitle}" – `/event/{eventId}/applicants` |
| `SendCollaborationPage` | Create collaboration | Target (creative) | "New collaboration proposal" – "{requesterName} sent you a proposal" – `/collaboration/detail` |
| `CollaborationDetailPage` / `BookingsPage` | Accept/decline collaboration | Requester | "Proposal accepted/declined" – "{name} accepted/declined your proposal" – `/collaboration/detail` |

### Payload format

Each notification includes a `data` map with:

- `route`: Path to navigate to when tapped (e.g. `/event/{eventId}/applicants`, `/bookings`, `/collaboration/detail`)
- `type`: Event type (e.g. `booking_new_application`, `booking_accepted`, `collaboration_new`, `collaboration_accepted`)
- `bookingId`, `eventId`, `collaborationId` as applicable

`FcmService._handleNotificationPayload` reads `data.route` and calls `AppRouter.router.go(route)`.

## Firebase service account

Create a service account in [Firebase Console](https://console.firebase.google.com/project/linkstage-rw/settings/serviceaccounts/adminsdk), download the JSON, and extract `client_email` and `private_key`:

```bash
supabase secrets set FIREBASE_CLIENT_EMAIL="..." --project-ref rfpltplxqwwobcgjscbd
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n" --project-ref rfpltplxqwwobcgjscbd
```

## Platform configuration

- **iOS**: Enable Push Notifications capability in Xcode. Upload APNs key or certificate to Firebase Console.
- **Android**: `google-services` plugin handles configuration. For Android 8+, a default notification channel is used.
