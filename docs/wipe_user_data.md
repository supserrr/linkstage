# Wipe All User Data

This guide describes how to wipe all user data for a fresh start. LinkStage stores data in Firebase (Firestore, Auth) and Supabase (Storage).

## Option 1: Firebase MCP (when connected)

When the **user-firebase** MCP is connected and authenticated to project `linkstage-rw`:

1. **Subcollections first** – For each `users/{userId}`, delete: `saved_creatives`, `followed_planners`, `device_tokens`, `notification_reads`, `accepted_event_ids`, `planner_new_event_notifications`
2. For each `chats/{chatId}`, delete: `users`, `messages`
3. For each `user_chats/{userId}`, delete: `chats`
4. For each `conversations/{id}`, delete: `messages`
5. **Root collections** – Delete: `users`, `profiles`, `planner_profiles`, `events`, `bookings`, `reviews`, `collaborations`, `creative_past_work_preferences`, `chat_users`, `chats`, `user_chats`, `conversations`

MCP tools: `firestore_list_documents` (parent: `projects/linkstage-rw/databases/(default)/documents`, use `mask: {fieldPaths: []}`) then `firestore_delete_document` per document.

## Option 2: Wipe script (Firestore + Auth)

The script at `scripts/wipe-all-user-data.js` uses Firebase Admin SDK to wipe Firestore and Firebase Auth.

**Prerequisites:** Firebase service account JSON at project root (`firebase-service-account.json`) or set `GOOGLE_APPLICATION_CREDENTIALS`.

**Run:**

```bash
node scripts/wipe-all-user-data.js
```

Ensure `functions/node_modules` exists (`cd functions && npm install` if needed).

## Option 3: Firebase CLI (Firestore only)

```bash
firebase firestore:delete --all-collections --project linkstage-rw --force
```

Or per collection with subcollections:

```bash
firebase firestore:delete users --recursive --project linkstage-rw --force
firebase firestore:delete chats --recursive --project linkstage-rw --force
# ... repeat for each collection
```

## Option 4: Manual – Supabase Storage

The Supabase MCP has no Storage API. Wipe storage manually:

1. **Supabase Dashboard:** [Storage > portfolio bucket](https://supabase.com/dashboard/project/rfpltplxqwwobcgjscbd/storage/buckets/portfolio) – delete folders under `users/`
2. **Supabase JS client:** Use `storage.from('portfolio').remove(paths)` or empty the bucket via Dashboard

## Summary

| Backend           | MCP | Script | CLI/Manual |
|-------------------|-----|--------|------------|
| Firestore         | Yes | Yes    | Yes        |
| Firebase Auth     | No  | Yes    | [Console](https://console.firebase.google.com/project/linkstage-rw/authentication/users) |
| Supabase Storage  | No  | No     | Dashboard  |
