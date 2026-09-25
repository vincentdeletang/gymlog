-- Migration 051 : Hammer retiré, curl haltère assis le vendredi en alterné avec l'overhead
--
-- 1) DROP "Curl haltères hammer" (lundi). Prise neutre = brachial + brachioradial, zone déjà
--    développée chez le user (auto-déclaré) alors que le bras est son seul objectif
--    d'hypertrophie → 4 sets mal placés. C'était aussi l'exo le plus chargé en grip /
--    brachioradial du programme (avant-bras douloureux, cf. 049). Set_logs sauvegardés dans
--    supabase/backups/curl_halt_res_hammer_set_logs.json.
--    La barre au front (lundi) perd sa consigne d'alterné : la séance fait 11 sets, inutile.
--
-- 2) ADD "Curl haltère assis (supination)" 3×10-12 VENDREDI, entre overhead et plank, EN
--    ALTERNÉ avec l'overhead EZ : même banc vertical (cran 6), haltère d'un côté, barre EZ
--    chargée de l'autre, rien à recharger. Dos calé, coude au corps → épaule neutre, le
--    tendon du chef long n'est pas étiré (le curl incliné bras en arrière travaille plus le
--    biceps mais c'est exactement la position qui irritait l'épaule G : arbitrage assumé).
--    Un seul haltère → alterné bras par bras, logué une fois par série comme le hammer.
--    Mode 'weight' (double progression) puisque l'exo est nouveau ; le user figera quand
--    ce sera "assez lourd". Départ 10 kg de disques (2 × 5) : le hammer à 20 kg (2 × 10 sur
--    l'haltère) était trop lourd ET impraticable, ce qui décourageait aussi.
--
-- Résultat : un exo biceps + un exo triceps le lundi ET le vendredi.
--   Lundi    (11) : bird dog 2, side plank 2, curl EZ 4, barre au front 3
--   Vendredi (14, ~11 en temps) : face pulls 2, pompes 3, overhead 4 ⇄ curl assis 3, plank 2
--
-- VOLUME BRAS HEBDO (rappel obligatoire)
-- Biceps : curl EZ 4 (lun) + curl haltère assis 3 (ven) = 7 directs, 0 indirect (était 8).
-- Triceps : barre au front 3 (lun) + overhead EZ 4 (ven) = 7 directs + pompes 3 indirect.

DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
  b_haltere  UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;
  SELECT bar_id INTO b_haltere FROM exercises WHERE program_day_id = d_lundi AND name = 'Curl haltères hammer';

  DELETE FROM set_logs
   WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id = d_lundi AND name = 'Curl haltères hammer');
  DELETE FROM exercises WHERE program_day_id = d_lundi AND name = 'Curl haltères hammer';

  UPDATE exercises
     SET notes = 'Banc PLAT, cran 1 (0°). Bras légèrement inclinés vers la tête, coudes FIXES pointés au plafond. Descendre vers le front, stop ~5cm avant. '
                 'Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse.'
   WHERE program_day_id = d_lundi AND name = 'Barre au front';

  UPDATE exercises
     SET notes = 'EN ALTERNÉ avec le curl haltère assis : une série d''overhead, une série de curl, même banc. Le repos de l''un est le temps de l''autre. '
                 'Banc VERTICAL, cran 6 (~90°, le plus redressé). Barre derrière la nuque, coudes pointés au plafond et FIXES (ne pas les écarter). Cible : longue portion étirée.'
   WHERE program_day_id = d_vendredi AND name = 'Extensions overhead barre EZ';

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_vendredi AND name = 'Curl haltère assis (supination)') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, bar_id, muscle_group, is_per_side, progression_mode, notes)
    VALUES (d_vendredi, 'Curl haltère assis (supination)', 8, 3, '10-12', false, 'main', b_haltere, 'biceps', false, 'weight',
            'EN ALTERNÉ avec l''overhead EZ, même banc VERTICAL cran 6, rien à recharger. '
            'Assis dos calé contre le dossier, coude au corps (jamais en arrière : c''est la position qui étirait le tendon du chef long de l''épaule G). '
            'Un seul haltère → bras par bras en alterné, une ligne de log par série pour les deux bras. '
            'Départ paume neutre, SUPINATION COMPLÈTE en montant, squeeze 1s en haut, descente lente. '
            'Charge de départ : 10 kg de disques = 2 × 5 kg, PETITS disques (les 2 × 10 kg sur l''haltère = impraticable et trop lourd, c''est ce qui décourageait sur le hammer à 20). '
            'Tu montes de 2 kg (1 kg par côté) seulement si tu finis à RIR 3+, et tu figes dès que c''est "assez lourd" — plafond pratique ~14-16 kg de disques.');
  END IF;
END $$;
