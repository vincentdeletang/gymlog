alter table exercises add column if not exists muscle_group text;

-- Best-effort backfill for the "main" section based on exercise names.
-- Rehab/cooldown/mobility intentionally left null (not counted for hypertrophy volume).

update exercises set muscle_group = 'back'
  where section = 'main' and (name ilike '%rowing%');

update exercises set muscle_group = 'biceps'
  where section = 'main' and name ilike 'curl%';

update exercises set muscle_group = 'chest'
  where section = 'main' and name ilike '%développé%';

update exercises set muscle_group = 'triceps'
  where section = 'main' and (name ilike '%triceps%' or name ilike '%kickback%');

update exercises set muscle_group = 'quads'
  where section = 'main' and (name ilike '%squat%' or name ilike '%fente%');

update exercises set muscle_group = 'hamstrings'
  where section = 'main' and name ilike '%soulevé de terre%';

update exercises set muscle_group = 'core'
  where section = 'main' and (name ilike '%plank%' or name ilike '%dead bug%');
