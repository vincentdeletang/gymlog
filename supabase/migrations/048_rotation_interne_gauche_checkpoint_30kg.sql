-- Migration 048 : Rotation interne épaule GAUCHE uniquement + checkpoint 30 kg sur le mercredi
--
-- 1) ROTATION INTERNE — épaule gauche seulement (lundi + vendredi)
-- L'exo a été ajouté (039) pour une hypothèse précise : subscapulaire qui stabilise le chef
-- long du biceps de l'épaule GAUCHE. L'épaule droite n'a jamais rien eu ; sa santé générale
-- est couverte par les face pulls, bilatéraux. Dans la logique 80/20 de la 047, faire le côté
-- sain double le temps pour rien. Si la droite se manifeste un jour, on l'ajoute. La note
-- mentionnait aussi "complément de la rotation externe", exo retiré en 047 → corrigé.
--
-- 2) CHECKPOINT 30 KG — les 3 exos barre du mercredi
-- La 047 fige la charge à 20 kg de disques (30 kg réels) comme TEST de 3 semaines : si les
-- réveils "cassé" s'améliorent, le SLDL était le coupable. Mais 30 kg réels est trop peu pour
-- deux objectifs (densité osseuse : le squelette porte déjà 136 kg ; entretien musculaire
-- jambes : séries loin de l'échec). Décision : après 3 mercredis à 20 kg (02/09, 09/09,
-- 16/09), passer hold_weight_kg à 30 (40 kg réels, deux tiers de l'ancienne charge) et figer
-- là. Si les réveils reviennent à 30 → retour à 20, le chiffre est trouvé.
-- Le rappel est mis DANS les notes de l'exo (visible en séance) parce que le user ne tient
-- pas ce qui n'est pas dans l'app — même pattern que la date de sortie de l'iso biceps (043).
-- Aucun set_log touché.

DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
  checkpoint TEXT := '⏳ CHECKPOINT 23/09/2026 : si les réveils vont mieux après 3 mercredis à 20 kg, on passe à 30 kg de disques (10+5 par côté) et on fige là. ';
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  UPDATE exercises
     SET notes = 'ÉPAULE GAUCHE UNIQUEMENT (la droite n''a rien, les face pulls suffisent). '
                 'Élastique ancré sur le côté à hauteur du coude. Coude COLLÉ au corps, avant-bras qui part de l''extérieur vers le nombril (rotation interne), lent et contrôlé. '
                 'Cible : subscapulaire = stabilise le chef long du biceps dans sa coulisse.'
   WHERE program_day_id IN (d_lundi, d_vendredi) AND name = 'Rotation interne élastique';

  UPDATE exercises
     SET notes = checkpoint || notes
   WHERE program_day_id = d_mercredi
     AND name IN ('Front squat (barre)', 'Soulevé de terre jambes tendues (barre)', 'Mollets debout (barre)')
     AND notes NOT LIKE '⏳ CHECKPOINT%';
END $$;
