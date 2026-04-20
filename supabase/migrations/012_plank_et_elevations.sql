-- Lundi : suppression Plank
-- Vendredi : suppression Élévations latérales + ajout Plank en fin de bloc muscu
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_lundi AND name='Plank');
  DELETE FROM exercises WHERE program_day_id=d_lundi AND name='Plank';

  UPDATE exercises SET order_index=order_index-1
  WHERE program_day_id=d_lundi AND section='main' AND order_index BETWEEN 6 AND 10;
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_vendredi AND name='Élévations latérales haltères');
  DELETE FROM exercises WHERE program_day_id=d_vendredi AND name='Élévations latérales haltères';

  UPDATE exercises SET order_index=order_index-1
  WHERE program_day_id=d_vendredi AND section='main' AND order_index BETWEEN 7 AND 8;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_vendredi, 'Plank', 8, 3, '30-60s', true, null, 'main'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Plank');
END $$;
