-- Equipment (bars) lookup table + FK on exercises
-- Replaces 002_add_bar_weight.sql — do NOT run 002

CREATE TABLE IF NOT EXISTS bars (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  weight_kg  DECIMAL(5,2) NOT NULL
);

-- Clean up 002 if it was accidentally applied
ALTER TABLE exercises DROP COLUMN IF EXISTS bar_weight_kg;

-- FK: each exercise optionally references a bar
ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS bar_id UUID REFERENCES bars(id) ON DELETE SET NULL;
