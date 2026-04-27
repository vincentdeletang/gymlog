-- Point 3 : plank déplacé en début de bloc muscu lundi (avant le travail lourd)
-- Point 4 : kickbacks 4→3 séries vendredi (volume triceps trop élevé)

DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  -- Décaler rowing + biceps (order 5-9) → 6-10 pour libérer la place
  UPDATE exercises SET order_index=order_index+1
  WHERE program_day_id=d_lundi AND section='main' AND order_index BETWEEN 5 AND 9;

  -- Plank en première position du bloc muscu
  UPDATE exercises SET order_index=5 WHERE program_day_id=d_lundi AND name='Plank';
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE exercises SET sets_target=3 WHERE program_day_id=d_vendredi AND name='Kickbacks haltères';
END $$;
