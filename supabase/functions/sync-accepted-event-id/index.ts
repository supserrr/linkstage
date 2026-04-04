import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import * as jose from "npm:jose@5";

const FIREBASE_PROJECT_ID =
  Deno.env.get("FIREBASE_PROJECT_ID") ?? "linkstage-rw";
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
    throw new Error(
      "FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY must be set"
    );
  }

  const key = await jose.importPKCS8(privateKey, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const scope = "https://www.googleapis.com/auth/datastore";
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

async function addAcceptedEventId(
  accessToken: string,
  creativeId: string,
  eventId: string
): Promise<void> {
  const docPath = `projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${creativeId}/accepted_event_ids/${eventId}`;
  const url = `https://firestore.googleapis.com/v1/${docPath}`;

  const docBody = {
    fields: {
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
    throw new Error(`Firestore write failed: ${err}`);
  }
}

async function getEventPlannerId(
  accessToken: string,
  eventId: string
): Promise<string | null> {
  const docPath = `projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/events/${eventId}`;
  const url = `https://firestore.googleapis.com/v1/${docPath}`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    if (res.status === 404) return null;
    const err = await res.text();
    throw new Error(`Firestore read failed: ${err}`);
  }

  const data = (await res.json()) as {
    fields?: { plannerId?: { stringValue?: string } };
  };
  const plannerId = data.fields?.plannerId?.stringValue;
  return plannerId ?? null;
}

async function removeAcceptedEventId(
  accessToken: string,
  creativeId: string,
  eventId: string
): Promise<void> {
  const docPath = `projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${creativeId}/accepted_event_ids/${eventId}`;
  const url = `https://firestore.googleapis.com/v1/${docPath}`;

  const res = await fetch(url, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!res.ok && res.status !== 404) {
    const err = await res.text();
    throw new Error(`Firestore delete failed: ${err}`);
  }
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
    creativeId?: string;
    eventId?: string;
    action?: "add" | "remove";
  };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const creativeId = body.creativeId;
  const eventId = body.eventId;
  const action = body.action ?? "add";

  if (!creativeId || !eventId) {
    return Response.json(
      { error: "creativeId and eventId are required" },
      { status: 400 }
    );
  }

  if (action !== "add" && action !== "remove") {
    return Response.json(
      { error: "action must be 'add' or 'remove'" },
      { status: 400 }
    );
  }

  try {
    const accessToken = await getGoogleAccessToken();

    const plannerId = await getEventPlannerId(accessToken, eventId);
    if (!plannerId) {
      return Response.json(
        { error: "Event not found" },
        { status: 404 }
      );
    }
    if (plannerId !== uid) {
      return Response.json(
        { error: "Only the event planner can modify accepted creatives" },
        { status: 403 }
      );
    }

    if (action === "add") {
      await addAcceptedEventId(accessToken, creativeId, eventId);
    } else {
      await removeAcceptedEventId(accessToken, creativeId, eventId);
    }

    return new Response(
      JSON.stringify({ ok: true, action }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (e) {
    console.error("sync-accepted-event-id error:", e);
    return Response.json(
      { error: e instanceof Error ? e.message : "Internal error" },
      { status: 500 }
    );
  }
});
