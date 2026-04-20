-- Ajout Dead bug en début de séance mercredi (activation lombaires avant SDT/fentes)
-- 2x8/côté, order_index 0 pour apparaître en premier

DO $$
DECLARE
  d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  VALUES (d_mercredi, 'Dead bug', 0, 2, '8/côté', true,
    'Activation lombaires avant le travail lourd — allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent',
    'main');
END $$;
