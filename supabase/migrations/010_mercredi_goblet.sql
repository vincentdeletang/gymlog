-- Mercredi : ajout Goblet squat, fentes 4→3, suppression mollets
DO $$
DECLARE d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=3;

  -- Décaler fentes + SLDL pour insérer goblet squat en order 1
  UPDATE exercises SET order_index=order_index+1
  WHERE program_day_id=d_mercredi AND order_index BETWEEN 1 AND 2;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_mercredi, 'Goblet squat', 1, 3, '8', false,
    'Haltère tenu vertical devant la poitrine, descente profonde, genoux dans l''axe des pieds, torse vertical — charge axiale pour la densité osseuse',
    'main'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Goblet squat');

  UPDATE exercises SET bar_id=(SELECT id FROM bars WHERE name='Haltère')
  WHERE program_day_id=d_mercredi AND name='Goblet squat';

  UPDATE exercises SET sets_target=3
  WHERE program_day_id=d_mercredi AND name='Fentes marchées haltères';

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_mercredi AND name='Mollets debout (barre)');

  DELETE FROM exercises WHERE program_day_id=d_mercredi AND name='Mollets debout (barre)';
END $$;
