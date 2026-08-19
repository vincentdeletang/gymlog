// Applique les migrations 045 + 046 via le client Supabase authentifié (pas de service_role
// ni de DDL nécessaire : ce sont des UPDATE sur `exercises` + un DELETE sur `set_logs`).
//
//   node scripts/apply_045_046.mjs
//
// Idempotent : relancer le script ne fait rien de plus une fois les migrations passées.

import { createClient } from '@supabase/supabase-js'
import fs from 'fs'

const env = Object.fromEntries(
  fs.readFileSync('.env', 'utf8').split('\n')
    .filter(l => l.includes('=') && !l.trimStart().startsWith('#'))
    .map(l => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()])
)

const sb = createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY)
const { error: authErr } = await sb.auth.signInWithPassword({
  email: env.GYMLOG_EMAIL, password: env.GYMLOG_PASSWORD,
})
if (authErr) { console.error('AUTH FAIL:', authErr.message); process.exit(1) }

const { data: prog } = await sb.from('programs').select('id').eq('is_active', true).single()
const { data: day } = await sb.from('program_days').select('id')
  .eq('program_id', prog.id).eq('day_of_week', 3).single()
const { data: bar } = await sb.from('bars').select('id').eq('name', 'Barre droite').single()

const { data: exos } = await sb.from('exercises').select('id,name').eq('program_day_id', day.id)
const goblet = exos.find(e => e.name === 'Goblet squat')
const sldl = exos.find(e => e.name === 'Soulevé de terre jambes tendues (barre)')

// ---- 046 : SLDL, butée au genou ----
const sldlNotes = "Barres de sécurité à hauteur de GENOU = butée : tu descends jusqu'à toucher, jamais plus bas. "
  + "Barre désenquillée à hauteur de hanche, pas de ramassage au sol. "
  + "Mouvement de hanche (fesses vers l'arrière), dos plat, jambes quasi tendues."

const { error: e046 } = await sb.from('exercises').update({ notes: sldlNotes }).eq('id', sldl.id)
console.log('046 SLDL butée genou :', e046 ? 'FAIL ' + e046.message : 'OK')

// ---- 045 : goblet -> front squat ----
if (!goblet) {
  console.log('045 : déjà appliquée (pas de Goblet squat)')
} else {
  const { data: logs, error: eBk } = await sb.from('set_logs').select('*')
    .eq('exercise_id', goblet.id).order('logged_at')
  if (eBk) { console.error('BACKUP FAIL:', eBk.message); process.exit(1) }
  fs.mkdirSync('supabase/backups', { recursive: true })
  fs.writeFileSync('supabase/backups/goblet_squat_set_logs.json', JSON.stringify(logs, null, 2))
  console.log(`045 backup : ${logs.length} set_logs -> supabase/backups/goblet_squat_set_logs.json`)

  const { error: eDel } = await sb.from('set_logs').delete().eq('exercise_id', goblet.id)
  const { count } = await sb.from('set_logs').select('id', { count: 'exact', head: true })
    .eq('exercise_id', goblet.id)
  console.log('045 purge set_logs :', eDel ? 'FAIL ' + eDel.message : `OK (restant ${count})`)
  if (eDel || count > 0) { console.error('Purge incomplète — on s\'arrête avant de renommer.'); process.exit(1) }

  const frontNotes = "Barre sur les deltoïdes avant, prise BRAS CROISÉS (jamais prise olympique). "
    + "Supports à hauteur d'épaule pour désenquiller, barres de sécurité en position basse = bail-out. "
    + "Coudes hauts, torse vertical, descente jusqu'à parallèle (cuisses //sol). "
    + "Repars léger : 20-30 kg barre comprise le temps de caler la position."

  const { error: e045 } = await sb.from('exercises').update({
    name: 'Front squat (barre)',
    notes: frontNotes,
    bar_id: bar.id,
    sets_target: 3,
    reps_target: '8',
    is_bodyweight: false,
    muscle_group: 'quads',
    progression_mode: 'weight',
  }).eq('id', goblet.id)
  console.log('045 goblet -> front squat :', e045 ? 'FAIL ' + e045.message : 'OK')
}

// ---- Vérification ----
const { data: final } = await sb.from('exercises')
  .select('name,order_index,sets_target,reps_target,section')
  .eq('program_day_id', day.id).order('order_index')
console.log('\n--- MERCREDI ---')
for (const e of final) console.log(` ${e.order_index} [${e.section}] ${e.name} — ${e.sets_target}×${e.reps_target}`)
