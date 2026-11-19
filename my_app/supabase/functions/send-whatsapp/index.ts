// Supabase Edge Function: send-whatsapp — PREPARED, NOT ACTIVE.
//
// Sends an approved WhatsApp template message through the official WhatsApp
// Cloud API (Meta Graph API) to church members who opted in
// (users.whatsapp_opt_in). Every attempt is logged in
// public.whatsapp_messages (migration_whatsapp_v1.sql).
//
// It refuses to send until the church has a verified Meta Business account,
// a WhatsApp Business phone number and approved templates, and the secret
// WHATSAPP_ENABLED is set to "true". See docs/whatsapp.md.
//
// Request (POST, called from the app with the signed-in user's JWT):
//   { "template": "pengumuman_umum", "language": "id",
//     "params": ["Ibadah Raya", "Minggu 07:00"],
//     "user_ids": ["<uuid>", ...] }
// The caller must hold notifikasi:create (checked with their own JWT).
//
// Secrets (Supabase Dashboard → Edge Functions → Secrets):
//   WHATSAPP_ENABLED          "true" to allow sending (anything else = off)
//   WHATSAPP_TOKEN            permanent System User access token from Meta
//   WHATSAPP_PHONE_NUMBER_ID  the WhatsApp Business phone number ID
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided
// by Supabase. No WhatsApp credential is ever in the app or the repo.

import { createClient } from "jsr:@supabase/supabase-js@2";

const GRAPH_VERSION = "v21.0";
const MAX_RECIPIENTS = 200;

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

/** Indonesian numbers to WhatsApp's international format: 0812… → 62812…; null if not plausible. */
export function toInternational(phone: string | null | undefined): string | null {
  if (!phone) return null;
  let d = phone.replace(/[^\d+]/g, "");
  if (d.startsWith("+")) d = d.slice(1);
  if (d.startsWith("0")) d = "62" + d.slice(1);
  if (d.startsWith("8")) d = "62" + d;
  return /^62\d{8,13}$/.test(d) ? d : null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  // 1. Caller must be a signed-in user with notifikasi:create.
  const authHeader = req.headers.get("Authorization") ?? "";
  const caller = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: who } = await caller.auth.getUser();
  if (!who?.user) return json({ error: "unauthorized" }, 401);
  const { data: allowed, error: permError } = await caller.rpc("has_permission", {
    p_module: "notifikasi",
    p_action: "create",
  });
  if (permError || allowed !== true) return json({ error: "forbidden" }, 403);

  // 2. Validate the request.
  const body = await req.json().catch(() => null);
  const template = typeof body?.template === "string" ? body.template.trim() : "";
  const language = typeof body?.language === "string" ? body.language : "id";
  const params: string[] = Array.isArray(body?.params) ? body.params.map((p: unknown) => String(p)) : [];
  const userIds: string[] = Array.isArray(body?.user_ids) ? body.user_ids.slice(0, MAX_RECIPIENTS) : [];
  if (!/^[a-z0-9_]{1,512}$/.test(template) || userIds.length === 0) {
    return json({ error: "template (lowercase name) and user_ids are required" }, 400);
  }

  // 3. Recipients: only members who opted in and have a usable number.
  const { data: users, error: usersError } = await admin
    .from("users")
    .select("id, phone, whatsapp_opt_in")
    .in("id", userIds);
  if (usersError) return json({ error: usersError.message }, 500);

  const enabled = Deno.env.get("WHATSAPP_ENABLED") === "true";
  const token = Deno.env.get("WHATSAPP_TOKEN");
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  const active = enabled && !!token && !!phoneNumberId;

  const log: Record<string, unknown>[] = [];
  let sent = 0;
  for (const u of users ?? []) {
    const to = toInternational(u.phone);
    const base = {
      user_id: u.id,
      to_phone: to ?? String(u.phone ?? ""),
      template_name: template,
      template_language: language,
      params,
      created_by: who.user.id,
    };
    if (!u.whatsapp_opt_in || !to) {
      log.push({ ...base, status: "skipped", error: !to ? "nomor tidak valid" : "belum opt-in" });
      continue;
    }
    if (!active) {
      log.push({ ...base, status: "disabled", error: "WhatsApp belum diaktifkan" });
      continue;
    }
    const res = await fetch(`https://graph.facebook.com/${GRAPH_VERSION}/${phoneNumberId}/messages`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "template",
        template: {
          name: template,
          language: { code: language },
          components: params.length
            ? [{ type: "body", parameters: params.map((text) => ({ type: "text", text })) }]
            : [],
        },
      }),
    });
    const result = await res.json().catch(() => ({}));
    if (res.ok) {
      sent++;
      log.push({ ...base, status: "sent", provider_message_id: result?.messages?.[0]?.id ?? null });
    } else {
      log.push({ ...base, status: "failed", error: JSON.stringify(result?.error ?? result).slice(0, 500) });
    }
  }

  if (log.length) await admin.from("whatsapp_messages").insert(log);
  if (!active) {
    return json({ enabled: false, sent: 0, logged: log.length, reason: "WhatsApp belum diaktifkan" }, 503);
  }
  return json({ enabled: true, sent, logged: log.length });
});
