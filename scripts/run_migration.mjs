// Applique un ou plusieurs fichiers de migration SQL directement sur la base Supabase.
//
//   node scripts/run_migration.mjs supabase/migrations/045_mercredi_front_squat.sql
//   node scripts/run_migration.mjs supabase/migrations/0*.sql
//
// Chaque fichier est exécuté dans SA PROPRE transaction : soit tout passe, soit rien.
// Nécessite GYMLOG_DB_URL dans .env (Supabase Dashboard -> Connect -> connection string).

import fs from 'fs'
import pg from 'pg'

const env = Object.fromEntries(
  fs.readFileSync('.env', 'utf8').split('\n')
    .filter(l => l.includes('=') && !l.trimStart().startsWith('#'))
    .map(l => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()])
)

if (!env.GYMLOG_DB_URL) {
  console.error('GYMLOG_DB_URL manquant dans .env')
  process.exit(1)
}

const files = process.argv.slice(2)
if (!files.length) {
  console.error('usage: node scripts/run_migration.mjs <fichier.sql> [...]')
  process.exit(1)
}

const client = new pg.Client({
  connectionString: env.GYMLOG_DB_URL,
  ssl: { rejectUnauthorized: false },
})

await client.connect()
console.log('connecté')

let failed = false
for (const file of files) {
  const sql = fs.readFileSync(file, 'utf8')
  try {
    await client.query('BEGIN')
    const res = await client.query(sql)
    await client.query('COMMIT')
    const notices = Array.isArray(res) ? res.length : 1
    console.log(`OK  ${file} (${notices} statement(s))`)
  } catch (err) {
    await client.query('ROLLBACK')
    console.error(`FAIL ${file}\n     ${err.message}`)
    failed = true
    break
  }
}

await client.end()
process.exit(failed ? 1 : 0)
