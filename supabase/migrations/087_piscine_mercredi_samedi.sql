-- Migration 087 : la piscine + sauna passe au mercredi et au samedi, mardi et jeudi deviennent 20 min de tapis le matin
--
-- Le user (25/11/2026) : « la piscine le mercredi c'est 10h-19h, je vois pas pourquoi on se fait
-- chier avec le mardi et le jeudi » puis « faut trouver le truc le plus smooth en fonction des
-- horaires piscine et sauna ». Constat dans la base : la nage du mardi et du jeudi n'a plus été
-- loguée depuis le 12/11 (le créneau 12h-14h coupait la journée). Horaires relus le 25/11 sur le
-- site du centre, période scolaire : bassin mercredi 10h-19h, samedi 10h-18h30 ; espace bien-être
-- mercredi et samedi 10h-13h puis 15h-20h (18h30 le samedi).
--
-- Grille : lun bras A + tapis · mar tapis · mer bras B le matin + piscine/sauna à midi ·
-- jeu tapis · ven bras C + tapis · sam piscine/sauna · dim repos. 6 zone 2, 2 saunas.
-- Les blocs déménagent avec leur historique (UPDATE program_day_id) ; seul le tapis du mardi est neuf.

-- 1. Nage du jeudi -> mercredi, à la place du tapis ; le tapis du mercredi -> jeudi
UPDATE cardio_blocks SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 4)
 WHERE id = 'a3efa16a-ab31-4939-b6c7-eaa58475ace9';
UPDATE cardio_blocks SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3),
       notes = 'À midi au centre, pas après la séance du matin. 20 min de nage continue, souffle qui laisse parler : c''est la zone 2 du jour. Puis 2 × 15 min de sauna, AVANT 13h (le bien-être ferme de 13h à 15h le mercredi).'
 WHERE id = '072e1ddf-bb82-4e70-b3fa-8c0eef3ebe75';

-- 2. Nage du mardi -> samedi
UPDATE cardio_blocks SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 6),
       notes = '20 min de nage continue, souffle qui laisse parler. Puis 2 × 15 min de sauna, AVANT 13h (le bien-être ferme de 13h à 15h le samedi) ou après 15h.'
 WHERE id = '270b8eb2-e19e-4424-ba4a-29fdd2962295';

-- 3. Tapis neuf du mardi
INSERT INTO cardio_blocks (program_day_id, name, duration_minutes, order_index, notes, duration_target_max_minutes, progression_step_minutes)
SELECT id, 'Zone 2 (FC 115-135)', 20, 1,
       'Le matin, au créneau de la muscu. 20 min d''UN SEUL bloc sur le tapis, pente 3 %, souffle qui laisse parler mais pas chanter. Rien d''autre ce jour-là.',
       20, 1
  FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 2;

UPDATE cardio_blocks
   SET notes = 'Le matin, au créneau de la muscu. 20 min d''UN SEUL bloc sur le tapis, pente 3 %, souffle qui laisse parler mais pas chanter. Rien d''autre ce jour-là.'
 WHERE id = 'a3efa16a-ab31-4939-b6c7-eaa58475ace9';

-- 4. Les jours
UPDATE program_days SET name = 'Zone 2 maison', type = 'cardio',
       notes = 'Le matin, 20 min de tapis, et c''est tout : pas de coupure à midi.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week IN (2, 4);

UPDATE program_days SET name = 'Bras B le matin + piscine/sauna à midi',
       notes = 'Mercredi. Le matin : side plank, barre au front et curl assis EN ALTERNÉ sur le banc plat (cran 1), face pulls, 3 séries de fente poids de corps. Pas de tapis : la nage de midi est la zone 2 du jour. Midi : shaker vers 11h30, au centre à 11h45 (bassin ouvert 10h-19h), 20 min de nage, 2 × 15 min de sauna avant 13h, douche fraîche entre les deux, un demi-litre d''eau. Le repas en rentrant, vers 13h15.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3;

UPDATE program_days SET name = 'Piscine + sauna', type = 'cardio',
       notes = 'Samedi matin, bassin dès 10h. Possible en famille : Maddie au bassin ludique avec Audrey pendant ton sauna. 20 min de nage, 2 × 15 min de sauna avant 13h (ou après 15h). Rien dans l''estomac avant.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 6;
