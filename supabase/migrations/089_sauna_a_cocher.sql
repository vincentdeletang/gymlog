-- Migration 089 : le sauna devient une case à cocher, mardi à vendredi
--
-- Le user (25/11/2026) veut voir où il en est dans la semaine (séances, sauna, zone 2). La 088 avait
-- mis le sauna dans les notes du jour seulement : rien ne l'enregistrait. Une ligne par jour, section
-- cooldown (tap-to-log, sans modal ni RIR), en fin de séance. Le nom exact « Sauna (2 × 15 min) » sert
-- de clé au compteur de la semaine (appli et tableau de bord FDR).
INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, progression_mode)
SELECT id, 'Sauna (2 × 15 min)', 99, 1, '2 × 15 min', true,
       'À 11h au centre. 2 × 15 min à environ 80 °C, douche fraîche entre les deux, un demi-litre d''eau, pas d''alcool, sortir au premier vertige. Le mercredi et le samedi, le bien-être ferme de 13h à 15h. Tu coches en sortant.',
       'cooldown', 'weight'
  FROM program_days
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week IN (2, 3, 4, 5);
