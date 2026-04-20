-- Remplace le programme Lower Body du mercredi
-- Split squat bulgare + Hip thrust retirés
-- Soulevé de terre jambes tendues ajouté en position 2
-- Notes des Fentes marchées mises à jour

DO $$
DECLARE
  day_id     UUID;
  bar_droite UUID;
BEGIN
  SELECT pd.id INTO day_id
  FROM program_days pd
  JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  SELECT id INTO bar_droite FROM bars WHERE name = 'Barre droite';

  DELETE FROM exercises
  WHERE program_day_id = day_id
    AND name IN ('Split squat bulgare', 'Hip thrust (barre sur banc)');

  UPDATE exercises SET
    order_index = 1,
    notes = 'Pas suffisamment large pour que le genou avant ne dépasse pas le pied, descente selon confort'
  WHERE program_day_id = day_id AND name = 'Fentes marchées haltères';

  INSERT INTO exercises
    (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
  VALUES
    (day_id, 'Soulevé de terre jambes tendues (barre)', 2, 3, '10-12', false,
     'Dos plat, descente contrôlée le long des jambes, étirement ischio en bas', 'main', bar_droite);

  UPDATE exercises SET order_index = 3
  WHERE program_day_id = day_id AND name = 'Mollets debout (barre)';

  UPDATE exercises SET order_index = 4
  WHERE program_day_id = day_id AND name = 'Reverse crunches';
END $$;
