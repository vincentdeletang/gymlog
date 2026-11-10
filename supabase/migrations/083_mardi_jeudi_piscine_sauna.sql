-- Migration 083 : mardi et jeudi deviennent piscine + sauna, la muscu passe à 3 jours (lun, mer, ven)
--
-- Le user (10/11/2026) : « la muscu à 3 jours, c'est même plus intelligent long terme de faire du
-- cardio 2 jours, c'était déjà mon truc d'avant ». Mardi et jeudi midi : 20 min de nage (la zone 2
-- du jour) puis 2 × 15 min de sauna au centre aquatique, bassin ouvert 12h-14h en période scolaire.
--
-- Ce qui bouge (UPDATE program_day_id, historique et progression conservés) :
--   - Face pulls (mardi)        -> mercredi, l'épaule garde sa dose
--   - Bird dog, fente, SLDL (jeudi) -> vendredi : les jambes restent une fois par semaine
-- Ce qui sort (set_logs sauvegardés dans supabase/backups/) : pompes serrées, plank, rowing
-- élastique (en test, 0 log), 2e dose de fente du mardi (0 log). La nage couvre le tirage et le gainage.

-- 1. Déplacements
UPDATE exercises SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3),
                     order_index = 3
 WHERE id = '16ffeb0b-6fce-4116-8738-3455135debae';           -- Face pulls -> mercredi

UPDATE exercises SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5),
                     order_index = 0
 WHERE id = '3d434742-b042-4d28-aa8b-d6a5b0145a84';           -- Bird dog -> vendredi, avant tout

UPDATE exercises SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5),
                     order_index = 3
 WHERE id = '249a276c-a264-47a6-a7ce-27134bbe1bd3';           -- Fente statique -> vendredi

UPDATE exercises SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5),
                     order_index = 4
 WHERE id = '2e41e3ab-d52f-4884-a238-cbc00395064a';           -- SLDL -> vendredi

-- 2. Sorties
DELETE FROM set_logs WHERE exercise_id IN (
  '021d1277-9258-4c9c-a7e1-d45d63e14a80',  -- Pompes serrées
  '7e2b7832-7aae-4163-8089-7e132b721b30',  -- Plank
  '1617edd1-b9da-4594-bb96-1e0dfbd51223',  -- Rowing élastique
  'f1cf0e6f-64fd-44e7-8afc-fe967f6f13e1'); -- Fente du mardi
DELETE FROM exercises WHERE id IN (
  '021d1277-9258-4c9c-a7e1-d45d63e14a80',
  '7e2b7832-7aae-4163-8089-7e132b721b30',
  '1617edd1-b9da-4594-bb96-1e0dfbd51223',
  'f1cf0e6f-64fd-44e7-8afc-fe967f6f13e1');

-- 3. Mardi et jeudi : jours cardio
UPDATE program_days
   SET name = 'Piscine + sauna', type = 'cardio',
       notes = 'Shaker pré-séance vers 11h45, au centre à 12h15 (bassin ouvert 12h-14h en période scolaire, horaires sur le site du centre). 20 min de nage, puis 2 × 15 min de sauna, douche fraîche entre les deux, un demi-litre d''eau. Le repas de midi en rentrant, vers 13h45.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week IN (2, 4);

UPDATE cardio_blocks
   SET name = 'Nage (zone 2)', duration_minutes = 20, duration_target_max_minutes = 20,
       notes = '20 min de nage continue, souffle qui laisse parler. C''est la zone 2 du jour. Puis 2 × 15 min de sauna.'
 WHERE id IN ('270b8eb2-e19e-4424-ba4a-29fdd2962295', '072e1ddf-bb82-4e70-b3fa-8c0eef3ebe75');

-- 4. Notes des jours muscu touchés
UPDATE program_days
   SET notes = notes || ' Depuis la 083 : face pulls en fin de séance (venus du mardi).'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3;

UPDATE program_days
   SET name = 'Bras C + jambes + zone 2',
       notes = 'Vendredi. Bird dog coché, 3 curls ⇄ 3 overhead (même barre, même charge), 3 séries de fente poids de corps, le SLDL (20 kg de disques, figé, butée au genou), puis 20 min de zone 2. ~55 min. Les jambes viennent du jeudi depuis la 083.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5;
