#!/usr/bin/env node
/**
 * Wipe all user data from Firebase (Firestore + Auth).
 * Run from project root with: node scripts/wipe-all-user-data.js
 *
 * Prerequisites:
 * - Firebase service account JSON at firebase-service-account.json (or set GOOGLE_APPLICATION_CREDENTIALS)
 * - npm install in ./functions (for firebase-admin)
 */

const path = require('path');
const admin = require(path.join(__dirname, '../functions/node_modules/firebase-admin'));

const BATCH_SIZE = 500;

async function deleteCollection(db, collectionRef) {
  const query = collectionRef.limit(BATCH_SIZE);
  const snapshot = await query.get();
  if (snapshot.empty) return 0;

  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return snapshot.size;
}

async function deleteCollectionRecursive(db, collectionPath) {
  const colRef = db.collection(collectionPath);
  let total = 0;
  let count;
  do {
    count = await deleteCollection(db, colRef);
    total += count;
    if (count > 0) process.stdout.write(`  Deleted ${total} docs from ${collectionPath}\r`);
  } while (count > 0);
  if (total > 0) console.log(`  Deleted ${total} docs from ${collectionPath}`);
  return total;
}

async function deleteSubcollections(db, parentPath, subcolNames) {
  const parentSnap = await db.collection(parentPath.split('/')[0]).get();
  for (const doc of parentSnap.docs) {
    const docPath = `${parentPath.split('/')[0]}/${doc.id}`;
    for (const sub of subcolNames) {
      await deleteCollectionRecursive(db, `${docPath}/${sub}`);
    }
  }
}

async function wipeFirestore(db) {
  console.log('Wiping Firestore...');

  // 1. User subcollections (must delete before users)
  const userCol = db.collection('users');
  const usersSnap = await userCol.get();
  const userSubcols = [
    'saved_creatives',
    'followed_planners',
    'device_tokens',
    'notification_reads',
    'accepted_event_ids',
    'planner_new_event_notifications',
  ];
  for (const userDoc of usersSnap.docs) {
    for (const sub of userSubcols) {
      await deleteCollectionRecursive(db, `users/${userDoc.id}/${sub}`);
    }
  }

  // 2. Chat subcollections
  const chatsSnap = await db.collection('chats').get();
  for (const chatDoc of chatsSnap.docs) {
    await deleteCollectionRecursive(db, `chats/${chatDoc.id}/users`);
    await deleteCollectionRecursive(db, `chats/${chatDoc.id}/messages`);
  }

  // 3. User_chats subcollection
  const userChatsSnap = await db.collection('user_chats').get();
  for (const ucDoc of userChatsSnap.docs) {
    await deleteCollectionRecursive(db, `user_chats/${ucDoc.id}/chats`);
  }

  // 4. Conversations/messages (legacy)
  const convsSnap = await db.collection('conversations').get();
  for (const convDoc of convsSnap.docs) {
    await deleteCollectionRecursive(db, `conversations/${convDoc.id}/messages`);
  }

  // 5. Root collections
  const rootCollections = [
    'users',
    'profiles',
    'planner_profiles',
    'events',
    'bookings',
    'reviews',
    'collaborations',
    'creative_past_work_preferences',
    'chat_users',
    'chats',
    'user_chats',
    'conversations',
  ];
  for (const name of rootCollections) {
    await deleteCollectionRecursive(db, name);
  }

  console.log('Firestore wipe complete.');
}

async function wipeAuth(auth) {
  console.log('Wiping Firebase Auth users...');
  let totalDeleted = 0;
  let pageToken;
  do {
    const listResult = await auth.listUsers(1000, pageToken);
    const uids = listResult.users.map((u) => u.uid);
    if (uids.length === 0) break;
    try {
      const deleteResult = await auth.deleteUsers(uids);
      totalDeleted += uids.length;
      console.log(`  Deleted ${uids.length} users (failures: ${deleteResult.failureCount})`);
      if (deleteResult.failureCount > 0) {
        deleteResult.errors.forEach((e) => console.warn('    ', e.uid, e.error.message));
      }
    } catch (e) {
      console.error('Auth delete failed:', e.message);
      break;
    }
    pageToken = listResult.pageToken;
  } while (pageToken);
  console.log(`Firebase Auth wipe complete. Total deleted: ${totalDeleted}`);
}

async function main() {
  const credPath =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.join(__dirname, '..', 'firebase-service-account.json');

  try {
    const fs = require('fs');
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({ credential: admin.credential.applicationDefault() });
    } else if (fs.existsSync(credPath)) {
      const cred = JSON.parse(fs.readFileSync(credPath, 'utf8'));
      admin.initializeApp({ credential: admin.credential.cert(cred) });
    } else {
      throw new Error(`Service account not found at ${credPath}`);
    }
  } catch (e) {
    console.error(
      'Failed to initialize Firebase. Ensure firebase-service-account.json exists in project root, or set GOOGLE_APPLICATION_CREDENTIALS.'
    );
    console.error(e.message);
    process.exit(1);
  }

  const db = admin.firestore();
  const auth = admin.auth();

  try {
    await wipeFirestore(db);
    await wipeAuth(auth);
    console.log('All user data wiped successfully.');
  } catch (e) {
    console.error('Wipe failed:', e);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();
