-- Migration 082 : zone 2 à 20 min chaque jour (75 → 100 min par semaine)
--
-- Le user (03/11/2026), après l'audit du programme : « 20 min dès lundi ». Le cœur est l'objectif
-- sport n°2, au-dessus des bras, et 75 min par semaine faisaient la moitié des 150 recommandées.
-- La progression automatique (+1 min toutes les 2 séances du même bloc, une par semaine) n'y
-- aurait mené que mi-janvier. Coût : +5 min par séance, le lundi passe à ~55 min.
-- Plafond laissé à 20 : la marche suivante (vers 30) se décide plus tard, après le RDV cardio du 04/12.

UPDATE cardio_blocks
   SET duration_minutes = 20,
       duration_target_max_minutes = 20,
       notes = replace(notes, '15 min d''UN SEUL bloc', '20 min d''UN SEUL bloc')
 WHERE name LIKE 'Zone 2%'
   AND program_day_id IN (SELECT pd.id FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active);

UPDATE program_days
   SET notes = replace(replace(replace(notes, '15 min de zone 2', '20 min de zone 2'), '~50 min', '~55 min'), '~35 min', '~40 min')
 WHERE program_id IN (SELECT id FROM programs WHERE is_active)
   AND notes LIKE '%15 min de zone 2%';
