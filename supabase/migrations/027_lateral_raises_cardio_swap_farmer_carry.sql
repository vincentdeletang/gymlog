-- 3 ajustements post-audit IA #2 :
-- 1. Ajout Élévations latérales haltères (vendredi) — comble le trou delt latéral, V-taper / focus bras
-- 2. Swap cardio mardi ↔ jeudi → boxe le jeudi (48h après upper pull, fini l'interférence), vélo le mardi
-- 3. Pallof press élastique → Farmer's carry (vendredi) — plus simple à exécuter, meilleur transfert
--    "rester droit sous charge" pour profil 136kg + lombaires faibles

-- ============================================================
-- 1) Élévations latérales haltères sur vendredi (insérées entre développé et extensions triceps)
-- ============================================================
DO $$
DECLARE
  d_vendredi  UUID;
  bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT id INTO bar_haltere FROM bars WHERE name='Haltère';

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Élévations latérales haltères') THEN
    -- Décale les exos main d'order 6+ d'un cran pour libérer l'ordre 6
    UPDATE exercises SET order_index = order_index + 1
    WHERE program_day_id = d_vendredi AND section = 'main' AND order_index >= 6;

    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
    VALUES (d_vendredi, 'Élévations latérales haltères', 6, 3, '12-15', false,
      'Haltères, mouvement latéral, jamais au-dessus de l''horizontale (épaule G). Pause brève en haut, descente contrôlée. Légère flexion du coude pour réduire stress poignet.',
      'main', bar_haltere);
  END IF;
END $$;

-- ============================================================
-- 2) Pallof press élastique → Farmer's carry (vendredi, en place)
-- ============================================================
DO $$
DECLARE
  d_vendredi  UUID;
  bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT id INTO bar_haltere FROM bars WHERE name='Haltère';

  UPDATE exercises
     SET name          = 'Farmer''s carry',
         sets_target   = 3,
         reps_target   = '20-30s',
         is_bodyweight = false,
         is_per_side   = false,
         bar_id        = bar_haltere,
         notes         = 'Haltères chargées le plus lourd possible avec posture parfaite (~30-40m de marche, soit 20-30s sous charge). Tronc gainé, scapulae rétractées, ne pas se laisser tirer en avant ni latéralement. Respiration courte et active. Repos 60-90s entre séries.'
   WHERE program_day_id = d_vendredi AND name = 'Pallof press élastique';
END $$;

-- ============================================================
-- 3) Swap cardio : boxe mardi → jeudi, vélo jeudi → mardi
-- ============================================================
DO $$
DECLARE
  d_mardi UUID;
  d_jeudi UUID;
BEGIN
  SELECT pd.id INTO d_mardi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=2;
  SELECT pd.id INTO d_jeudi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=4;

  -- Détection : ne fait le swap que si la boxe est encore sur mardi (idempotent)
  IF EXISTS (SELECT 1 FROM cardio_blocks WHERE name='Sac de boxe' AND program_day_id=d_mardi) THEN
    UPDATE cardio_blocks SET program_day_id = d_jeudi
    WHERE name = 'Sac de boxe' AND program_day_id = d_mardi;

    UPDATE cardio_blocks SET program_day_id = d_mardi
    WHERE name IN ('Zone 2 (FC 120-140)', 'Zone 4 (FC 160-175)') AND program_day_id = d_jeudi;

    UPDATE program_days SET name = 'Cardio Vélo' WHERE id = d_mardi;
    UPDATE program_days SET name = 'Cardio Boxe' WHERE id = d_jeudi;
  END IF;
END $$;
