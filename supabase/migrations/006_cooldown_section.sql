-- Ajout de la section 'cooldown' (après séance, tap-to-log comme rehab)
-- Conversion des "Suspension barre fixe" de rehab → cooldown

ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_section_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_section_check
  CHECK (section IN ('main', 'rehab', 'cardio', 'cooldown'));

UPDATE exercises SET section = 'cooldown' WHERE name = 'Suspension barre fixe';
