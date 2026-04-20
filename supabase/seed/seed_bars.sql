-- Seed equipment bars + auto-assign to exercises
-- Run AFTER migration 003 and seed_program.sql

INSERT INTO bars (name, weight_kg) VALUES
  ('Barre droite', 10),
  ('Barre EZ',      6),
  ('Haltère',       2.5);

DO $$
DECLARE
  bar_ez      UUID;
  bar_droite  UUID;
  bar_haltere UUID;
BEGIN
  SELECT id INTO bar_ez      FROM bars WHERE name = 'Barre EZ';
  SELECT id INTO bar_droite  FROM bars WHERE name = 'Barre droite';
  SELECT id INTO bar_haltere FROM bars WHERE name = 'Haltère';

  -- EZ bar: "Curl barre EZ (supination)", "Extensions triceps barre EZ"
  UPDATE exercises SET bar_id = bar_ez
  WHERE name ILIKE '%EZ%' AND NOT is_bodyweight;

  -- Straight bar: "Hip thrust (barre sur banc)", "Mollets debout (barre)"
  UPDATE exercises SET bar_id = bar_droite
  WHERE name ILIKE '%barre%' AND name NOT ILIKE '%EZ%' AND NOT is_bodyweight;

  -- Dumbbells: all exercises containing "haltère" / "haltères"
  UPDATE exercises SET bar_id = bar_haltere
  WHERE (name ILIKE '%haltère%' OR name ILIKE '%haltères%') AND NOT is_bodyweight;
END $$;
