# Supabase Storage Setup

Portfolio media (images/videos) and profile photos are stored in Supabase Storage. Uploads use a **two-step flow** for speed and reliability: the Flutter app obtains a signed upload URL from an Edge Function (auth only, no file), then uploads the file **directly** to Storage. This avoids sending the file through the Edge Function and reduces timeouts.

## Architecture

1. Flutter app sends Firebase ID token and metadata (type, fileName, isVideo) to the `get-upload-url` Edge Function (no file in the request).
2. Edge Function verifies the token with Firebase JWKS, builds the storage path, and calls Supabase Storage `createSignedUploadUrl(path)`. It returns `path`, `token`, and `publicUrl` to the client.
3. Flutter app uploads the file bytes directly to Supabase Storage using the Supabase Dart client’s `uploadBinaryToSignedUrl(path, token, bytes)`. The file is sent only once (client → Storage).
4. The app uses the returned `publicUrl`; no second request is needed.

Storage paths (unchanged):

- **Portfolio** (`type=portfolio`): `users/{uid}/portfolio/images/...` or `users/{uid}/portfolio/videos/...`
- **Profile photo** (`type=profile`): `users/{uid}/profile/avatar.{ext}` (single file per user, overwritten on each upload)

No Supabase Third-Party Auth or Firebase Cloud Functions are required. The legacy `portfolio-upload` function (which accepted the full file) is no longer used by the app but can be kept as a fallback.

## Image upload (compression)

All image uploads (profile photos and portfolio images) are compressed by default using the `fast_image_compress` package before being sent to Storage. This reduces upload size and time.

- **Profile photos:** target width 512px, quality 70%, `ImageQuality.medium`.
- **Portfolio images:** target width 1920px, quality 70%, `ImageQuality.medium`.
- **Videos:** not compressed; uploaded as-is.

Compression is applied in `PortfolioStorageDataSource` so every caller (onboarding, planner edit, creative edit) gets it automatically.

## 1. Storage Bucket

The `portfolio` bucket and RLS policies were created via Supabase MCP. The Edge Function uses the service role to create signed upload URLs; the client uploads using the token and does not need storage credentials.

## 2. Deploy Edge Functions

`supabase/config.toml` sets `verify_jwt = false` for `get-upload-url` so the Supabase gateway does not validate the `Authorization` header as a Supabase JWT. The app sends a **Firebase** ID token; the function verifies it with Firebase JWKS and returns 401 only if that verification fails. Without this config, the gateway would reject the Firebase token with 401 before the request reaches the function.

Deploy the function that issues signed upload URLs (required for the current app):

```bash
supabase functions deploy get-upload-url --project-ref rfpltplxqwwobcgjscbd
```

Optional: deploy the legacy full-upload function (only if you need a fallback):

```bash
supabase functions deploy portfolio-upload --project-ref rfpltplxqwwobcgjscbd
```

Configure Firebase project ID (used by both functions to verify JWTs):

```bash
supabase secrets set FIREBASE_PROJECT_ID=linkstage-rw --project-ref rfpltplxqwwobcgjscbd
```

## 3. Run the App

The LinkStage Supabase project is preconfigured. The app uses `SupabaseConfig.url` and `SupabaseConfig.anonKey` for the Supabase client (Storage only; Firebase remains the auth source). No dart-define needed:

```bash
flutter run
```

To use a different Supabase project:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co
```

## 4. Dependencies

The app depends on the `supabase` Dart package for Storage’s `uploadBinaryToSignedUrl` API. Auth continues to use Firebase.
