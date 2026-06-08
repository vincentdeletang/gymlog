-- Migration 040 : Lundi — Chest-supported row → Inverted row (barres de sécurité)
--
-- Contexte : le user ne peut pas faire correctement les deux variantes de tirage
-- testées jusqu'ici, pour des raisons morphologiques (1m97 / 136kg) :
--   - Rowing barre classique (avant 031) : amplitude bloquée par le stockage abdominal
--     (la barre touche le ventre avant rétraction scapulaire complète).
--   - Chest-supported row haltère (031) : la position face contre le banc incliné lui
--     écrase l'entrejambe (inconfort rédhibitoire) → adhérence nulle.
--   - Rowing haltère unilatéral (avant 031) : "pas senti", déjà écarté.
--
-- C'est le SEUL tirage horizontal de toute la semaine (lundi = unique jour pull).
-- On ne supprime donc PAS sans remplacer : le dos n'est pas une cible hypertrophie,
-- mais le tirage couvre 3 priorités réelles du user — posture/anti-blessure (contre-
-- poids du push), santé épaule G (rétraction scapulaire, complément rehab), et biceps
-- indirect (biceps = seule cible croissance).
--
-- Remplacement : INVERTED ROW (tirage horizontal au poids de corps), barre droite posée
-- sur les barres de sécurité. Règle les deux problèmes d'un coup :
--   - Corps suspendu sous la barre, seules les chaussures touchent le sol → plus aucun
--     contact ventre/banc/entrejambe, amplitude pleine, et pas d'appui au sol du garage
--     (cf. floor press refusé pour cette raison).
--   - Gainage corps rigide = anti-extension (comme le plank) → bon pour ses lombaires
--     faibles, zéro flexion spinale sous charge.
--   - Charge réglée par l'angle (barre haute = facile) → adapté à 136kg, et s'allège
--     mécaniquement à mesure qu'il perd du gras → progression loggable gratuite.
--   - Prise SUPINATION (paumes vers soi) → maximise le biceps indirect ; épaule en
--     flexion (pas extension) donc n'agace pas le chef long du biceps (≠ développé incliné).
--
-- Conserve : order_index 5 (même slot), 4×8-12, section main, muscle_group 'back'.
-- Bodyweight (pas de bar_id/tare), bilatéral (is_per_side = false, vs unilatéral avant).
--
-- ⚠️ Supprime un exo avec set_logs historiques (chest-supported row) : suppression des
--    logs avant l'exo (FK constraint), détruit l'historique. Même pattern que 010, 011,
--    030, 031, 032, 039.

DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  -- 1) Drop set_logs du chest-supported row (FK constraint) puis l'exo
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id = d_lundi
        AND name = 'Chest-supported row haltère'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_lundi
     AND name = 'Chest-supported row haltère';

  -- 2) Insert de l'inverted row (idempotent)
  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_lundi AND name = 'Inverted row (barres de sécurité)') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, muscle_group, is_per_side)
    VALUES (
      d_lundi,
      'Inverted row (barres de sécurité)',
      5,
      4,
      '8-12',
      true,
      'Cible : milieu du dos + grand dorsal. Biceps indirect.

SETUP : barre droite posée sur les barres de sécurité, hauteur hanche / bas de poitrine. Te glisser dessous, prise SUPINATION (paumes vers toi, largeur épaules), corps gainé droit de la tête aux talons, talons au sol. Tu es suspendu : seules tes chaussures touchent le sol.

EXÉCUTION : tirer le STERNUM vers la barre en serrant les omoplates (omoplate d''abord). Pause brève en haut, descente contrôlée jusqu''aux bras tendus. Corps rigide tout du long = gainage anti-extension (comme un plank, bon pour les lombaires).

CHARGE : plus la barre est HAUTE = plus facile (torse redressé). Commence haut. Régression : genoux pliés, pieds à plat. Progression : baisse la barre d''un cran quand 8-12 deviennent faciles — et ça s''allège tout seul à mesure que tu perds du gras.',
      'main',
      'back',
      false
    );
  END IF;
END $$;
