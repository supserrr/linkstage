# LinkStage

Mobile marketplace connecting event planners with creative professionals (DJs, photographers, decorators, content creators) in Rwanda.

## Features

- **Authentication**: Email/Password and Google Sign-In
- **Role selection**: Event Planner or Creative Professional
- **Profile discovery**: Browse creatives with filters (event type, location, budget)
- **Events & bookings**: Planners create events; creatives apply or get invited; accept/decline flows with notifications
- **Collaborations**: Direct proposals between planners and creatives outside events
- **Chat**: Real-time messaging via Firestore and chatview
- **Reviews**: Post-gig reviews for completed bookings and collaborations
- **Settings**: Theme (light/dark/system), notifications, language (EN/RW)
- **Push notifications**: FCM notifications for bookings, invitations, and collaborations
- **Maps & location**: Event location picker with geocoding

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.11+ |
| **State** | BLoC (flutter_bloc) |
| **Navigation** | go_router |
| **Auth & data** | Firebase (Auth, Firestore) |
| **Storage** | Supabase Storage (signed uploads) |
| **Push** | FCM + Supabase Edge Functions |
| **Backend** | Firestore, Supabase Edge Functions (Deno) |

## Prerequisites

- Flutter SDK ^3.11.0
- Node.js 20+ (for Supabase CLI, optional)
- Firebase project (`linkstage-rw`)
- Supabase project (`rfpltplxqwwobcgjscbd`)

## Setup

### 1. Clone & dependencies

```bash
git clone <repo-url>
cd linkstage-dev
flutter pub get
```

### 2. Firebase

1. Configure Firebase (generates `lib/firebase_options.dart`):
   ```bash
   dart run flutterfire_cli:flutterfire configure
   ```

2. Add platform config files:
   - **Android**: `android/app/google-services.json` (from Firebase Console)
   - **iOS**: `ios/Runner/GoogleService-Info.plist` (from Firebase Console)

3. **Hosting (email sign-in link)**: Magic links use `https://<project>.firebaseapp.com/finishSignIn`. Deploy Hosting so that URL is not “Site Not Found”:
   ```bash
   firebase deploy --only hosting --project linkstage-rw
   ```
   Static files live in `hosting_public/`.

4. **Google Sign-In**: The app pins `google_sign_in` 6.x (Play Services account picker) for reliable sign-in on emulators; `google_sign_in` 7.x uses Android Credential Manager and often returns “No credential available” on emulators. `AuthRemoteDataSource` passes the **Web** OAuth client ID from `google-services.json` (`client_type: 3`) as `serverClientId` via `lib/firebase_options.dart` (`googleSignInServerClientId`).

5. Deploy Firestore rules (optional, for production):
   ```bash
   firebase deploy --only firestore
   ```

### 3. Supabase

The app uses Supabase for **storage** (portfolio images, profile photos) and **push notifications** (Edge Functions). Firebase remains the auth source.

1. **Supabase project**: Default URL and anon key are in `lib/core/config/supabase_config.dart`. Override with `--dart-define` if needed:
   ```bash
   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```

2. **Storage uploads**: Deploy the Edge Function that issues signed upload URLs:
   ```bash
   supabase functions deploy get-upload-url --project-ref rfpltplxqwwobcgjscbd
   supabase secrets set FIREBASE_PROJECT_ID=linkstage-rw --project-ref rfpltplxqwwobcgjscbd
   ```
   See [docs/supabase_storage_setup.md](docs/supabase_storage_setup.md).

3. **Push notifications**: Deploy the Edge Function and set Firebase service account secrets:
   ```bash
   supabase functions deploy send-push-notification --project-ref rfpltplxqwwobcgjscbd
   ```
   Download the Firebase service account JSON from [Firebase Console](https://console.firebase.google.com/project/linkstage-rw/settings/serviceaccounts/adminsdk), save as `firebase-service-account.json` (or similar), then:
   ```bash
   supabase secrets set \
     FIREBASE_CLIENT_EMAIL="$(jq -r '.client_email' firebase-service-account.json)" \
     FIREBASE_PRIVATE_KEY="$(jq -r '.private_key' firebase-service-account.json)" \
     --project-ref rfpltplxqwwobcgjscbd
   ```
   See [docs/push_notifications.md](docs/push_notifications.md).

### 4. Secrets and sensitive files

- **Firebase service account**: Add to `.gitignore` (e.g. `firebase-service-account*.json*`) and never commit.
- **Supabase secrets**: Set via `supabase secrets set`; not stored in the repo.

## Run

```bash
flutter run
```

## Project Structure

```
lib/
├── core/           # Theme, router, DI, constants, config, services (FCM, push)
├── data/           # Data sources, models, repository implementations
├── domain/         # Entities, repositories, use cases
├── presentation/   # BLoC, pages, widgets (atoms, molecules, organisms)
├── app.dart
└── main.dart

supabase/functions/
├── get-upload-url/         # Signed Storage upload URLs
├── send-push-notification/ # FCM push via Edge Function
└── portfolio-upload/       # Legacy full-upload (optional)

functions/                  # Firebase Cloud Functions (legacy, optional)
docs/                       # Architecture, flows, setup guides
```

## Architecture

- **Clean Architecture**: Presentation, domain, data layers
- **BLoC** for state management
- **Firebase** (Auth + Firestore) for auth and core data
- **Supabase** for Storage (media) and Edge Functions (push)
- **go_router** for declarative routing

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/erd.md](docs/erd.md) | Firestore data model (ERD) |
| [docs/chat.md](docs/chat.md) | Chat setup and routes |
| [docs/create_event_flow.md](docs/create_event_flow.md) | Event creation flow |
| [docs/push_notifications.md](docs/push_notifications.md) | Push notifications (Supabase Edge Function) |
| [docs/supabase_storage_setup.md](docs/supabase_storage_setup.md) | Supabase Storage and upload flow |
| [docs/localization.md](docs/localization.md) | i18n (EN, RW) |
| [docs/state_management.md](docs/state_management.md) | BLoC patterns |
| [docs/privacy.md](docs/privacy.md) | Privacy settings |
| [docs/wipe_user_data.md](docs/wipe_user_data.md) | Wipe all user data (Firestore, Auth, Storage) |

## Testing

```bash
flutter test
```

## Deployment

- **Android / iOS**: Standard Flutter build (`flutter build apk`, `flutter build ios`).
- **Firebase**: Deploy rules and indexes as needed (`firebase deploy`).
- **Supabase**: Edge Functions deployed via CLI; secrets managed with `supabase secrets set`.

## License

Private - LinkStage Project
