-- Migration 059 : Rowing landmine (barre calée dans un coin) — TEST, mercredi
--
-- 6e variante de tirage, la seule jamais essayée qui contourne les trois obstacles des cinq
-- précédentes (031, 040, 042) : le ventre (la barre passe ENTRE les jambes, pas sur le bide),
-- l'entrejambe (pas de banc), le rack qui se soulève (rien n'est accroché au rack). Décision du
-- user (20/10/2026) : une série d'essai mercredi ; si le ventre, le dos ou les avant-bras disent
-- non à la 1ère série → DROP et le dossier tirage est clos pour de bon.
--
-- SETUP : un bout de la barre droite calé au sol dans un coin du garage (serviette ou disque
-- contre le mur), l'autre bout chargé. Entre les séries ce bout REPOSE SUR UNE BARRE DE SÉCURITÉ
-- à hauteur de genou : jamais de ramassage au sol. Prise à deux mains sur le manchon, torse
-- incliné ~45°, dos plat, tirer vers le bas du ventre, coudes le long du corps, omoplates
-- serrées 1 s, descente contrôlée. Charge de départ 10 kg de disques (un seul disque).
--
-- bar_id NULL : avec un bout au sol on ne soulève qu'une partie de la barre, la tare de 10 kg
-- serait fausse → on logue les disques seulement. Grip : deux mains sur un manchon pour
-- 10-20 kg, bien moins que le curl EZ à 32 ; si l'avant-bras parle, c'est un critère de DROP.

DO $$
DECLARE
  d_mer UUID;
BEGIN
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;

  IF EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_mer AND name LIKE 'Rowing landmine%') THEN
    RAISE NOTICE 'Migration 059 déjà appliquée';
    RETURN;
  END IF;

  UPDATE exercises SET order_index = 2 WHERE program_day_id = d_mer AND name = 'Barre au front';
  UPDATE exercises SET order_index = 3 WHERE program_day_id = d_mer AND name = 'Curl haltère assis (supination)';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, bar_id, muscle_group, is_per_side, progression_mode, notes)
  VALUES (d_mer, 'Rowing landmine (barre calée) — TEST', 1, 3, '10-12', false, 'main', NULL, 'back', false, 'weight',
          'TEST : si le ventre, le dos ou les avant-bras disent non à la 1ère série, tu arrêtes et tu me le dis, on le retire. '
          'SETUP : un bout de la barre droite calé au sol dans un coin (serviette ou disque contre le mur), l''autre bout chargé. Entre les séries, ce bout REPOSE sur une barre de sécurité à hauteur de genou : jamais de ramassage au sol. '
          'EXÉCUTION : à cheval au-dessus de la barre, prise à deux mains sur le manchon, torse incliné ~45°, dos plat, tu tires vers le bas du ventre, coudes le long du corps, omoplates serrées 1 s, descente contrôlée. La barre passe entre tes jambes, pas sur ton ventre. '
          'CHARGE : 10 kg de disques pour commencer (un seul disque). Tu logues les disques seulement, pas la barre. '
          'Si ça passe : c''est le seul tirage du programme, posture et épaule, 3 séries suffisent.');
END $$;
