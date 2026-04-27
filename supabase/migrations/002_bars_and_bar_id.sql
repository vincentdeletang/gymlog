-- Equipment (bars) lookup table + FK on exercises

CREATE TABLE IF NOT EXISTS bars (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  weight_kg  DECIMAL(5,2) NOT NULL
);

-- FK: each exercise optionally references a bar
ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS bar_id UUID REFERENCES bars(id) ON DELETE SET NULL;

-- RLS pour bars (lecture publique comme les autres tables de programme)
ALTER TABLE bars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read bars"
  ON bars FOR SELECT TO authenticated USING (true);
