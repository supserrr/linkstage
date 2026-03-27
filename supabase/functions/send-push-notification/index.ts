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
    targetUserId?: string;
    title?: string;
    body?: string;
    data?: Record<string, string>;
  };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const targetUserId = body.targetUserId;
  const title = (body.title ?? "").slice(0, 200);
  const notificationBody = (body.body ?? "").slice(0, 500);

  if (!targetUserId || !title) {
    return Response.json(
      { error: "targetUserId and title are required" },
      { status: 400 }
    );
  }

  const ALLOWED_DATA_KEYS = new Set([
    "route",
    "type",
    "bookingId",
    "eventId",
    "collaborationId",
  ]);
  const ALLOWED_ROUTE_PATTERNS = [
    /^\/event\/[^/]+\/applicants$/,
    /^\/event\/[^/]+$/,
    /^\/bookings$/,
    /^\/collaboration\/detail$/,
    /^\/notifications$/,
    /^\/messages\/chat\/[^/]+$/,
    /^\/messages\/with\/[^/]+$/,
  ];

  const rawData = body.data ?? {};
  const data: Record<string, string> = {};
  for (const [k, v] of Object.entries(rawData)) {
    if (ALLOWED_DATA_KEYS.has(k) && typeof v === "string") {
      const val = String(v).slice(0, 256);
      if (k === "route") {
        if (!ALLOWED_ROUTE_PATTERNS.some((p) => p.test(val))) {
          return Response.json(
            { error: "Invalid route in data" },
            { status: 400 }
          );
        }
      }
      data[k] = val;
    }
  }

  try {
    const accessToken = await getGoogleAccessToken();
    const tokens = await getFcmTokens(accessToken, targetUserId);

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No FCM tokens for user" }),
        {
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    let sent = 0;
    for (const t of tokens) {
      const ok = await sendFcm(
        accessToken,
        t,
        title,
        notificationBody,
        data
      );
      if (ok) sent++;
    }

    return new Response(
      JSON.stringify({ sent, total: tokens.length }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (e) {
    console.error("send-push-notification error:", e);
    return Response.json(
      { error: e instanceof Error ? e.message : "Internal error" },
      { status: 500 }
    );
  }
});
