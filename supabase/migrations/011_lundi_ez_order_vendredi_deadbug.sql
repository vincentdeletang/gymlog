-- Lundi : Curl barre EZ passe avant Rowing haltère unilatéral (order 7↔8)
-- Vendredi : suppression Dead bug
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  UPDATE exercises SET order_index=7 WHERE program_day_id=d_lundi AND name='Curl barre EZ (supination)';
  UPDATE exercises SET order_index=8 WHERE program_day_id=d_lundi AND name='Rowing haltère unilatéral';
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_vendredi AND name='Dead bug');

  DELETE FROM exercises WHERE program_day_id=d_vendredi AND name='Dead bug';
END $$;
