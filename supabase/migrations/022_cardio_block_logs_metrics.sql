alter table cardio_block_logs
  add column if not exists duration_seconds int,
  add column if not exists avg_hr int check (avg_hr is null or (avg_hr between 40 and 250)),
  add column if not exists notes text;
