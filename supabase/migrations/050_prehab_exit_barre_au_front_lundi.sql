-- Migration 050 : Sortie de la prehab épaule + rééquilibrage vendredi → lundi
--
-- ============================================================
-- 1) PREHAB ÉPAULE — fin du protocole (épaule G sans douleur, déclaré par le user)
-- ============================================================
-- DROP "Rotation interne élastique" (lundi + vendredi) : prehab ciblée sur une hypothèse
--   précise (039 : subscapulaire / chef long du biceps irrité par la position basse du
--   développé incliné haltère). Cet exo n'est plus au programme et la douleur est partie.
--   Job fait, même sortie que l'iso biceps en 047.
-- DROP "Face pulls élastique" LUNDI : le lundi c'est curls uniquement, rien à protéger.
-- GARDÉ "Face pulls élastique" 2×15 VENDREDI : seule séance de poussée (pompes + overhead,
--   épaule en flexion). Les symptômes disparaissent avant que le tendon ait fini de
--   s'adapter → 90 s d'assurance avant la poussée. Si l'épaule reparle, on remonte le bloc.
-- Élastique hebdo : 8 sets → 2. Set_logs sauvegardés dans supabase/backups/.
--
-- ============================================================
-- 2) "Barre au front" VENDREDI → LUNDI, en alterné avec le curl hammer
-- ============================================================
-- Le vendredi (16 sets : 2 FP + 2 RI + 3 pompes + 4 overhead + 3 barre au front + 2 plank)
-- est vécu comme trop long. Le lundi n'en avait que 12 avec 4 de gainage. Déplacer la
-- barre au front (3 sets, même charge, même historique : c'est un UPDATE, pas un delete)
-- donne 15 / 11 / 11 sets, et :
--   - triceps en 2 séances/semaine (lun 3 + ven 4) au lieu de 7 sets d'affilée le vendredi
--     alors qu'il congestionne vite et a besoin de vrais repos ;
--   - en ALTERNÉ avec le curl hammer (haltère vs barre EZ à 24 kg : rien à recharger,
--     antagonistes) → le repos de l'un est le temps de l'autre, les 7 sets prennent le temps
--     de ~4. Le curl EZ est à 30 kg, donc pas d'alterné avec lui (changement de disques).
--
-- ============================================================
-- VOLUME BRAS HEBDO (inchangé, rappel obligatoire)
-- ============================================================
-- Biceps : curl EZ 4 + hammer 4 = 8 directs (lundi), 0 indirect.
-- Triceps : barre au front 3 (lundi) + overhead EZ 4 (vendredi) = 7 directs + pompes 3 indirect.

DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  -- 1) Prehab épaule
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE (program_day_id IN (d_lundi, d_vendredi) AND name = 'Rotation interne élastique')
         OR (program_day_id = d_lundi AND name = 'Face pulls élastique'));

  DELETE FROM exercises
   WHERE (program_day_id IN (d_lundi, d_vendredi) AND name = 'Rotation interne élastique')
      OR (program_day_id = d_lundi AND name = 'Face pulls élastique');

  UPDATE exercises
     SET notes = 'Assurance épaule avant la poussée (seul bloc élastique restant). Tirer vers le visage en ouvrant les bras, coudes hauts, 1s de squeeze.'
   WHERE program_day_id = d_vendredi AND name = 'Face pulls élastique';

  -- 2) Barre au front → lundi, alterné avec le hammer
  UPDATE exercises
     SET program_day_id = d_lundi,
         order_index    = 8,
         notes = 'EN ALTERNÉ avec le curl hammer : une série de hammer, une série de barre au front, et ainsi de suite. Le repos de l''un est le temps de l''autre. '
                 'Banc PLAT, cran 1 (0°). Bras légèrement inclinés vers la tête, coudes FIXES pointés au plafond. Descendre vers le front, stop ~5cm avant. '
                 'Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse.'
   WHERE program_day_id = d_vendredi AND name = 'Barre au front';

  UPDATE exercises
     SET notes = 'EN ALTERNÉ avec la barre au front (haltère d''un côté, barre EZ chargée de l''autre, rien à recharger). '
                 'Prise neutre, mouvement lent, squeeze en haut — travaille le brachial et l''avant-bras.'
   WHERE program_day_id = d_lundi AND name = 'Curl haltères hammer';
END $$;
