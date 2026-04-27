-- Améliorations programme post-audit IA :
-- 1. Pulldown élastique (lundi)         → comble le trou tirage vertical, santé scapulaire / épaule G
-- 2. Mollets debout (mercredi)          → santé tendineuse à 136kg + cardio impact
-- 3. Pallof press élastique (vendredi)  → anti-rotation core, transfert lombaire (squat / RDL / fentes)
-- 4. Goblet squat : note recalibrée pour morpho 1m97 + abdominal (parallèle strict, plus profond uniquement si mobilité OK)

-- ============================================================
-- LUNDI — Pulldown élastique (main, après les biceps)
-- ============================================================
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_lundi, 'Pulldown élastique',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_lundi AND section = 'main'),
    3, '12-15', true,
    'Élastique fixé en hauteur (porte / barre fixe), tirer vers la poitrine en abaissant les omoplates en fin de mouvement. Comble le tirage vertical absent du programme — recrute lower trap + rhomboïdes, clé pour la santé scapulaire et l''épaule gauche.',
    'main'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_lundi AND name='Pulldown élastique');
END $$;

-- ============================================================
-- MERCREDI — Mollets debout (main, après le SDT)
-- ============================================================
DO $$
DECLARE
  d_mercredi UUID;
  bar_droite UUID;
BEGIN
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT id INTO bar_droite FROM bars WHERE name='Barre droite';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
  SELECT d_mercredi, 'Mollets debout (barre)',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_mercredi AND section = 'main'),
    3, '15-20', false,
    'Monter sur disque ou step pour amplitude complète. Pause 1s en haut, descente lente. Important pour santé Achille à ton poids + cardio régulier.',
    'main', bar_droite
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Mollets debout (barre)');
END $$;

-- ============================================================
-- VENDREDI — Pallof press élastique (main, en core anti-rotation)
-- ============================================================
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, is_per_side)
  SELECT d_vendredi, 'Pallof press élastique',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_vendredi AND section = 'main'),
    3, '10', true,
    'Élastique fixé sur le côté à hauteur de poitrine, debout perpendiculaire au point d''ancrage. Pousser l''élastique droit devant, résister à la rotation, retour lent. Anti-rotation = transfert direct sur la stabilité lombaire dans tous les compounds.',
    'main', true
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Pallof press élastique');
END $$;

-- ============================================================
-- Goblet squat — note recalibrée morpho 1m97 + abdominal
-- ============================================================
UPDATE exercises
   SET notes = 'Haltère tenu vertical devant la poitrine, descente jusqu''à parallèle stricte (cuisses parallèles au sol). Plus bas seulement si mobilité chevilles/hanches le permet sans cambrer le bas du dos (butt wink à éviter, surtout vu morpho longues jambes + stockage abdominal). Genoux dans l''axe des pieds, torse vertical — charge axiale pour la densité osseuse.'
 WHERE name = 'Goblet squat'
   AND program_day_id IN (
     SELECT pd.id FROM program_days pd
     JOIN programs p ON p.id = pd.program_id
     WHERE p.is_active = true AND pd.day_of_week = 3
   );
