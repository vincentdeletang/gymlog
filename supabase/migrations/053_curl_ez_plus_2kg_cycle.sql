-- Migration 053 : Curl EZ +2 kg, le cycle reps repart (lundi + vendredi)
--
-- Le curl EZ du lundi est au plafond du mode 'reps' depuis plusieurs séances : 24 kg de disques
-- × 20 reps × 4 séries, RIR 2, charge figée. À 20 reps c'est de l'endurance, plus de
-- l'hypertrophie, et un muscle ne grossit que si quelque chose monte. Décision du user
-- (19/10/2026, FDR) : +2 kg et on recommence le cycle. Même règle désormais pour tout exo bras
-- en mode 'reps' : au plafond de 20 reps avec RIR >= 2 → +2 kg, retour à la plage reps_target,
-- et on remonte vers 20. Ce n'est plus "figé", c'est un cycle lent.
--
-- MÉCANIQUE : hold_weight_kg = 26 (migration 047). Tant que le dernier log n'est pas à 26, l'app
-- pré-remplit 26 et remet l'objectif reps sur la plage reps_target (10-12) ; ensuite +1 rep par
-- séance jusqu'à 20, puis l'app propose +2 kg à nouveau. Le vendredi (nouvelle ligne de la 052,
-- même barre, même charge) suit à 26 pour ne rien avoir à recharger entre curl et overhead ;
-- l'overhead reste à 24 jusqu'à son propre plafond de 20 reps.

UPDATE exercises e
   SET hold_weight_kg = 26, progression_mode = 'reps'
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
 WHERE e.program_day_id = pd.id AND p.is_active
   AND pd.day_of_week IN (1, 5)
   AND e.name = 'Curl barre EZ (supination)';
