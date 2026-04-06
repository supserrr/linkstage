import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Get FCM tokens for a user from users/{userId}/device_tokens.
 */
async function getFcmTokens(userId: string): Promise<string[]> {
  const snapshot = await db
    .collection("users")
    .doc(userId)
    .collection("device_tokens")
    .get();

  const tokens: string[] = [];
  snapshot.docs.forEach((doc) => {
    const token = doc.data().token as string | undefined;
    if (token) tokens.push(token);
  });
  return tokens;
}

/**
 * Send FCM notification to a user.
 */
async function sendToUser(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const tokens = await getFcmTokens(userId);
  if (tokens.length === 0) return;

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: { title, body },
    data,
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  const response = await messaging.sendEachForMulticast(message);
  if (response.failureCount > 0) {
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        console.warn(`FCM failed for token idx ${idx}: ${resp.error?.message}`);
      }
    });
  }
}

/**
 * Get display name for a user (for notification body).
 */
async function getDisplayName(userId: string): Promise<string> {
  const userDoc = await db.collection("users").doc(userId).get();
  const data = userDoc.data();
  if (!data) return "Someone";
  const displayName = data.displayName as string | undefined;
  if (displayName?.trim()) return displayName;
  const username = data.username as string | undefined;
  if (username?.trim()) return `@${username}`;
  const email = data.email as string | undefined;
  if (email) return email.split("@")[0] ?? "Someone";
  return "Someone";
}

/**
 * Get event title by ID.
 */
async function getEventTitle(eventId: string): Promise<string> {
  const eventDoc = await db.collection("events").doc(eventId).get();
  const title = eventDoc.data()?.title as string | undefined;
  return title ?? "Event";
}

/**
 * On new booking (creative applies) -> notify planner.
 */
export const onBookingCreated = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const status = data?.status as string | undefined;
    if (status !== "pending") return;

    const plannerId = data?.plannerId as string | undefined;
    const creativeId = data?.creativeId as string | undefined;
    const eventId = data?.eventId as string | undefined;
    if (!plannerId || !creativeId || !eventId) return;

    const creativeName = await getDisplayName(creativeId);
    const eventTitle = await getEventTitle(eventId);

    await sendToUser(
      plannerId,
      `New application for ${eventTitle}`,
      `${creativeName} applied`,
      {
        route: `/event/${eventId}/applicants`,
        bookingId: event.params.bookingId,
        eventId,
        type: "booking_new_application",
      }
    );
  }
);

/**
 * On booking status update (accepted/declined) -> notify creative.
 */
export const onBookingUpdated = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const change = event.data;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();
    const prevStatus = before?.status as string | undefined;
    const newStatus = after?.status as string | undefined;

    if (prevStatus === newStatus) return;
    if (newStatus !== "accepted" && newStatus !== "declined") return;

    const creativeId = after?.creativeId as string | undefined;
    const eventId = after?.eventId as string | undefined;
    if (!creativeId || !eventId) return;

    const eventTitle = await getEventTitle(eventId);

    if (newStatus === "accepted") {
      await sendToUser(
        creativeId,
        "Application accepted",
        `Your application for ${eventTitle} was accepted`,
        {
          route: "/bookings",
          bookingId: event.params.bookingId,
          eventId,
          type: "booking_accepted",
        }
      );
    } else {

      await sendToUser(
        creativeId,
        "Application declined",
        `Your application for ${eventTitle} was declined`,
        {
          route: "/bookings",
          bookingId: event.params.bookingId,
          eventId,
          type: "booking_declined",
        }
      );
    }
  }
);

/**
 * On new collaboration (planner sends proposal) -> notify creative/target.
 */
export const onCollaborationCreated = onDocumentCreated(
  "collaborations/{collabId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const status = data?.status as string | undefined;
    if (status !== "pending") return;

    const targetUserId = data?.targetUserId as string | undefined;
    const requesterId = data?.requesterId as string | undefined;
    if (!targetUserId || !requesterId) return;

    const requesterName = await getDisplayName(requesterId);

    await sendToUser(
      targetUserId,
      "New collaboration proposal",
      `${requesterName} sent you a proposal`,
      {
        route: "/collaboration/detail",
        collaborationId: event.params.collabId,
        type: "collaboration_new_proposal",
      }
    );
  }
);

/**
 * On collaboration status update (accepted/declined) -> notify requester.
 */
export const onCollaborationUpdated = onDocumentUpdated(
  "collaborations/{collabId}",
  async (event) => {
    const change = event.data;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();
    const prevStatus = before?.status as string | undefined;
    const newStatus = after?.status as string | undefined;

    if (prevStatus === newStatus) return;
    if (newStatus !== "accepted" && newStatus !== "declined") return;

    const requesterId = after?.requesterId as string | undefined;
    const targetUserId = after?.targetUserId as string | undefined;
    if (!requesterId || !targetUserId) return;

    const targetName = await getDisplayName(targetUserId);

    if (newStatus === "accepted") {
      await sendToUser(
        requesterId,
        "Proposal accepted",
        `${targetName} accepted your collaboration`,
        {
          route: "/collaboration/detail",
          collaborationId: event.params.collabId,
          type: "collaboration_accepted",
        }
      );
    } else {
      await sendToUser(
        requesterId,
        "Proposal declined",
        `${targetName} declined your collaboration`,
        {
          route: "/collaboration/detail",
          collaborationId: event.params.collabId,
          type: "collaboration_declined",
        }
      );
    }
  }
);
