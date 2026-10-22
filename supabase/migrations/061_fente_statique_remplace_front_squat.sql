-- Migration 061 : Fente statique poids de corps remplace le front squat (jeudi)
--
-- Le user (22/10/2026) : « j'ai vraiment peur de me niquer le dos », « il me faut des exos qui
-- protègent mon dos, j'ai l'impression que tous les exos de jambes niquent le dos », et il ne
-- descend pas jusqu'au banc (le box squat ne fixait rien en pratique). Les jambes ne sont pas
-- une cible d'hypertrophie : santé, ossature, garder le réservoir de muscle.
--
-- Ce qui charge les lombaires dans un exo de jambes = une charge tenue AU-DESSUS des hanches
-- × l'inclinaison du torse. Une fente poids de corps, torse vertical, main sur le rack :
-- rien au-dessus des hanches, les lombaires voient ce qu'elles voient dans un escalier.
-- Et elle construit PLUS que le squat à 30 : front squat = (134 + 30) / 2 ≈ 82 kg par
-- jambe ; fente = la jambe avant porte ~70 % de 134 ≈ 95 kg, pour 30 kg de moins sur la
-- colonne. Plus de stimulus, moins de dos. Le squat à 8 reps avec 4 en réserve ne tenait
-- plus le muscle ; 3 × 8-12 par jambe près de 2 en réserve, oui.
--
-- Progression sans jamais toucher à la colonne : reps 8 → 12 sur les 3 séries, puis l'haltère
-- (pris sur le banc, jamais au sol) tenu contre la poitrine, puis le pied arrière posé sur le
-- banc. Des années de marge. Les fentes MARCHÉES restent interdites (032 : setup, friction) ;
-- celle-ci est statique, les pieds ne bougent pas.
--
-- DROP "Front squat sur banc (barre)" (24 set_logs sauvegardés dans
-- supabase/backups/front_squat_sur_banc_barre_set_logs.json). Le jeudi = dead bug (rehab),
-- fente 3, SLDL 3 (seul exo barre, figé, butée au genou), zone 2 : 6 séries + 15 min.

DO $$
DECLARE d_jeu uuid;
BEGIN
  SELECT pd.id INTO d_jeu FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active AND pd.day_of_week = 4;

  DELETE FROM set_logs
   WHERE exercise_id IN (SELECT id FROM exercises WHERE name = 'Front squat sur banc (barre)');
  DELETE FROM exercises WHERE name = 'Front squat sur banc (barre)';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, notes)
  VALUES (d_jeu, 'Fente statique (poids de corps)', 1, 3, '8-12/jambe', true, 'main', 'quads', false, 'weight',
          'ZÉRO charge sur le dos : rien au-dessus des hanches, torse vertical. Debout face au rack, une main posée sur un support (équilibre, tu ne tires pas dessus). '
          'Un grand pas en arrière, pieds écartés de la largeur des hanches, les pieds ne bougent plus de la série. '
          'Tu descends droit : le tibia avant reste vertical, le genou arrière va vers le sol et s''arrête à une main au-dessus (jamais au contact). '
          'Tu remontes en poussant dans le talon avant. 8 à 12 reps, tu changes de jambe, une ligne de log pour les deux jambes. '
          'Arrête la série à 2 en réserve. PROGRESSION : 12 reps sur les 3 séries → l''haltère pris SUR LE BANC (jamais au sol) tenu à deux mains contre la poitrine, '
          'et on repart à 8. Plus tard : pied arrière posé sur le banc. Si ça tire dans le dos ou le genou pendant la série : tu arrêtes, tu me le dis.');

  UPDATE program_days
     SET notes = 'Jeudi. Dead bug coché, 3 séries de fente poids de corps, puis le SLDL : la seule barre du jour (20 kg de disques, figée, butée au genou). Puis 15 min de zone 2. Séance courte.'
   WHERE id = d_jeu;
END $$;
