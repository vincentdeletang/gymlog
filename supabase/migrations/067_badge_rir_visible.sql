-- Migration 067 : la consigne de réserve lisible AVANT chaque exo, dans le badge.
-- Le user (22/10) : « l'app est peut-être construite comme ça, mais c'est pas clair pour moi,
-- faudrait que je le sache avant chaque exo, je m'en tiens à ce qu'il y a écrit ».
-- Le badge affiche sets×reps_target. parseRepsTarget() coupe tout ce qui suit un « / » avant
-- de lire la plage : on peut donc écrire la consigne après le « / » sans toucher au
-- déclencheur du +2 kg (la plage reste lue). Zéro changement de code.
UPDATE exercises SET reps_target = '10-15/jusqu''à 2 en réserve, 4e à 1'
 WHERE name IN ('Curl barre EZ (supination)', 'Extensions overhead barre EZ');
UPDATE exercises SET reps_target = '10-12/jusqu''à 2 en réserve, 3e à 1'
 WHERE name = 'Barre au front';
UPDATE exercises SET reps_target = '10-15/jusqu''à 2 en réserve, 3e à 1'
 WHERE name = 'Curl haltère assis (supination)';
UPDATE exercises SET reps_target = '8-15/jusqu''à 2 en réserve'
 WHERE name = 'Pompes serrées mains surélevées (banc)';
UPDATE exercises SET reps_target = '10-12/jusqu''à 2 en réserve, dos plat'
 WHERE name = 'Soulevé de terre jambes tendues (barre)';
UPDATE exercises SET reps_target = '8-12/jambe, jusqu''à 2 en réserve'
 WHERE name = 'Fente statique (poids de corps)';
