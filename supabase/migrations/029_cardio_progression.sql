-- ============================================================
-- Migration 029 — Cardio progression (overload progressif)
-- ============================================================
-- Mirroring de la double progression poids (lib/progression.js) appliquée à
-- la durée cardio. Pour la perte de gras (priorité #1) le levier sûr à 136kg
-- est la durée, pas la vitesse/incline (charge articulaire). On stocke un
-- plafond par bloc et un pas d'augmentation. La logique de suggestion (lib/
-- cardioProgression.js) bump le target si les 2 dernières séances ont été
-- complétées au target courant, plafonné à duration_target_max_minutes.
--
-- Targets initiaux mis à jour pour aligner sur la pratique réelle :
--   - Tapis incliné lun/ven : 20-25 → 35 (post-muscu allongé)
--   - Tapis 3% mer : 30 → 35 (asymétrie post-lower, plafond plus bas)
--   - Vélo Z2 mardi : 50 → 40 (alignement réalité, vrai stimulus dans la durée)
--   - Boxe jeudi & Vélo Z4 : inchangés sur target, plafonds ajoutés

ALTER TABLE cardio_blocks
  ADD COLUMN IF NOT EXISTS duration_target_max_minutes int,
  ADD COLUMN IF NOT EXISTS progression_step_minutes int NOT NULL DEFAULT 2;

DO $$
DECLARE
  d_lundi    UUID;
  d_mardi    UUID;
  d_mercredi UUID;
  d_jeudi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_mardi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=2;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT pd.id INTO d_jeudi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=4;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  -- Lundi tapis incliné : 20 → 35, plafond 50
  UPDATE cardio_blocks
     SET duration_minutes = 35, duration_target_max_minutes = 50
   WHERE program_day_id = d_lundi AND name = 'Tapis incliné';

  -- Mercredi tapis 3% : 30 → 35, plafond 45 (asymétrie post-lower)
  UPDATE cardio_blocks
     SET duration_minutes = 35, duration_target_max_minutes = 45
   WHERE program_day_id = d_mercredi AND name = 'Tapis 3%';

  -- Vendredi tapis incliné : 25 → 35, plafond 50
  UPDATE cardio_blocks
     SET duration_minutes = 35, duration_target_max_minutes = 50
   WHERE program_day_id = d_vendredi AND name = 'Tapis incliné';

  -- Mardi vélo Z2 : 50 → 40 (alignement pratique réelle), plafond 50
  UPDATE cardio_blocks
     SET duration_minutes = 40, duration_target_max_minutes = 50
   WHERE program_day_id = d_mardi AND name = 'Zone 2 (FC 120-140)';

  -- Mardi vélo Z4 : plafond 15
  UPDATE cardio_blocks
     SET duration_target_max_minutes = 15
   WHERE program_day_id = d_mardi AND name = 'Zone 4 (FC 160-175)';

  -- Jeudi sac de boxe : plafond 30
  UPDATE cardio_blocks
     SET duration_target_max_minutes = 30
   WHERE program_day_id = d_jeudi AND name = 'Sac de boxe';
END $$;
