-- Mercredi : ajout Dead bug (activation avant SDT) + suppression Reverse crunches

DO $$
DECLARE
  d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  -- Ajout Dead bug en order 0 (avant les fentes)
  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_mercredi, 'Dead bug', 0, 2, '8/côté', true,
    'Activation lombaires avant le travail lourd — allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent',
    'main'
  WHERE NOT EXISTS (
    SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Dead bug'
  );

  -- Suppression Reverse crunches (flexion spinale inutile avec lombaires faibles)
  -- On supprime d'abord les set_logs associés pour respecter la FK
  DELETE FROM set_logs
  WHERE exercise_id IN (
    SELECT id FROM exercises WHERE program_day_id=d_mercredi AND name='Reverse crunches'
  );

  DELETE FROM exercises WHERE program_day_id=d_mercredi AND name='Reverse crunches';
END $$;
