-- Cooldown décompression : Suspension barre fixe 2×30s → 1×30-45s, ajout Genoux-poitrine 1×60s
-- L'objectif principal du hang devient l'épaule (la lombaire ne décompresse pas vraiment debout) ;
-- le genoux-poitrine prend le relais pour la déco lombaire passive.

-- 1) Réduire la Suspension à 1 série avec range 30-45s
UPDATE exercises
   SET sets_target = 1,
       reps_target = '30-45s'
 WHERE name = 'Suspension barre fixe'
   AND section = 'cooldown';

-- 2) Ajouter Genoux-poitrine en cooldown sur lundi / mercredi / vendredi, juste après la suspension
DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
  notes_text TEXT := 'Couché sur le dos, ramener les 2 genoux vers la poitrine, mains autour des tibias, relâcher complètement le bas du dos. Respiration lente.';
BEGIN
  SELECT pd.id INTO d_lundi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 1;

  SELECT pd.id INTO d_mercredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  SELECT pd.id INTO d_vendredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 5;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_lundi, 'Genoux-poitrine',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_lundi),
    1, '60s', true, notes_text, 'cooldown'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_lundi AND name = 'Genoux-poitrine');

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_mercredi, 'Genoux-poitrine',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_mercredi),
    1, '60s', true, notes_text, 'cooldown'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_mercredi AND name = 'Genoux-poitrine');

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_vendredi, 'Genoux-poitrine',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_vendredi),
    1, '60s', true, notes_text, 'cooldown'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_vendredi AND name = 'Genoux-poitrine');
END $$;
