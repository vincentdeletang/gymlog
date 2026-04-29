// Supabase Edge Function — monthly-backup
// Dumps all GymLog tables to JSON and emails it as an attachment via Resend.
// Triggered monthly by pg_cron (cf. migration 028) and on demand from Settings.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const TABLES = [
  'programs',
  'program_days',
  'exercises',
  'cardio_blocks',
  'bars',
  'workout_sessions',
  'set_logs',
  'cardio_block_logs',
  'bodyweight_logs',
  'soreness_logs',
  'user_state',
] as const

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Chunked encode — avoids stack overflow with large payloads.
function toBase64(bytes: Uint8Array): string {
  let binary = ''
  const chunk = 0x8000
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk))
  }
  return btoa(binary)
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const resendKey = Deno.env.get('RESEND_API_KEY')
  const toEmail = Deno.env.get('BACKUP_TO_EMAIL')
  const fromEmail = Deno.env.get('BACKUP_FROM_EMAIL') ?? 'GymLog Backup <onboarding@resend.dev>'

  if (!resendKey || !toEmail) {
    return jsonResponse(
      { ok: false, error: 'Missing RESEND_API_KEY or BACKUP_TO_EMAIL env var' },
      500,
    )
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  })

  const data: Record<string, unknown[]> = {}
  let totalRows = 0
  for (const t of TABLES) {
    const { data: rows, error } = await supabase.from(t).select('*')
    if (error) {
      return jsonResponse(
        { ok: false, step: 'fetch', table: t, error: error.message },
        500,
      )
    }
    data[t] = rows ?? []
    totalRows += data[t].length
  }

  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  const filename = `gymlog-backup-${yyyy}-${mm}-${dd}.json`

  const json = JSON.stringify(
    {
      exported_at: now.toISOString(),
      schema_version: '028',
      total_rows: totalRows,
      tables: data,
    },
    null,
    2,
  )

  const base64 = toBase64(new TextEncoder().encode(json))
  const sizeKb = Math.round(json.length / 1024)

  const sendResp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${resendKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: fromEmail,
      to: [toEmail],
      subject: `Backup GymLog — ${yyyy}-${mm}`,
      text:
        `Backup automatique GymLog du ${yyyy}-${mm}-${dd}.\n\n` +
        `${totalRows} lignes sur ${TABLES.length} tables (${sizeKb} Ko).\n\n` +
        `Le JSON joint contient toutes tes données — sessions, sets, poids corporel, soreness, programme.\n` +
        `C'est ta sauvegarde de secours, garde ce mail.`,
      attachments: [{ filename, content: base64 }],
    }),
  })

  if (!sendResp.ok) {
    const errBody = await sendResp.text()
    return jsonResponse(
      { ok: false, step: 'send', status: sendResp.status, error: errBody },
      500,
    )
  }

  return jsonResponse({ ok: true, filename, total_rows: totalRows, size_kb: sizeKb })
})
