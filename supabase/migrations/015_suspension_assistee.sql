DO $$
BEGIN
  UPDATE exercises
     SET notes='Pieds au sol ou genoux en appui sur un banc pour décharger le grip. Corps relâché, suspension depuis les épaules (scapular hang léger, pas dead hang passif). 30s continus.'
   WHERE name='Suspension barre fixe'
     AND section='cooldown'
     AND program_day_id IN (
       SELECT pd.id FROM program_days pd
       JOIN programs p ON p.id=pd.program_id
       WHERE p.is_active=true AND pd.day_of_week IN (1, 3, 5)
     );
END $$;
