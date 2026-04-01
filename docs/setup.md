# Setup and development

How to configure, run, test, and build LinkStage. For the data model and Firestore rules summary for coursework reports, see [erd.md](erd.md).

## Prerequisites

- Flutter SDK ^3.11.0 (see [pubspec.yaml](../pubspec.yaml))
- A Firebase project (team default: `linkstage-rw`)
- A Supabase project if you use signed uploads and push helpers (team default: `rfpltplxqwwobcgjscbd`)
- Node.js 20+ optional (Supabase CLI)

## Clone and install

```bash
git clone https://github.com/supserrr/linkstage.git
cd linkstage
flutter pub get
```

## Firebase

1. Configure Firebase (generates `lib/firebase_options.dart`):

   ```bash
   dart run flutterfire_cli:flutterfire configure
   ```

2. Add platform files from the Firebase Console:

   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

3. **Email link sign-in**: Deploy Hosting so `https://<project>.firebaseapp.com/finishSignIn` is served (static files in `hosting_public/`):

   ```bash
   firebase deploy --only hosting --project linkstage-rw
   ```

4. **Google Sign-In**: This repo pins `google_sign_in` 6.x for reliable emulator sign-in. The Web OAuth client ID from `google-services.json` (`client_type: 3`) is passed as `serverClientId` via `lib/firebase_options.dart` (`googleSignInServerClientId`).

5. Deploy Firestore rules and indexes as needed:

   ```bash
   firebase deploy --only firestore
   ```

Canonical rules: [`firestore.rules`](../firestore.rules).

## Supabase (media uploads and push only)

Firebase remains the source for authentication and core Firestore data. Supabase provides signed upload URLs and Edge Functions that call FCM.

The Supabase **anon key is not committed**. Pass it at run time or in CI:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Example deploy (project ref may differ):

```bash
supabase functions deploy get-upload-url --project-ref rfpltplxqwwobcgjscbd
supabase secrets set FIREBASE_PROJECT_ID=linkstage-rw --project-ref rfpltplxqwwobcgjscbd
```

- Storage: [supabase_storage_setup.md](supabase_storage_setup.md)
- Push: [push_notifications.md](push_notifications.md)

Do not commit Firebase service account JSON. Set `FIREBASE_CLIENT_EMAIL` and `FIREBASE_PRIVATE_KEY` with `supabase secrets set` as described in [push_notifications.md](push_notifications.md).

## Run

```bash
flutter run
```

## Test and format

```bash
dart format .
flutter analyze
flutter test
```

- Widget tests: `test/widget_test.dart`
- Unit tests: `test/*_test.dart`

## Build

- Android / iOS: `flutter build apk`, `flutter build ios`
- Firebase: `firebase deploy` for rules and hosting
- Supabase: CLI for functions and secrets

### Android release signing

Release builds use your **upload keystore** when `android/key.properties` is present (the file is gitignored). If it is missing, release APKs still build but are signed with the **debug** key—not suitable for Play Store or long-term installs.

1. Create a keystore (one-time; store the file and passwords securely):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Add `android/key.properties` (never commit):

   ```properties
   storePassword=<keystore password>
   keyPassword=<key password>
   keyAlias=upload
   storeFile=<path to .jks, e.g. /Users/you/upload-keystore.jks>
   ```

   Paths in `storeFile` can be absolute, or relative to the **`android/`** directory (Gradle resolves them via `rootProject.file`).

3. Build: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

See also: [Flutter — Sign the app](https://docs.flutter.dev/deployment/android#signing-the-app).

## Project layout

```
lib/
├── core/         # theme, router, DI, config, FCM/push services
├── data/         # datasources, models, repository implementations
├── domain/       # entities, repository contracts, use cases
└── presentation/ # BLoC, pages, widgets (atoms / molecules / organisms)

supabase/functions/   # Edge Functions (uploads, push, etc.)
```

Architecture notes: [state_management.md](state_management.md).

## Line coverage (for reports)

### Full instrumentation

```bash
flutter test --coverage
```

- **Whole codebase** (all paths in `coverage/lcov.info`): sum every `LF:` / `LH:` record.

### Filtered-style aggregate (optional, for reports or CI)

For an **“app code”** percentage without treating every large screen as equal to domain logic, exclude the paths below when you summarize `coverage/lcov.info` (manually, in a spreadsheet, or with the system **`lcov`** package if installed):

| Excluded path | Rationale |
|---------------|-----------|
| `lib/presentation/pages/` (prefix) | Full-screen pages; breadth-style widget tests optional |
| `lib/core/router/app_router.dart` | Large route table; integration-style or manual QA |
| `lib/core/router/auth_redirect.dart` | Auth redirect notifier; shell / integration |
| `lib/core/di/injection.dart` | DI bootstrap |
| `lib/firebase_options.dart` | Generated Firebase options |
| `lib/data/datasources/auth_remote_datasource.dart` | Firebase Auth / Google Sign-In (integration-tested) |
| `lib/core/services/fcm_service.dart` | FCM glue (integration-tested) |
| `lib/l10n/` (prefix) | Generated localizations |

Example after `flutter test --coverage` (adjust patterns to match your `lcov` version):

```bash
lcov --remove coverage/lcov.info \
  'lib/presentation/pages/*' \
  'lib/l10n/*' \
  'lib/core/router/app_router.dart' \
  'lib/core/router/auth_redirect.dart' \
  'lib/core/di/injection.dart' \
  'lib/firebase_options.dart' \
  'lib/data/datasources/auth_remote_datasource.dart' \
  'lib/core/services/fcm_service.dart' \
  -o coverage/lcov_filtered.info
lcov --summary coverage/lcov_filtered.info
```

Reaching **~80% on full `lcov.info`** (no exclusions) typically requires **on the order of two thousand** additional instrumented lines (mostly breadth-style widget tests on large `presentation` pages). Prefer reporting **full** vs **filtered** separately in write-ups.

**Measured reference:** On a full `flutter test --coverage` run, **full** `coverage/lcov.info` was **65.83%** (9623 / 14617 lines hit). Re-run `flutter test --coverage` after adding tests for current numbers.

### Scoped domain + utils (coursework reports)

**Scoped: `lib/domain` + `lib/core/utils`** (entities, use cases, shared utils—not the whole UI layer). With `lcov` installed:

```bash
lcov --extract coverage/lcov.info 'lib/domain/*' 'lib/core/utils/*' -o coverage/lcov_domain_utils.info
lcov --summary coverage/lcov_domain_utils.info
```

For coursework PDF **Figure 9.3**, the terminal screenshot usually shows the **whole-repo** line aggregate; state the **scoped** or **filtered** percentage separately in §9.3 so graders do not confuse partial coverage with full-app coverage.

## Course submission checklist

Use when preparing the PDF, demo video, and repository for grading.

- **Repository**: Public or shared-access GitHub; include everything needed to build and run on **Android or iOS** (device or emulator). Course policy often requires a **mobile** demo—not web, desktop, or Chrome-only.
- **Report**: Setup (this guide + [erd.md](erd.md)), database / ERD description, features, Firebase security summary ([erd.md — Firestore security rules](erd.md#firestore-security-rules-for-report)), **Known limitations and future work**, group contribution tracker. PDF formatting (e.g. font, file name `Group#_Final_Project_Submission.pdf`) applies to the document, not the repo.
- **Alignment**: Flutter + **go_router**; **BLoC** and clean layers (`presentation` / `domain` / `data`); two auth methods (email/password and Google); Firestore CRUD via repositories; [`firestore.rules`](../firestore.rules).
- **Before report screenshots**: `dart format .`, `flutter analyze`, `flutter test`; capture analyzer output if required. For **coverage** numbers (whole-app vs `domain` + `core/utils` scoped), see [Line coverage (for reports)](#line-coverage-for-reports) above.

## Documentation index

| Doc | Purpose |
|-----|---------|
| [erd.md](erd.md) | Firestore ERD, indexes, security rules summary |
| [state_management.md](state_management.md) | BLoC, data flow, local UI vs BLoC |
| [create_event_flow.md](create_event_flow.md) | Event creation |
| [chat.md](chat.md) | Chat routes and packages |
| [push_notifications.md](push_notifications.md) | FCM and Edge Functions |
| [supabase_storage_setup.md](supabase_storage_setup.md) | Signed uploads |
| [localization.md](localization.md) | i18n |
| [privacy.md](privacy.md) | Privacy settings |
| [wipe_user_data.md](wipe_user_data.md) | Wipe user data |
| [troubleshooting_firestore.md](troubleshooting_firestore.md) | Firestore issues |
| [splash_screen_setup.md](splash_screen_setup.md) | Splash |
| [app_icons_setup.md](app_icons_setup.md) | Launcher icons |
| [firebase-mcp-setup.md](firebase-mcp-setup.md) | Firebase MCP |
