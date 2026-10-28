-- Migration 070 : retrait du rowing landmine (059), le dossier tirage est clos pour de bon
--
-- Le user (28/10/2026) : « jlai meme pas tenté en fait, rien que le setup me fait chier à mettre
-- en place ». Jamais fait, 0 set_logs. Critère de la 059 atteint par un autre chemin : un exo
-- dont le setup bloque avant la 1re série ne sera jamais fait. Plus de 6e variante : le dos reste
-- le trou connu et accepté (setup-sport.md dans FDR).
--
-- DELETE de la ligne (aucun log à sauvegarder), barre au front et curl assis remontent en 1 et 2.

DO $$
DECLARE
  d_mer UUID;
BEGIN
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;

  DELETE FROM set_logs WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id = d_mer AND name LIKE 'Rowing landmine%');
  DELETE FROM exercises WHERE program_day_id = d_mer AND name LIKE 'Rowing landmine%';

  UPDATE exercises SET order_index = 1 WHERE program_day_id = d_mer AND name = 'Barre au front';
  UPDATE exercises SET order_index = 2 WHERE program_day_id = d_mer AND name = 'Curl haltère assis (supination)';
END $$;
