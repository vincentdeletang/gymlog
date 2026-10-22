-- Migration 063 : règle de sortie du SLDL, choisie par le user (22/10/2026).
-- Question : « si c'est le SLDL qui charge mes lombaires, faudrait peut-être le virer avant
-- d'avoir mal ». Gardé (seul exo qui apprend au dos à se pencher sous charge : l'enfant au
-- sol, le siège auto), 30 kg à vie, avec une règle écrite : deux réveils du vendredi « cassé »
-- dans le même mois → retiré sans discussion. Note mise à jour, rien d'autre ne change.
UPDATE exercises
   SET notes = 'CHARGE FIGÉE À VIE : 10 kg de chaque côté (20 kg de disques + barre = 30 kg), la seule barre du jeudi. Barres de sécurité à hauteur de GENOU = butée : tu descends jusqu''à toucher, jamais plus bas. Barre désenquillée à hauteur de hanche, pas de ramassage au sol. Mouvement de hanche (fesses vers l''arrière), dos plat, jambes quasi tendues. La série s''arrête à la première rep où le dos s''arrondit. C''est le seul exo du programme qui charge tes lombaires. RÈGLE DE SORTIE (ta décision du 22/10) : deux réveils du vendredi « cassé » dans le même mois → tu me le dis, il saute.'
 WHERE name = 'Soulevé de terre jambes tendues (barre)';
