"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCollaborationUpdated = exports.onCollaborationCreated = exports.onBookingUpdated = exports.onBookingCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
/**
 * Get FCM tokens for a user from users/{userId}/device_tokens.
 */
async function getFcmTokens(userId) {
    const snapshot = await db
        .collection("users")
        .doc(userId)
        .collection("device_tokens")
        .get();
    const tokens = [];
    snapshot.docs.forEach((doc) => {
        const token = doc.data().token;
        if (token)
            tokens.push(token);
    });
    return tokens;
}
/**
 * Send FCM notification to a user.
 */
async function sendToUser(userId, title, body, data) {
    const tokens = await getFcmTokens(userId);
    if (tokens.length === 0)
        return;
    const message = {
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
            var _a;
            if (!resp.success) {
                console.warn(`FCM failed for token idx ${idx}: ${(_a = resp.error) === null || _a === void 0 ? void 0 : _a.message}`);
            }
        });
    }
}
/**
 * Get display name for a user (for notification body).
 */
async function getDisplayName(userId) {
    var _a;
    const userDoc = await db.collection("users").doc(userId).get();
    const data = userDoc.data();
    if (!data)
        return "Someone";
    const displayName = data.displayName;
    if (displayName === null || displayName === void 0 ? void 0 : displayName.trim())
        return displayName;
    const username = data.username;
    if (username === null || username === void 0 ? void 0 : username.trim())
        return `@${username}`;
    const email = data.email;
    if (email)
        return (_a = email.split("@")[0]) !== null && _a !== void 0 ? _a : "Someone";
    return "Someone";
}
/**
 * Get event title by ID.
 */
async function getEventTitle(eventId) {
    var _a;
    const eventDoc = await db.collection("events").doc(eventId).get();
    const title = (_a = eventDoc.data()) === null || _a === void 0 ? void 0 : _a.title;
    return title !== null && title !== void 0 ? title : "Event";
}
/**
 * On new booking (creative applies) -> notify planner.
 */
exports.onBookingCreated = (0, firestore_1.onDocumentCreated)("bookings/{bookingId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const status = data === null || data === void 0 ? void 0 : data.status;
    if (status !== "pending")
        return;
    const plannerId = data === null || data === void 0 ? void 0 : data.plannerId;
    const creativeId = data === null || data === void 0 ? void 0 : data.creativeId;
    const eventId = data === null || data === void 0 ? void 0 : data.eventId;
    if (!plannerId || !creativeId || !eventId)
        return;
    const creativeName = await getDisplayName(creativeId);
    const eventTitle = await getEventTitle(eventId);
    await sendToUser(plannerId, `New application for ${eventTitle}`, `${creativeName} applied`, {
        route: `/event/${eventId}/applicants`,
        bookingId: event.params.bookingId,
        eventId,
        type: "booking_new_application",
    });
});
/**
 * On booking status update (accepted/declined) -> notify creative.
 */
exports.onBookingUpdated = (0, firestore_1.onDocumentUpdated)("bookings/{bookingId}", async (event) => {
    const change = event.data;
    if (!change)
        return;
    const before = change.before.data();
    const after = change.after.data();
    const prevStatus = before === null || before === void 0 ? void 0 : before.status;
    const newStatus = after === null || after === void 0 ? void 0 : after.status;
    if (prevStatus === newStatus)
        return;
    if (newStatus !== "accepted" && newStatus !== "declined")
        return;
    const creativeId = after === null || after === void 0 ? void 0 : after.creativeId;
    const eventId = after === null || after === void 0 ? void 0 : after.eventId;
    if (!creativeId || !eventId)
        return;
    const eventTitle = await getEventTitle(eventId);
    if (newStatus === "accepted") {
        // Denormalize: creative can now see event location when visibility is acceptedCreatives
        await db
            .collection("users")
            .doc(creativeId)
            .collection("accepted_event_ids")
            .doc(eventId)
            .set({ createdAt: admin.firestore.FieldValue.serverTimestamp() });
        await sendToUser(creativeId, "Application accepted", `Your application for ${eventTitle} was accepted`, {
            route: "/bookings",
            bookingId: event.params.bookingId,
            eventId,
            type: "booking_accepted",
        });
    }
    else {
        // Remove accepted_event_ids when status changes from accepted
        if (prevStatus === "accepted") {
            await db
                .collection("users")
                .doc(creativeId)
                .collection("accepted_event_ids")
                .doc(eventId)
                .delete();
        }
        await sendToUser(creativeId, "Application declined", `Your application for ${eventTitle} was declined`, {
            route: "/bookings",
            bookingId: event.params.bookingId,
            eventId,
            type: "booking_declined",
        });
    }
});
/**
 * On new collaboration (planner sends proposal) -> notify creative/target.
 */
exports.onCollaborationCreated = (0, firestore_1.onDocumentCreated)("collaborations/{collabId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const status = data === null || data === void 0 ? void 0 : data.status;
    if (status !== "pending")
        return;
    const targetUserId = data === null || data === void 0 ? void 0 : data.targetUserId;
    const requesterId = data === null || data === void 0 ? void 0 : data.requesterId;
    if (!targetUserId || !requesterId)
        return;
    const requesterName = await getDisplayName(requesterId);
    await sendToUser(targetUserId, "New collaboration proposal", `${requesterName} sent you a proposal`, {
        route: "/collaboration/detail",
        collaborationId: event.params.collabId,
        type: "collaboration_new_proposal",
    });
});
/**
 * On collaboration status update (accepted/declined) -> notify requester.
 */
exports.onCollaborationUpdated = (0, firestore_1.onDocumentUpdated)("collaborations/{collabId}", async (event) => {
    const change = event.data;
    if (!change)
        return;
    const before = change.before.data();
    const after = change.after.data();
    const prevStatus = before === null || before === void 0 ? void 0 : before.status;
    const newStatus = after === null || after === void 0 ? void 0 : after.status;
    if (prevStatus === newStatus)
        return;
    if (newStatus !== "accepted" && newStatus !== "declined")
        return;
    const requesterId = after === null || after === void 0 ? void 0 : after.requesterId;
    const targetUserId = after === null || after === void 0 ? void 0 : after.targetUserId;
    if (!requesterId || !targetUserId)
        return;
    const targetName = await getDisplayName(targetUserId);
    if (newStatus === "accepted") {
        await sendToUser(requesterId, "Proposal accepted", `${targetName} accepted your collaboration`, {
            route: "/collaboration/detail",
            collaborationId: event.params.collabId,
            type: "collaboration_accepted",
        });
    }
    else {
        await sendToUser(requesterId, "Proposal declined", `${targetName} declined your collaboration`, {
            route: "/collaboration/detail",
            collaborationId: event.params.collabId,
            type: "collaboration_declined",
        });
    }
});
//# sourceMappingURL=index.js.map