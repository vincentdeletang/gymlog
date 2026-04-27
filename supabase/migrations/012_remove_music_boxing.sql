DO $$
DECLARE d_mardi UUID;
BEGIN
  SELECT pd.id INTO d_mardi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=2;

  DELETE FROM cardio_blocks WHERE program_day_id=d_mardi AND name='Music Boxing';
  UPDATE cardio_blocks SET order_index=1 WHERE program_day_id=d_mardi AND name='Sac de boxe';
END $$;
