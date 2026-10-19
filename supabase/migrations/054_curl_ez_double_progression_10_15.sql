-- Migration 054 : Curl EZ en double progression courte (10-15), le plafond de 20 reps saute
--
-- Suite immédiate de la 053 (même soir). Question du user : "est-ce que c'est vraiment le mieux
-- d'aller jusqu'à 20 reps avant d'augmenter ?" Non. Le plafond de 20 (REPS_CEILING du mode
-- 'reps', migration 044) était une béquille posée quand il refusait toute montée de charge :
-- le seul moyen de garder une progression. Maintenant que la charge peut bouger, les séries
-- de 20 n'ont plus de raison d'être : longues (~50 s), brûlure, "ça me nique les bras", et
-- c'est le coude qui encaisse la durée.
--
-- Méthode standard hypertrophie = double progression sur une plage courte : reps_target
-- '10-15', mode 'weight'. L'app plafonne les reps à 15 ; la séance où il fait 15 avec RIR >= 2,
-- elle propose +2 kg et il repart à 10. Séries de ~30 s, petites marches plus fréquentes.
--
-- Lundi : dernier log 24 kg × 20 (>= 15) RIR 2 → l'app proposera 26 dès lundi, c'est bien la
-- décision de la 053. hold_weight_kg remis à NULL (il ne sert qu'au mode 'reps').
-- Vendredi : nouvelle ligne sans historique → l'app n'a rien à proposer, il tape 26 la première
-- fois (note mise à jour).
-- L'overhead EZ reste en mode 'reps' à 24 jusqu'à son plafond, on changera à ce moment-là si
-- la plage courte lui convient sur le curl.

UPDATE exercises e
   SET progression_mode = 'weight',
       reps_target      = '10-15',
       hold_weight_kg   = NULL,
       notes = CASE pd.day_of_week
         WHEN 1 THEN 'Double progression courte : tu montes les reps de 10 à 15, et la séance où tu fais 15 avec 2 en réserve, +2 kg et tu repars à 10. Plus jamais 20. Coudes fixes le long du corps, pas de balancement, descente contrôlée.'
         ELSE        'Même règle que le lundi : 10 à 15 reps, 15 avec 2 en réserve → +2 kg, retour à 10. Première séance : tape 26 (la même charge que le lundi). EN ALTERNÉ avec l''overhead : même barre, même charge, tu passes de l''un à l''autre sans rien toucher. Coudes fixes le long du corps, descente contrôlée.'
       END
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
 WHERE e.program_day_id = pd.id AND p.is_active
   AND pd.day_of_week IN (1, 5)
   AND e.name = 'Curl barre EZ (supination)';
