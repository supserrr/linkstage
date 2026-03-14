import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import * as jose from "npm:jose@5";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "linkstage-rw";
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL");
const FIREBASE_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY");

const FIREBASE_X509_URL =
  "https://www.googleapis.com/service_accounts/v1/metadata/x509/securetoken@system.gserviceaccount.com";
const FIREBASE_ISSUER = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;

let cachedPublicKeys: Record<string, string> | null = null;

async function getFirebasePublicKeys(): Promise<Record<string, string>> {
  if (cachedPublicKeys) return cachedPublicKeys;
  const res = await fetch(FIREBASE_X509_URL);
  if (!res.ok) throw new Error("Failed to fetch Firebase public keys");
  cachedPublicKeys = (await res.json()) as Record<string, string>;
  return cachedPublicKeys;
}

async function verifyFirebaseToken(token: string): Promise<string | null> {
  try {
    const publicKeys = await getFirebasePublicKeys();
    const { payload } = await jose.jwtVerify(
      token,
      async (header) => {
        const kid = header.kid ?? "";
        const x509Cert = publicKeys[kid];
        if (!x509Cert) throw new Error(`Unknown key: ${kid}`);
        return await jose.importX509(x509Cert, "RS256");
      },
      {
        issuer: FIREBASE_ISSUER,
        audience: FIREBASE_PROJECT_ID,
        algorithms: ["RS256"],
        clockTolerance: 30,
      }
    );
    const sub = payload.sub as string | undefined;
    return sub ?? null;
  } catch {
    return null;
  }
}

async function getGoogleAccessToken(): Promise<string> {
  const clientEmail = FIREBASE_CLIENT_EMAIL;
  const privateKey = FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");
  if (!clientEmail || !privateKey) {
    throw new Error("FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY must be set");
  }

  const key = await jose.importPKCS8(privateKey, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const scope =
    "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging";
  const jwt = await new jose.SignJWT({ scope })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    const err = await tokenRes.text();
    throw new Error(`Failed to get access token: ${err}`);
  }

  const tokenData = (await tokenRes.json()) as { access_token?: string };
  const accessToken = tokenData.access_token;
  if (!accessToken) throw new Error("No access_token in response");
  return accessToken;
}

async function getFollowerIds(
  accessToken: string,
  plannerId: string
): Promise<string[]> {
  const parent = `projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;
  const url = `${parent}:runQuery`;

  const body = {
    structuredQuery: {
      from: [{ collectionId: "followed_planners", allDescendants: true }],
      where: {
        fieldFilter: {
          field: { fieldPath: "plannerId" },
          op: "EQUAL",
          value: { stringValue: plannerId },
        },
      },
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Firestore runQuery error: ${err}`);
  }

  const results = (await res.json()) as Array<{
    document?: { name?: string };
  }>;

  const followerIds: string[] = [];
  for (const item of results) {
    const name = item.document?.name;
    if (!name) continue;
    const parts = name.split("/");
    const usersIdx = parts.indexOf("users");
    if (usersIdx >= 0 && parts[usersIdx + 1]) {
      const userId = parts[usersIdx + 1];
      if (userId && userId !== plannerId) {
        followerIds.push(userId);
      }
    }
  }
  return followerIds;
}

async function createNotificationDoc(
  accessToken: string,
  followerId: string,
  eventId: string,
  plannerId: string,
  plannerName: string,
  eventTitle: string
): Promise<void> {
  const docPath = `projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${followerId}/planner_new_event_notifications/${eventId}`;
  const url = `https://firestore.googleapis.com/v1/${docPath}`;

  const docBody = {
    fields: {
      eventId: { stringValue: eventId },
      plannerId: { stringValue: plannerId },
      plannerName: { stringValue: plannerName },
      eventTitle: { stringValue: eventTitle },
      createdAt: { timestampValue: new Date().toISOString() },
    },
  };

  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(docBody),
  });

  if (!res.ok && res.status !== 409) {
    const err = await res.text();
    console.warn(`Failed to create notification doc for ${followerId}: ${err}`);
  }
}

async function getFcmTokens(
  accessToken: string,
  userId: string
): Promise<string[]> {
  const url = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${userId}/device_tokens`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    if (res.status === 404) return [];
    const err = await res.text();
    throw new Error(`Firestore error: ${err}`);
  }

  const data = (await res.json()) as {
    documents?: Array<{ fields?: Record<string, { stringValue?: string }> }>;
  };
  const docs = data.documents ?? [];
  const tokens: string[] = [];
  for (const doc of docs) {
    const token = doc.fields?.token?.stringValue;
    if (token) tokens.push(token);
  }
  return tokens;
}

async function sendFcm(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
  const payload = {
    message: {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: { priority: "high" },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const err = await res.text();
    console.warn(`FCM send failed: ${err}`);
    return false;
  }
  return true;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  if (req.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.replace("Bearer ", "").trim();
  if (!token) {
    return Response.json(
      { error: "Missing Authorization header" },
      { status: 401 }
    );
  }

  const uid = await verifyFirebaseToken(token);
  if (!uid) {
    return Response.json({ error: "Invalid token" }, { status: 401 });
  }

  let body: {
    eventId?: string;
    plannerId?: string;
    eventTitle?: string;
    plannerName?: string;
  };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const eventId = body.eventId;
  const plannerId = body.plannerId;
  const eventTitle = body.eventTitle ?? "Event";
  const plannerName = body.plannerName ?? "Someone";

  if (!eventId || !plannerId) {
    return Response.json(
      { error: "eventId and plannerId are required" },
      { status: 400 }
    );
  }

  try {
    const accessToken = await getGoogleAccessToken();
    const followerIds = await getFollowerIds(accessToken, plannerId);

    if (followerIds.length === 0) {
      return new Response(
        JSON.stringify({ notified: 0, message: "No followers" }),
        {
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const title = `${plannerName} posted a new event`;
    const data = {
      route: `/event/${eventId}`,
      eventId,
      type: "planner_new_event",
    };

    for (const followerId of followerIds) {
      await createNotificationDoc(
        accessToken,
        followerId,
        eventId,
        plannerId,
        plannerName,
        eventTitle
      );
    }

    let sent = 0;
    for (const followerId of followerIds) {
      const tokens = await getFcmTokens(accessToken, followerId);
      for (const t of tokens) {
        const ok = await sendFcm(accessToken, t, title, eventTitle, data);
        if (ok) sent++;
      }
    }

    return new Response(
      JSON.stringify({ notified: followerIds.length, fcmSent: sent }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (e) {
    console.error("notify-planner-event-published error:", e);
    return Response.json(
      { error: e instanceof Error ? e.message : "Internal error" },
      { status: 500 }
    );
  }
});
