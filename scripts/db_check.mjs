// Test de connexion + état du mercredi. Lecture seule.
//   node scripts/db_check.mjs
import { makeClient } from './db.mjs'

const client = makeClient()

try {
  await client.connect()
} catch (err) {
  console.error('CONNEXION KO:', err.message)
  process.exit(1)
}

const { rows: who } = await client.query('select current_user, version()')
console.log('user:', who[0].current_user)
console.log('pg  :', who[0].version.split(' ').slice(0, 2).join(' '))

const { rows } = await client.query(`
  select e.order_index, e.section, e.name, e.sets_target, e.reps_target,
         (select count(*) from set_logs sl where sl.exercise_id = e.id) as logs
    from exercises e
    join program_days pd on pd.id = e.program_day_id
    join programs p on p.id = pd.program_id
   where p.is_active and pd.day_of_week = 3
   order by e.order_index`)

console.log('\n--- MERCREDI ---')
for (const r of rows) {
  console.log(` ${r.order_index} [${r.section}] ${r.name} — ${r.sets_target}×${r.reps_target} (${r.logs} logs)`)
}

await client.end()
