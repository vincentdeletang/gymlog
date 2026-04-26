create table if not exists bodyweight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null default current_date,
  weight_kg decimal(5,1) not null check (weight_kg > 0 and weight_kg < 500),
  notes text,
  created_at timestamptz default now(),
  unique (user_id, log_date)
);

create index if not exists idx_bodyweight_logs_user_date
  on bodyweight_logs (user_id, log_date desc);

alter table bodyweight_logs enable row level security;

create policy "Users own their bodyweight_logs"
  on bodyweight_logs for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
