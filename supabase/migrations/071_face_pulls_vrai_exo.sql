-- Migration 071 : les face pulls passent de case à cocher à vrai exo (mardi)
--
-- Le user (28/10/2026) : « je considère pas vraiment ça comme un exo, c'est de l'élastique ».
-- Verdict donné : l'élastique n'est pas le problème (même gain de force qu'avec des poids libres
-- ou des machines, méta de Lopes 2019, SAGE Open Med 7) ; le problème, c'était 2 × 15 cochés
-- sans réserve logée, donc loin de l'échec = rien de construit. Il choisit d'en faire un vrai exo.
-- Seul travail du haut du dos du programme depuis que le dossier tirage est clos (070).
--
-- Section rehab → main : reps + réserve loguées comme les pompes. Toujours en 1er dans le bloc
-- principal (il garde son rôle d'échauffement d'épaule avant la poussée). 2 séries, même temps.
-- Plage 15-25 : à l'élastique, la tension se règle par la distance, pas par des kilos.

UPDATE exercises
   SET section = 'main',
       order_index = 1,
       muscle_group = 'back',
       reps_target = '15-25/jusqu''à 2 en réserve',
       notes = 'Haut du dos et arrière d''épaule, ton seul tirage : il compte comme un vrai exo. Élastique accroché à hauteur de visage, tirer vers le visage en ouvrant les bras, coudes hauts, omoplates serrées 1 s, retour lent (2 s) sans laisser l''élastique te tirer. La série va jusqu''à 2 en réserve : si tu finis 25 reps facile, tu recules d''un pas ou tu doubles l''élastique, la tension se règle par la distance. PROGRESSION : 25 reps avec 2 en réserve sur les 2 séries → un pas plus loin la semaine d''après.'
 WHERE name = 'Face pulls élastique';
