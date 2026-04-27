create table if not exists soreness_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null default current_date,
  body_part text not null,
  level int not null check (level between 0 and 3),
  notes text,
  created_at timestamptz default now(),
  unique (user_id, log_date, body_part)
);

create index if not exists idx_soreness_logs_user_date
  on soreness_logs (user_id, log_date desc);

alter table soreness_logs enable row level security;

create policy "Users own their soreness_logs"
  on soreness_logs for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
