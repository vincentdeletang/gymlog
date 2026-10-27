// Déclenche la sauvegarde mensuelle à la main, exactement comme le cron (pg_net + Vault),
// puis lit la réponse HTTP. Usage : node scripts/trigger_backup.mjs
import { makeClient } from './db.mjs'

const client = makeClient()
await client.connect()
const { rows: [{ id }] } = await client.query(`
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'gymlog_backup_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'gymlog_service_role_key')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  ) as id`)
console.log('requête pg_net', id)
let res
for (let i = 0; i < 20 && !res; i++) {
  await new Promise(r => setTimeout(r, 3000))
  const { rows } = await client.query('select status_code, content, error_msg from net._http_response where id = $1', [id])
  res = rows[0]
}
console.log(res ? `${res.status_code} ${String(res.content).slice(0, 300)} ${res.error_msg ?? ''}` : 'pas de réponse après 60 s')
await client.end()
