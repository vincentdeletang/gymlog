-- Ajout "Suspension barre fixe" en fin de chaque séance muscu (lundi/mercredi/vendredi)
-- Section rehab = tap sans modal, bodyweight

DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
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

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) VALUES
    (d_lundi,    'Suspension barre fixe', 10, 2, '30s', true, 'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'rehab'),
    (d_mercredi, 'Suspension barre fixe',  5, 2, '30s', true, 'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'rehab'),
    (d_vendredi, 'Suspension barre fixe', 10, 2, '30s', true, 'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'rehab');
END $$;
