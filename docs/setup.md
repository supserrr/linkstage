# Developer setup

How to configure, run, test, and build LinkStage. For the Firestore model, indexes, and security rules, see [erd.md](erd.md).

## Table of contents

- [Prerequisites](#prerequisites)
- [Install](#install)
- [Configure Firebase](#configure-firebase)
- [Configure Supabase (optional)](#configure-supabase-optional)
- [Run](#run)
- [Test and analyze](#test-and-analyze)
- [Build](#build)
- [Android release signing](#android-release-signing)
- [Project layout](#project-layout)
- [Documentation](#documentation)
- [Test coverage (optional)](#test-coverage-optional)

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| Flutter | SDK `^3.11.0` — [`pubspec.yaml`](../pubspec.yaml) |
| Firebase | Project for Auth, Firestore, Hosting |
| Supabase | Only if you use signed uploads or push-related Edge Functions |
| Node.js 20+ | Optional; for Supabase CLI |

## Install

```bash
git clone https://github.com/supserrr/linkstage.git
cd linkstage
flutter pub get
```

Core flows need [Firebase](#configure-firebase). Signed uploads and push helpers need [Supabase](#configure-supabase-optional) and `--dart-define` values at run time.

## Configure Firebase

1. **Generate Dart options** (writes `lib/firebase_options.dart`):

   ```bash
   dart run flutterfire_cli:flutterfire configure
   ```

2. **Platform files** from the Firebase Console:

   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

3. **Email link sign-in:** Deploy Hosting so `https://<project>.firebaseapp.com/finishSignIn` is served (`hosting_public/`):

   ```bash
   firebase deploy --only hosting --project <your-project-id>
   ```

4. **Google Sign-In:** This repo pins `google_sign_in` 6.x. The Web OAuth client ID (`client_type: 3` in `google-services.json`) is passed as `serverClientId` via `lib/firebase_options.dart` (`googleSignInServerClientId`).

5. **Firestore rules and indexes** when you change them:

   ```bash
   firebase deploy --only firestore
   ```

   Canonical rules: [`firestore.rules`](../firestore.rules).

## Configure Supabase (optional)

Firebase remains the source for authentication and core Firestore data. Supabase provides signed upload URLs and Edge Functions that call FCM.

The Supabase **anon key is not committed**. Pass it at run time or in CI:

```bash
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Deploy functions and set secrets with the Supabase CLI (replace project ref):

```bash
supabase functions deploy get-upload-url --project-ref <ref>
supabase secrets set FIREBASE_PROJECT_ID=<id> --project-ref <ref>
```

- Storage: [supabase_storage_setup.md](supabase_storage_setup.md)
- Push: [push_notifications.md](push_notifications.md)

Do not commit Firebase service account JSON. Set `FIREBASE_CLIENT_EMAIL` and `FIREBASE_PRIVATE_KEY` with `supabase secrets set` as in [push_notifications.md](push_notifications.md).

## Run

```bash
flutter run
```

## Test and analyze

```bash
dart format .
flutter analyze
flutter test
```

- Widget tests: `test/widget_test.dart`
- Unit tests: `test/*_test.dart`

## Build

| Target | Command / notes |
|--------|-----------------|
| Android APK | `flutter build apk` |
| iOS | `flutter build ios` |
| Firebase | `firebase deploy` for rules and hosting (see [Configure Firebase](#configure-firebase)) |
| Supabase | CLI for functions and secrets (see [Configure Supabase (optional)](#configure-supabase-optional)) |

## Android release signing

Release builds use your **upload keystore** when `android/key.properties` exists (gitignored). Without it, release APKs use the **debug** key—not suitable for Play Store.

1. Create a keystore (store file and passwords securely):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Add `android/key.properties` (never commit):

   ```properties
   storePassword=<keystore password>
   keyPassword=<key password>
   keyAlias=upload
   storeFile=<path to .jks>
   ```

   `storeFile` may be absolute or relative to the **`android/`** directory.

3. Build: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

See [Sign the app (Android)](https://docs.flutter.dev/deployment/android#signing-the-app).

## Project layout

```
lib/
├── core/          # theme, router, DI, config, FCM/push
├── data/          # datasources, models, repositories
├── domain/        # entities, contracts, use cases
└── presentation/  # BLoC, pages, widgets

supabase/functions/  # Edge Functions
```

Architecture: [state_management.md](state_management.md).

## Documentation

| Document | Topic |
|----------|--------|
| [setup.md](setup.md) | This guide |
| [erd.md](erd.md) | Firestore ERD, indexes, rules |
| [state_management.md](state_management.md) | BLoC and layers |
| [app_icons_setup.md](app_icons_setup.md) | Launcher icons |
| [splash_screen_setup.md](splash_screen_setup.md) | Splash screen |
| [firebase-mcp-setup.md](firebase-mcp-setup.md) | Firebase MCP |
| [troubleshooting_firestore.md](troubleshooting_firestore.md) | Firestore issues |
| [create_event_flow.md](create_event_flow.md) | Event creation |
| [chat.md](chat.md) | Chat |
| [push_notifications.md](push_notifications.md) | FCM and Edge Functions |
| [supabase_storage_setup.md](supabase_storage_setup.md) | Signed uploads |
| [localization.md](localization.md) | i18n |
| [privacy.md](privacy.md) | Privacy |
| [wipe_user_data.md](wipe_user_data.md) | Wipe user data |

## Test coverage (optional)

```bash
flutter test --coverage
```

Summarize line hit rate from `coverage/lcov.info`. To exclude large UI surfaces from an aggregate, use `lcov --remove` with path patterns (e.g. `lib/presentation/pages/*`, generated `lib/l10n/*`, `lib/firebase_options.dart`). To scope to domain and shared utils:

```bash
lcov --extract coverage/lcov.info 'lib/domain/*' 'lib/core/utils/*' -o coverage/lcov_domain_utils.info
lcov --summary coverage/lcov_domain_utils.info
```

Requires the `lcov` package on your system where noted.
