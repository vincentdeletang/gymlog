-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ============================================================
-- TABLES
-- ============================================================

create table if not exists programs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists program_days (
  id uuid primary key default gen_random_uuid(),
  program_id uuid references programs(id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6),
  name text not null,
  type text not null check (type in ('strength', 'cardio', 'rest')),
  xp_reward int default 0,
  notes text
);

create table if not exists exercises (
  id uuid primary key default gen_random_uuid(),
  program_day_id uuid references program_days(id) on delete cascade,
  name text not null,
  order_index int not null default 0,
  sets_target int not null default 3,
  reps_target text default '10',
  is_bodyweight boolean default false,
  notes text,
  section text not null default 'main' check (section in ('main', 'rehab', 'cardio'))
);

create table if not exists cardio_blocks (
  id uuid primary key default gen_random_uuid(),
  program_day_id uuid references program_days(id) on delete cascade,
  name text not null,
  duration_minutes int not null default 20,
  order_index int not null default 0,
  notes text
);

create table if not exists workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  program_day_id uuid references program_days(id),
  session_date date not null default current_date,
  completed boolean default false,
  completed_at timestamptz,
  cardio_duration_seconds int,
  notes text,
  created_at timestamptz default now()
);

create table if not exists set_logs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references workout_sessions(id) on delete cascade,
  exercise_id uuid references exercises(id),
  set_number int not null,
  weight_kg decimal,
  reps_done int,
  rir int check (rir between 0 and 10),
  logged_at timestamptz default now()
);

create table if not exists user_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete cascade,
  xp_total int default 0,
  streak_current int default 0,
  streak_best int default 0,
  last_session_date date,
  level int default 1,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table programs enable row level security;
alter table program_days enable row level security;
alter table exercises enable row level security;
alter table cardio_blocks enable row level security;
alter table workout_sessions enable row level security;
alter table set_logs enable row level security;
alter table user_state enable row level security;

-- Programs and program structure: readable by all authenticated users (shared programs)
create policy "Authenticated users can read programs"
  on programs for select to authenticated using (true);

create policy "Authenticated users can read program_days"
  on program_days for select to authenticated using (true);

create policy "Authenticated users can read exercises"
  on exercises for select to authenticated using (true);

create policy "Authenticated users can read cardio_blocks"
  on cardio_blocks for select to authenticated using (true);

-- Workout sessions: user owns their data
create policy "Users own their workout_sessions"
  on workout_sessions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Set logs: user owns their data (via session ownership)
create policy "Users own their set_logs"
  on set_logs for all to authenticated
  using (
    exists (
      select 1 from workout_sessions ws
      where ws.id = set_logs.session_id and ws.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from workout_sessions ws
      where ws.id = set_logs.session_id and ws.user_id = auth.uid()
    )
  );

-- User state: user owns their own row
create policy "Users own their user_state"
  on user_state for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- FUNCTION: upsert user_state on first login
-- ============================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.user_state (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
