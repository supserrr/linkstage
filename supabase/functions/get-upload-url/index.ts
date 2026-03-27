import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "linkstage-rw";
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
    return Response.json({ error: "Missing Authorization header" }, { status: 401 });
  }

  const uid = await verifyFirebaseToken(token);
  if (!uid) {
    return Response.json({ error: "Invalid token" }, { status: 401 });
  }

  let body: { type?: string; isVideo?: boolean; fileName?: string };
  try {
    body = (await req.json()) as { type?: string; isVideo?: boolean; fileName?: string };
  } catch {
    return Response.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const type = body.type ?? "portfolio";
  const isVideo = body.isVideo === true;
  const fileName = body.fileName ?? (type === "profile" ? "avatar.jpg" : isVideo ? "file.mp4" : "file.jpg");

  let path: string;
  if (type === "profile") {
    const ext = fileName.split(".").pop() ?? "jpg";
    path = `users/${uid}/profile/avatar.${ext}`;
  } else {
    const ext = fileName.split(".").pop() ?? (isVideo ? "mp4" : "jpg");
    const subfolder = isVideo ? "videos" : "images";
    path = `users/${uid}/portfolio/${subfolder}/${Date.now()}.${ext}`;
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const upsert = type === "profile";
  const { data: signedData, error: signError } = await supabase.storage
    .from("portfolio")
    .createSignedUploadUrl(path, upsert ? { upsert: true } : undefined);

  if (signError) {
    return Response.json({ error: signError.message }, { status: 500 });
  }

  if (!signedData?.path || !signedData?.token) {
    return Response.json({ error: "Failed to create signed upload URL" }, { status: 500 });
  }

  const { data: urlData } = supabase.storage.from("portfolio").getPublicUrl(signedData.path);
  const publicUrl = urlData.publicUrl;

  return new Response(
    JSON.stringify({
      path: signedData.path,
      token: signedData.token,
      publicUrl,
    }),
    {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    }
  );
});
