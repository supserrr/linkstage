# 5) Serein Demo Script (Backend + QA pack)

I’m going to close the demo with backend security, server functions, and QA proof. I’ll start by briefly explaining that the app is production-backed by Firebase (Firestore + Auth) and that security rules restrict access correctly. I’ll show the Firestore rules and indexes, either in the Firebase Console or by quickly opening `firestore.rules` and `firestore.indexes.json`. If helpful, I can add a one-sentence note that they protect user data and support the queries used by the app.

Next, I’ll explain that server-side automation is handled with functions that react to Firestore changes. I’ll show `functions/src/index.ts` (or the Functions logs) and mention that these triggers support key workflows like booking and collaboration updates and notification-related data.

Then I’ll cover the Supabase production pieces that the app relies on for edge functionality, including signed upload URLs and push notification sending. I’ll show the Edge Functions under `supabase/functions/*` and point out that `supabase/config.toml` is configured so functions can verify Firebase tokens passed in the request.

Finally, I’ll show QA proof by running or showing passing unit/widget tests and a clean `flutter analyze` result. If needed, I can remind the reviewer that screenshots of these go into the PDF report. I’ll end with a single closing sentence confirming that we covered both auth methods, backend-verified CRUD, persistence after restart, and secure rules.

