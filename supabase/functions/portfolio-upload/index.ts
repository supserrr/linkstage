import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "linkstage-rw";
const JWKS_URL = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}/.well-known/jwks.json`;

async function verifyFirebaseToken(token: string): Promise<string | null> {
  try {
    const jwks = jose.createRemoteJWKSet(new URL(JWKS_URL));
    const { payload } = await jose.jwtVerify(token, jwks);
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

  const contentType = req.headers.get("Content-Type") ?? "";
  if (!contentType.includes("multipart/form-data")) {
    return Response.json({ error: "Expected multipart/form-data" }, { status: 400 });
  }

  const formData = await req.formData();
  const file = formData.get("file") as File | null;
  const type = (formData.get("type") as string | null) ?? "portfolio";
  const isVideo = formData.get("isVideo") === "true";

  if (!file) {
    return Response.json({ error: "Missing file" }, { status: 400 });
  }

  let path: string;
  if (type === "profile") {
    const ext = file.name.split(".").pop() ?? "jpg";
    path = `users/${uid}/profile/avatar.${ext}`;
  } else {
    const ext = file.name.split(".").pop() ?? (isVideo ? "mp4" : "jpg");
    const subfolder = isVideo ? "videos" : "images";
    path = `users/${uid}/portfolio/${subfolder}/${Date.now()}.${ext}`;
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const bytes = await file.arrayBuffer();
  const { error } = await supabase.storage
    .from("portfolio")
    .upload(path, new Uint8Array(bytes), { upsert: true });

  if (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }

  const { data: urlData } = supabase.storage.from("portfolio").getPublicUrl(path);

  return new Response(
    JSON.stringify({ url: urlData.publicUrl }),
    {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    }
  );
});
