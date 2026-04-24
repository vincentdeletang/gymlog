create table if not exists cardio_block_logs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references workout_sessions(id) on delete cascade,
  cardio_block_id uuid references cardio_blocks(id) on delete cascade,
  completed_at timestamptz default now(),
  unique (session_id, cardio_block_id)
);

alter table cardio_block_logs enable row level security;

create policy "Users own their cardio_block_logs"
  on cardio_block_logs for all to authenticated
  using (
    exists (
      select 1 from workout_sessions ws
      where ws.id = cardio_block_logs.session_id and ws.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from workout_sessions ws
      where ws.id = cardio_block_logs.session_id and ws.user_id = auth.uid()
    )
  );
