// Connexion Postgres partagée par les scripts de migration.
//
// Parse GYMLOG_DB_URL à la main plutôt que via l'URL parser : les mots de passe Supabase
// contiennent souvent des caractères qui cassent une URL (#, /, ?, @...). On découpe sur
// le DERNIER '@' — tout ce qui précède est `user:password`, tout ce qui suit `host:port/db`.

import fs from 'fs'
import pg from 'pg'

export function readEnv() {
  return Object.fromEntries(
    fs.readFileSync('.env', 'utf8').split('\n')
      .filter(l => l.includes('=') && !l.trimStart().startsWith('#'))
      .map(l => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()])
  )
}

export function makeClient() {
  const env = readEnv()
  const raw = env.GYMLOG_DB_URL
  if (!raw) throw new Error('GYMLOG_DB_URL manquant dans .env')

  const afterScheme = raw.slice(raw.indexOf('://') + 3)
  const at = afterScheme.lastIndexOf('@')
  if (at < 0) throw new Error('GYMLOG_DB_URL : pas de "@", format inattendu')

  const auth = afterScheme.slice(0, at)
  const rest = afterScheme.slice(at + 1)
  const colon = auth.indexOf(':')
  const user = auth.slice(0, colon)
  const password = auth.slice(colon + 1)

  const slash = rest.indexOf('/')
  const hostPort = slash < 0 ? rest : rest.slice(0, slash)
  const database = slash < 0 ? 'postgres' : rest.slice(slash + 1).split('?')[0]
  const [host, port] = hostPort.split(':')

  return new pg.Client({
    user,
    password,
    host,
    port: Number(port || 5432),
    database,
    ssl: { rejectUnauthorized: false },
  })
}
