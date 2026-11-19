// Supabase Edge Function: delete-account
//
// Lets a signed-in user permanently delete THEIR OWN account (Google Play
// account-deletion requirement). Deploy with "Verify JWT" ON: the caller is
// identified from their JWT, never from the request body, so nobody can
// delete someone else's account.
//
// Steps: 1) find the caller from the JWT, 2) delete their app data with the
// service-role-only RPC public.delete_account_data (migration_account_deletion.sql;
// refuses Super Admin), 3) delete their login (auth.users) via the Admin API.
//
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided
// by Supabase; no extra secrets. The service-role key never leaves the server.

import { createClient } from "jsr:@supabase/supabase-js@2";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const caller = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: who, error: whoError } = await caller.auth.getUser();
  if (whoError || !who?.user) return json({ error: "Sesi tidak valid. Silakan login ulang." }, 401);
  const userId = who.user.id;

  const { error: dataError } = await admin.rpc("delete_account_data", { p_user_id: userId });
  if (dataError) {
    const forbidden = dataError.code === "42501";
    console.error(`delete_account_data failed for ${userId}: ${dataError.code} ${dataError.message}`);
    return json(
      { error: forbidden ? dataError.message : "Data akun belum bisa dihapus. Hubungi admin gereja." },
      forbidden ? 403 : 500,
    );
  }

  const { error: authError } = await admin.auth.admin.deleteUser(userId);
  if (authError) {
    console.error(`auth deleteUser failed for ${userId}: ${authError.message}`);
    return json({ error: "Data aplikasi terhapus, tetapi login belum terhapus. Hubungi admin gereja." }, 500);
  }

  return json({ deleted: true });
});
