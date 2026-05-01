-- Migration 032 : Trim final aligné objectifs + ajout marche tapis samedi
--
-- Suite à audit programme avec hiérarchie d'objectifs clarifiée (cf. CLAUDE.md) :
-- bras = seul muscle visé en hypertrophie, le reste = entretien santé/fonction.
--
-- DROPS (5 exos) — tous marginaux pour les objectifs réels du user :
--   - VENDREDI "Élévations latérales haltère" : pure esthétique (delt latéral / V-taper).
--     Profil user = naturellement large/imposant (1m97/136kg, carrure bûcheron) → ajouter
--     largeur d'épaule serait esthétiquement contre-productif. Aucun bénéfice santé/fonction.
--   - MERCREDI "Fentes marchées haltères" : redondance partielle avec goblet squat.
--     Densité osseuse + insuline + NEAT couverts par goblet + SLDL + mollets. Setup chiant
--     (2 disques + espace), donc forte friction adhérence pour gain marginal.
--   - SAMEDI "Respiration diaphragmatique" : utile mais cosmétique côté programme,
--     peut être fait n'importe quand dans la journée si besoin.
--   - SAMEDI "90/90 hip switch" : redondance partielle avec Pigeon modifié (tous deux
--     ciblent les hanches). Pigeon couvre l'essentiel.
--   - LUNDI + VENDREDI "Pendulaires de Codman" : exercice rehab passif. User ne le sent pas
--     et ça l'agace. Stretch doorway (gardé) couvre déjà l'étirement épaule G.
--     Les 2 actifs (rotations externes + face pulls) restent intacts.
--
-- ADD :
--   - SAMEDI cardio "Marche tapis" 35 min (cible 50) : NEAT structuré pour priorité #1
--     (perte de gras), zéro interférence muscu, soutenable en déficit. User préfère tapis
--     loggable à marche dehors non-loggable (= adhérence supérieure).

-- ============================================================
-- 1) DROPS (avec suppression set_logs préalable pour FK constraint)
-- ============================================================
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

  -- Suppression set_logs (détruit l'historique de ces exos)
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises WHERE
       (program_day_id = d_vendredi AND name = 'Élévations latérales haltères')
       OR (program_day_id = d_mercredi AND name = 'Fentes marchées haltères')
       OR (program_day_id = d_samedi AND name IN ('Respiration diaphragmatique', '90/90 hip switch'))
       OR (program_day_id IN (d_lundi, d_vendredi) AND name = 'Pendulaires de Codman')
   );

  -- DELETE des exos
  DELETE FROM exercises
   WHERE program_day_id = d_vendredi AND name = 'Élévations latérales haltères';

  DELETE FROM exercises
   WHERE program_day_id = d_mercredi AND name = 'Fentes marchées haltères';

  DELETE FROM exercises
   WHERE program_day_id = d_samedi AND name IN ('Respiration diaphragmatique', '90/90 hip switch');

  DELETE FROM exercises
   WHERE program_day_id IN (d_lundi, d_vendredi) AND name = 'Pendulaires de Codman';
END $$;

-- ============================================================
-- 2) ADD cardio "Marche tapis" sur samedi
-- ============================================================
DO $$
DECLARE
  d_samedi UUID;
BEGIN
  SELECT pd.id INTO d_samedi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=6;

  IF NOT EXISTS (SELECT 1 FROM cardio_blocks WHERE program_day_id=d_samedi AND name='Marche tapis') THEN
    INSERT INTO cardio_blocks (program_day_id, name, duration_minutes, duration_target_max_minutes, progression_step_minutes, order_index, notes)
    VALUES (
      d_samedi,
      'Marche tapis',
      35,
      50,
      2,
      1,
      'Récup active + NEAT structuré pour la perte de gras (priorité #1). Plat ou très légère pente (3% max). Zone 1-2 (FC ~110-120, conversation facile). Zéro stress muscu, zéro interférence avec les séances de la semaine, soutenable en déficit. Préférée à la marche dehors car loggable = adhérence supérieure.'
    );
  END IF;
END $$;
