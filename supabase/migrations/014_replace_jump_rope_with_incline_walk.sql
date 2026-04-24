DO $$
DECLARE
  d_lundi UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE cardio_blocks
     SET name='Tapis incliné',
         duration_minutes=20,
         notes='Pente 8-12%, FC cible 110-130 bpm, torse droit'
   WHERE program_day_id=d_lundi AND name='Corde à sauter';

  UPDATE cardio_blocks
     SET name='Tapis incliné',
         duration_minutes=25,
         notes='Pente 8-12%, FC cible 110-130 bpm, torse droit'
   WHERE program_day_id=d_vendredi AND name='Corde à sauter ou Tapis';
END $$;
