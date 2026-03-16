# Firestore Not Loading – Troubleshooting

If nothing loads from Firebase/Firestore and it's not a network issue, check the following.

## 1. Check the debug console

With the debug logging added in `auth_redirect.dart`, run the app and watch the console when loading the home screen. Look for:

```
[AuthRedirect] Firestore load failed: ...
```

Common errors:

- **`PERMISSION_DENIED`** – See sections 2–4 below
- **`UNAVAILABLE`** – Firestore may be down, or wrong project/region
- **`NOT_FOUND`** – Document or collection doesn’t exist

## 2. App Check (very common)

If **App Check** is **enforced** for Firestore but the app doesn’t send valid tokens, all reads will fail with `PERMISSION_DENIED`.

**Check:** Firebase Console → App Check → Cloud Firestore

- If enforcement is on: either **Unenforce** temporarily to test, or add App Check to the app (e.g. `firebase_app_check` + Debug Provider in dev).

## 3. Firestore rules

Rules require `request.auth != null` for reads. If the auth token is missing or invalid, reads will fail.

**Check:**

- User is signed in before Firestore calls
- Firestore rules are deployed: `firebase deploy --only firestore:rules`
- Rules match your data model (see `firestore.rules`)

## 4. User document missing

`AuthRedirectNotifier` loads `users/{userId}` after sign-in. If that document doesn’t exist (e.g. new Google user who skipped onboarding), `getUser` returns `null` and the app can show empty or fallback UI.

**Fix:** Ensure the user document is created during onboarding (role selection or profile setup).

## 5. Firestore not enabled

**Check:** Firebase Console → Firestore Database. The database must exist and be in the same project as your app (`linkstage-rw`).

## 6. Offline cache

Firestore uses offline persistence. A bad cache can cause empty or stale data.

**Temporary debug step:** In `main.dart`, after Firebase init, add:

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

Run the app again. If data appears, the cache was likely the issue. Restart the app with persistence re-enabled after clearing app data or reinstalling.

## 7. Emulator

If `USE_FIRESTORE_EMULATOR=true` is set but the emulator isn’t running, Firestore calls will fail.

**Check:** Don’t pass `--dart-define=USE_FIRESTORE_EMULATOR=true` unless the emulator is running, or remove it from your run configuration.
