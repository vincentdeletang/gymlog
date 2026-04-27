-- Tapis incliné : recalibre les notes pour le tapis perso (pente max 3%) + repère sans capteur FC.
-- Vitesse cible et talk test à la place de la fourchette FC, qui n'est pas mesurable sans chest strap / montre.

UPDATE cardio_blocks
   SET notes = 'Pente 3% (max), 5,5-6,5 km/h. Talk test : phrases complètes possibles. RPE 4-5/10 (effort modéré, soutenable 1h théorique). Torse droit.'
 WHERE name = 'Tapis incliné'
   AND program_day_id IN (
     SELECT pd.id FROM program_days pd
     JOIN programs p ON p.id = pd.program_id
     WHERE p.is_active = true AND pd.day_of_week IN (1, 5)
   );
