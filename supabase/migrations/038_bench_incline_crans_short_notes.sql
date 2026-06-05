-- 038_bench_incline_crans_short_notes.sql
--
-- 1) BANC : pour chaque exo qui se fait sur le banc, on ajoute l'inclinaison
--    idéale + le CRAN correspondant sur le banc du user (JOROTO MD80) pour
--    plus de fluidité (zéro réflexe à avoir, on lit le cran et on règle).
--
--    Le MD80 a 6 positions de dossier. Angle mesuré assise↔dossier sur la fiche
--    produit → inclinaison réelle vs horizontale (= 180° - angle fiche). On
--    numérote les crans du PLAT vers le VERTICAL :
--      cran 1 = 180° = plat        (0°)
--      cran 2 = 155° = ~25°        (1er cran au-dessus du plat)
--      cran 3 = 135° = ~45°
--      cran 4 = 125° = ~55°
--      cran 5 = 105° = ~75°
--      cran 6 =  90° = vertical    (~90°, le plus redressé)
--    (la 7e position 210° = décliné via l'assise, non utilisée ici)
--
--    Mapping exos → cran :
--      Barre au front (plat 0°)               → cran 1
--      Chest-supported row (~30°)             → cran 2 (~25°, le + proche)
--      Développé haltères incliné (~30°)      → cran 2 (~25°, le + proche)
--      Extensions overhead (vertical)         → cran 6 (~90°)
--    Chaque note garde un repère physique sans équivoque (plat / 1er cran
--    au-dessus du plat / le plus redressé) en plus du numéro de cran.
--
-- 2) NOTES : on vire les 2 grandes descriptions restantes (Goblet squat,
--    Pallof press) au profit de versions condensées (infos essentielles only).
--
-- Aucun set_log touché : seul `notes` change.

-- ============================================================
-- LUNDI — Chest-supported row haltère
-- ============================================================
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  UPDATE exercises
     SET notes = 'Banc cran 2 (~25-30°, 1er cran au-dessus du plat), face contre le dossier.

Tirer le COUDE vers la HANCHE, omoplate AVANT le bras. Descente lente 3s, étirement complet en bas.

Si tu sens le biceps → allège + "omoplate d''abord". Cible : grand dorsal + milieu du dos.'
   WHERE program_day_id = d_lundi
     AND name = 'Chest-supported row haltère';
END $$;

-- ============================================================
-- MERCREDI — Goblet squat (note condensée)
-- ============================================================
DO $$
DECLARE
  d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 3;

  UPDATE exercises
     SET notes = 'Haltère vertical contre la poitrine, torse droit, genoux dans l''axe des pieds. Descente jusqu''à parallèle (cuisses //sol), plus bas uniquement si pas de butt wink. Charge axiale = densité osseuse.'
   WHERE program_day_id = d_mercredi
     AND name = 'Goblet squat';
END $$;

-- ============================================================
-- VENDREDI — Développé incliné, Extensions overhead, Barre au front, Pallof
-- ============================================================
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  -- Développé haltères neutre : banc cran 2 (~25-30°)
  UPDATE exercises
     SET notes = 'Banc cran 2 (~25-30°, 1er cran au-dessus du plat). Prise neutre (paumes face à face) = épaule safe. Coudes ~45° du corps, descente contrôlée, pas de verrouillage brutal en haut.'
   WHERE program_day_id = d_vendredi
     AND name = 'Développé haltères neutre (incliné 30°)';

  -- Extensions overhead : banc cran 6 (vertical ~90°)
  UPDATE exercises
     SET notes = 'Banc VERTICAL, cran 6 (~90°, le plus redressé). Barre derrière la nuque, coudes pointés au plafond et FIXES (ne pas les écarter). Cible : longue portion étirée.'
   WHERE program_day_id = d_vendredi
     AND name = 'Extensions overhead barre EZ';

  -- Barre au front : banc cran 1 (plat 0°)
  UPDATE exercises
     SET notes = 'Banc PLAT, cran 1 (0°). Bras légèrement inclinés vers la tête, coudes FIXES pointés au plafond. Descendre vers le front, stop ~5cm avant.

Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse.'
   WHERE program_day_id = d_vendredi
     AND name = 'Barre au front';

  -- Pallof press élastique (note condensée)
  UPDATE exercises
     SET notes = 'Élastique ancré sur le côté à hauteur poitrine. Debout de profil, pousser droit devant et RÉSISTER à la rotation, retour lent. Anti-rotation → stabilité lombaire.'
   WHERE program_day_id = d_vendredi
     AND name = 'Pallof press élastique';
END $$;
