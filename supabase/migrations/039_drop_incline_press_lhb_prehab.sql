-- Migration 039 : Épaule G — drop développé incliné + recentrage prehab chef long du biceps
--
-- Contexte : douleur antérieure épaule G récurrente sur la 1ère série du développé
-- haltères incliné, localisée par le user au tendon du CHEF LONG DU BICEPS (coulisse
-- bicipitale). Pas de douleur sur les curls → spécifique à la position basse du
-- développé (coude derrière le corps = mise en tension du chef long). Le pec n'est PAS
-- une cible de croissance (santé/densité osseuse only) et les triceps sont déjà couverts
-- en direct (overhead + barre au front) → on DROP le développé SANS le remplacer
-- (allège aussi le vendredi, déjà dense). Cf. CLAUDE.md (profil épaule G).
--
-- PREHAB (lundi + vendredi) — recentrage sur le chef long, à coût net ~nul (1 swap) :
--   - DROP "Stretch doorway" : étire l'avant de l'épaule (abduction + rotation externe
--     + extension) = pile la position qui peut agacer le chef long quand il est irritable.
--   - ADD "Rotation interne élastique" 2×15 : subscapulaire = stabilise le chef long dans
--     sa coulisse. Complète la rotation externe déjà présente (équilibre coiffe).
--   - ADD "Isométrie biceps (temporaire)" 3×30s : protocole tendon (Keith Baar) — charge
--     le tendon sans mouvement douloureux, effet antalgique + capacité. À RETIRER une fois
--     l'épaule calme. Charge modérée-lourde, ~30s, douleur ≤ 3/10.
--   - GARDÉS : Rotations externes (infra-épineux, ciblé ≠ face pull), Face pulls.
--   À exécuter en CIRCUIT warm-up (enchaîné, sans repos).
--
-- ⚠️ Supprime des exos avec set_logs historiques (développé, doorway) : suppression des
--    logs avant l'exo (FK constraint), détruit l'historique. Même pattern que 010, 011,
--    030, 031, 032.

-- ============================================================
-- VENDREDI — drop développé haltères incliné (sans remplacement)
-- ============================================================
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id = d_vendredi
        AND name = 'Développé haltères neutre (incliné 30°)'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_vendredi
     AND name = 'Développé haltères neutre (incliné 30°)';
END $$;

-- ============================================================
-- LUNDI + VENDREDI — prehab : doorway → rotation interne + isométrie biceps
-- ============================================================
DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
  day_ids    UUID[];
  d_id       UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 5;
  day_ids := ARRAY[d_lundi, d_vendredi];

  -- 1) DROP "Stretch doorway" (set_logs d'abord — FK constraint)
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises WHERE program_day_id = ANY(day_ids) AND name = 'Stretch doorway'
   );
  DELETE FROM exercises
   WHERE program_day_id = ANY(day_ids) AND name = 'Stretch doorway';

  -- 2) + 3) ADD rotation interne + isométrie biceps sur les 2 jours (idempotent)
  FOREACH d_id IN ARRAY day_ids LOOP
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_id AND name = 'Rotation interne élastique') THEN
      INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
      VALUES (d_id, 'Rotation interne élastique', 4, 2, '15', true,
        'Élastique ancré sur le côté à hauteur du coude. Coude COLLÉ au corps, avant-bras qui part de l''extérieur vers le nombril (rotation interne), lent et contrôlé. Cible : subscapulaire = stabilise le chef long du biceps dans sa coulisse. Complément de la rotation externe (équilibre la coiffe).',
        'rehab');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_id AND name = 'Isométrie biceps (temporaire)') THEN
      INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
      VALUES (d_id, 'Isométrie biceps (temporaire)', 5, 3, '30s', true,
        'PROTOCOLE TENDON (chef long du biceps). Tenir une charge MODÉRÉE-LOURDE, coude à ~90°, avant-bras supiné, sans bouger, ~30s. La charge compte (pas un truc léger). Douleur ≤ 3/10. Renforce + soulage le tendon. TEMPORAIRE → à retirer une fois l''épaule calme. En warm-up, pas tous les jours (le tendon récupère en plusieurs heures).',
        'rehab');
    END IF;
  END LOOP;
END $$;
