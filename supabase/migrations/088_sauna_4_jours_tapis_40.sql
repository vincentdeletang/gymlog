-- Migration 088 : sauna 4 jours à 11h (mar, mer, jeu, ven), tapis 40 min mardi et jeudi, samedi rendu au repos
--
-- Le user (25/11/2026), même soirée que la 087 : le samedi ne tient pas (week-ends pleins) ; nage +
-- sauna le mercredi à 11h ; puis « je pourrais même faire un sauna le mardi 11h et vendredi 11h »,
-- validé à 4 saunas (KIHD : 4-7 séances par semaine = le meilleur groupe). 11h = son heure calme au
-- boulot. Tapis : « je dirais 40 min » les jours où il n'a que ça (plafond du programme).
-- Le sauna vit dans les notes du jour, pas dans un bloc cardio : il ne compte pas comme zone 2.

-- 1. Samedi rendu au repos ; ses 3 logs de nage rejoignent le bloc nage du mercredi
UPDATE cardio_block_logs SET cardio_block_id = '072e1ddf-bb82-4e70-b3fa-8c0eef3ebe75'
 WHERE cardio_block_id = '270b8eb2-e19e-4424-ba4a-29fdd2962295';
DELETE FROM cardio_blocks WHERE id = '270b8eb2-e19e-4424-ba4a-29fdd2962295';
UPDATE program_days SET name = 'Récupération active', type = 'rest', notes = NULL
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 6;

-- 2. Tapis 40 min mardi et jeudi
UPDATE cardio_blocks
   SET duration_minutes = 40, duration_target_max_minutes = 40,
       notes = 'Le matin, au créneau de la muscu. 40 min d''UN SEUL bloc sur le tapis, pente 3 %, souffle qui laisse parler mais pas chanter. Le plafond du programme : ne pas dépasser.'
 WHERE id IN ('47a828da-0146-470f-87eb-aa8408ddc655', 'a3efa16a-ab31-4939-b6c7-eaa58475ace9');

UPDATE program_days SET name = 'Tapis 40 min + sauna à 11h',
       notes = 'Le matin : 40 min de tapis. 11h : sauna seul au centre, 2 × 15 min, douche fraîche entre les deux, un demi-litre d''eau, pas d''alcool, sortir au premier vertige. Retour vers 12h15, repas.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week IN (2, 4);

-- 3. Mercredi : sur place à 11h
UPDATE cardio_blocks
   SET notes = 'Au centre à 11h (bassin 10h-19h). 20 min de nage continue, souffle qui laisse parler : c''est la zone 2 du jour. Puis 2 × 15 min de sauna, AVANT 13h (le bien-être ferme de 13h à 15h le mercredi).'
 WHERE id = '072e1ddf-bb82-4e70-b3fa-8c0eef3ebe75';
UPDATE program_days SET name = 'Bras B le matin + nage/sauna à 11h',
       notes = 'Mercredi. Le matin : side plank, barre au front et curl assis EN ALTERNÉ sur le banc plat (cran 1), face pulls, 3 séries de fente poids de corps. Pas de tapis : la nage est la zone 2 du jour. 11h au centre : 20 min de nage, 2 × 15 min de sauna avant 13h, douche fraîche entre les deux, un demi-litre d''eau. Retour vers 12h30, repas.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3;

-- 4. Vendredi : sauna seul à 11h après la séance du matin
UPDATE program_days SET name = 'Bras C + jambes + zone 2, sauna à 11h',
       notes = 'Vendredi. Bird dog coché, 3 curls haltère ⇄ 3 overhead EZ, 3 séries de pompes serrées, le SLDL (20 kg de disques, figé, butée au genou), puis 20 min de zone 2. ~55 min. 11h : sauna seul au centre, 2 × 15 min, retour vers 12h15.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5;
