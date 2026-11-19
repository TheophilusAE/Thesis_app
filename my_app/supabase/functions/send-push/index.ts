// Supabase Edge Function: send-push
//
// Called by a Database Webhook on INSERT into public.notifications. Sends a
// Firebase Cloud Messaging (HTTP v1) push to every phone registered for the
// notification's user (public.device_tokens) and removes tokens Firebase
// reports as no longer valid.
//
// Secrets (Supabase Dashboard → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT  the full JSON of the Firebase service-account key
//   PUSH_WEBHOOK_SECRET       any long random text; the webhook sends it in the
//                             "x-webhook-secret" header
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.
//
// The service-account key never leaves the server: the app only registers
// its token and receives pushes.

import { createClient } from "jsr:@supabase/supabase-js@2";

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

let cachedToken: { value: string; expiresAt: number } | null = null;

function base64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out.buffer;
}

/** OAuth access token for FCM, signed with the service-account key (cached ~1 h). */
async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const enc = new TextEncoder();
  const header = base64url(enc.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64url(enc.encode(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(`${header}.${claims}`)),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${base64url(signature)}`,
    }),
  });
  if (!res.ok) throw new Error(`Google OAuth failed: ${res.status} ${await res.text()}`);
  const json = await res.json();
  cachedToken = { value: json.access_token, expiresAt: now + (json.expires_in ?? 3600) };
  return cachedToken.value;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (!secret || req.headers.get("x-webhook-secret") !== secret) {
    return json({ error: "unauthorized" }, 401);
  }

  const rawSa = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!rawSa) return json({ error: "FIREBASE_SERVICE_ACCOUNT secret is not set" }, 500);
  const sa = JSON.parse(rawSa) as ServiceAccount;

  const payload = await req.json().catch(() => null);
  const n = payload?.record;
  if (payload?.type !== "INSERT" || !n?.user_id || !n?.title) {
    return json({ skipped: true });
  }

  const { data: tokens, error } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", n.user_id);
  if (error) return json({ error: error.message }, 500);
  if (!tokens?.length) return json({ sent: 0, reason: "no device registered" });

  const auth = await accessToken(sa);
  let sent = 0;
  const removed: string[] = [];

  for (const { token } of tokens) {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${auth}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: n.title, body: n.message ?? "" },
          // All data values must be strings.
          data: {
            notification_id: String(n.id ?? ""),
            route: String(n.route ?? ""),
            category: String(n.category ?? ""),
            title: String(n.title),
            body: String(n.message ?? ""),
          },
          android: { priority: "HIGH", notification: { channel_id: "church_notifications" } },
        },
      }),
    });
    if (res.ok) {
      sent++;
      continue;
    }
    const text = await res.text();
    // The phone uninstalled the app or the token expired: forget it.
    if (res.status === 404 || text.includes("UNREGISTERED") || text.includes("registration-token-not-registered")) {
      removed.push(token);
    } else {
      console.error(`FCM send failed (${res.status}): ${text}`);
    }
  }

  if (removed.length) await supabase.from("device_tokens").delete().in("token", removed);
  return json({ sent, removed: removed.length });
});
