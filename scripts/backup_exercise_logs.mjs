// Sauvegarde les set_logs d'un exercice avant une migration destructive.
//   node scripts/backup_exercise_logs.mjs "Goblet squat"
import fs from 'fs'
import { makeClient } from './db.mjs'

const name = process.argv[2]
if (!name) { console.error('usage: node scripts/backup_exercise_logs.mjs "<nom exo>"'); process.exit(1) }

const client = makeClient()
await client.connect()

const { rows } = await client.query(`
  select sl.*, e.name as exercise_name, ws.session_date
    from set_logs sl
    join exercises e on e.id = sl.exercise_id
    left join workout_sessions ws on ws.id = sl.session_id
   where e.name = $1
   order by sl.logged_at`, [name])

const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '')
fs.mkdirSync('supabase/backups', { recursive: true })
const path = `supabase/backups/${slug}_set_logs.json`
fs.writeFileSync(path, JSON.stringify(rows, null, 2))

console.log(`${rows.length} set_logs sauvegardés -> ${path}`)
if (rows.length) {
  const last = rows[rows.length - 1]
  console.log(`dernier log : ${last.session_date ?? '?'} — ${last.weight_kg}kg × ${last.reps_done} @ RIR ${last.rir}`)
}

await client.end()
