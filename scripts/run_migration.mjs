// Applique un ou plusieurs fichiers de migration SQL directement sur la base Supabase.
//
//   node scripts/run_migration.mjs supabase/migrations/045_mercredi_front_squat.sql
//   node scripts/run_migration.mjs supabase/migrations/04{5,6}_*.sql
//
// Chaque fichier est exécuté dans SA PROPRE transaction : soit tout passe, soit rien.
// Nécessite GYMLOG_DB_URL dans .env (Supabase Dashboard -> Connect -> Session pooler).

import fs from 'fs'
import { makeClient } from './db.mjs'

const files = process.argv.slice(2)
if (!files.length) {
  console.error('usage: node scripts/run_migration.mjs <fichier.sql> [...]')
  process.exit(1)
}

const client = makeClient()
client.on('notice', n => console.log('   notice:', n.message))
await client.connect()
console.log('connecté')

let failed = false
for (const file of files) {
  const sql = fs.readFileSync(file, 'utf8')
  try {
    await client.query('BEGIN')
    await client.query(sql)
    await client.query('COMMIT')
    console.log(`OK   ${file}`)
  } catch (err) {
    await client.query('ROLLBACK')
    console.error(`FAIL ${file}\n     ${err.message}`)
    failed = true
    break
  }
}

await client.end()
process.exit(failed ? 1 : 0)
