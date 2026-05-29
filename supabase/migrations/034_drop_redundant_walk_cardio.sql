-- Migration 034 : Suppression du cardio "marche" redondant avec la marche bureau (NEAT)
--
-- Contexte : le user ajoute une marche quotidienne devant l'ordi (~1h30-2h/jour) comme
-- moteur principal de la perte de gras (priorité #1). À 136 kg c'est ~250-350 kcal/h,
-- soit plus que tout le cardio structuré de la semaine réuni, sans friction ni pic de faim.
-- Le cardio "perte de gras" en steady-state devient donc redondant ET nuit à l'adhérence
-- (séances de muscu rallongées, faim post-cardio → compensation calorique).
--
-- DROPS (4 blocs cardio "marche") :
--   - LUNDI    "Tapis incliné" 20'  : NEAT post-muscu, couvert par la marche bureau.
--   - MERCREDI "Tapis 3%"      30'  : idem.
--   - VENDREDI "Tapis incliné" 25'  : idem.
--   - SAMEDI   "Marche tapis"  35'  : littéralement la même chose que la marche bureau.
--
-- GARDÉS (cardio "plaisir" + intensité cœur/longévité, objectif #2) :
--   - MARDI "Sac de boxe" 25' : modalité tolérée + un peu d'intensité.
--   - JEUDI vélo Zone 2 (50') + Zone 4 (10') : conservé tel quel — le user aime le vélo.
--
-- Les cardio_block_logs sont supprimés en cascade (FK on delete cascade).

DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
  d_samedi   UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT pd.id INTO d_samedi   FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=6;

  DELETE FROM cardio_blocks WHERE program_day_id = d_lundi    AND name = 'Tapis incliné';
  DELETE FROM cardio_blocks WHERE program_day_id = d_mercredi AND name = 'Tapis 3%';
  DELETE FROM cardio_blocks WHERE program_day_id = d_vendredi AND name = 'Tapis incliné';
  DELETE FROM cardio_blocks WHERE program_day_id = d_samedi   AND name = 'Marche tapis';
END $$;
