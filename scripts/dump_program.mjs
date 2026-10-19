// Dump lecture seule du programme actif : jours, exos (avec dernière charge loguée), blocs cardio.
//   node scripts/dump_program.mjs
import { makeClient } from './db.mjs'
const c = makeClient(); await c.connect()
const { rows: cols } = await c.query(`select table_name, column_name, data_type from information_schema.columns where table_schema='public' and table_name in ('exercises','cardio_blocks','program_days','programs','bars') order by table_name, ordinal_position`)
console.log('COLS', JSON.stringify(cols.map(r=>`${r.table_name}.${r.column_name}:${r.data_type}`)))
const { rows: progs } = await c.query(`select id,name,is_active,created_at from programs order by created_at`)
console.log('PROGRAMS', JSON.stringify(progs))
const { rows: bars } = await c.query(`select id,name,weight_kg from bars order by weight_kg`)
console.log('BARS', JSON.stringify(bars))
const { rows: days } = await c.query(`select pd.* from program_days pd join programs p on p.id=pd.program_id where p.is_active order by day_of_week`)
for (const d of days) {
  console.log(`\n=== DAY ${d.day_of_week} ${d.name ?? ''} ${JSON.stringify(d)}`)
  const { rows: ex } = await c.query(`select e.*, b.name as bar_name, b.weight_kg as bar_kg,
     (select count(*) from set_logs s where s.exercise_id=e.id) as nlogs,
     (select json_agg(json_build_object('d',s.logged_at::date,'w',s.weight_kg,'r',s.reps_done,'rir',s.rir) order by s.logged_at desc) from (select * from set_logs s where s.exercise_id=e.id order by s.logged_at desc limit 4) s) as last
     from exercises e left join bars b on b.id=e.bar_id where e.program_day_id=$1 order by e.order_index`, [d.id])
  for (const e of ex) { const {id,program_day_id,bar_id,...rest}=e; console.log(JSON.stringify(rest)) }
  const { rows: cb } = await c.query(`select * from cardio_blocks where program_day_id=$1 order by order_index`, [d.id])
  for (const b of cb) { const {id,program_day_id,...rest}=b; console.log('CARDIO', JSON.stringify(rest)) }
}
await c.end()
