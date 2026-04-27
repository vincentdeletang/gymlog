insert into cardio_block_logs (session_id, cardio_block_id, completed_at)
select ws.id, cb.id, coalesce(ws.completed_at, ws.session_date::timestamptz)
from workout_sessions ws
join cardio_blocks cb on cb.program_day_id = ws.program_day_id
where ws.completed = true
on conflict (session_id, cardio_block_id) do nothing;
