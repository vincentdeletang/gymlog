-- Migration 052 : Muscu 5 matins, zone 2 fondue (mardi + jeudi), jambes en entretien
--
-- CONTEXTE (19/10/2026, décidé dans FDR — `../fdr/projects/sante/setup-sport.md` est
-- désormais le propriétaire du setup : matériel, interdits, contraintes articulaires).
-- Le sport passe à 8h tous les matins (test FDR jusqu'au 01/11), même rituel chaque jour
-- pour tenir : "le seul truc qui m'intéresse c'est le haut du corps / gros bras", jambes
-- "juste pour mon ossature et ma santé générale". Les deux jours cardio seuls (mardi vélo,
-- jeudi boxe) n'ont plus été logués depuis juin (boxe arrêtée le 18/06, vélo dernier log
-- 30/06) : un jour "cardio seul" ne tient pas chez lui. Deux doses de vraie zone 2 par
-- semaine restent le plancher (raisons dans FDR) → elles sont FONDUES en fin de séance
-- mardi et jeudi (15 min), plus de jour cardio.
--
-- PRINCIPES :
--   - Même volume hebdo étalé sur 5 séances courtes (≈ 7 à 11 sets), pas 3 longues.
--   - Bras = seule cible : touchés lundi / mercredi / vendredi (48 h entre, coudes
--     sensibles sur la barre au front → une seule fois par semaine).
--   - Jamais la même articulation chargée deux matins de suite ; jambes le jeudi seulement.
--   - Interdits inchangés : rien au-dessus de la tête en poussée (pas de press militaire),
--     pas de back squat, pas de grip lourd, pas d'élastique en muscu, un seul haltère.
--     L'extension overhead EZ reste : ce n'est pas un press (coudes fixes, 84 logs sans
--     souci d'épaule).
--
-- GRILLE :
--   LUN  Bras A · biceps        : bird dog 2, side plank 2, curl EZ 4, barre au front 3   (11)
--   MAR  Haut entretien + zone 2: face pulls 2, pompes banc 3, plank 2 + zone 2 15'       (7)
--   MER  Bras B · triceps       : overhead EZ 4 ⇄ curl haltère assis 3                    (7)
--   JEU  Jambes court + zone 2  : dead bug 2, front squat SUR BANC 3, SLDL 3, mollets 3
--                                 + zone 2 15'                                            (11)
--   VEN  Bras C · curl ⇄ overhead: curl EZ 3 ⇄ overhead EZ 3 (même barre, même charge)   (6)
--   Genoux-poitrine en cooldown chaque jour.
--
-- SQUAT : le user doute ("je sais pas si c'est fait pour moi"). Le front squat reste (charge
-- figée 20 kg de disques, 3×12 RIR 3 : très loin du risque, et c'est le seul exo qui charge
-- les hanches en axial) mais devient un BOX SQUAT : le banc plat derrière lui, il descend
-- jusqu'à effleurer l'assise et remonte. Profondeur contrôlée par le banc (pas de butt wink),
-- bail-out = s'asseoir. Zéro décision sur la profondeur, zéro portion dangereuse.
--
-- MÉCANIQUE : tout est UPDATE (déplacements d'exos entre jours, historique et progression
-- conservés). INSERT uniquement pour : les 2 exos du vendredi (curl EZ + overhead EZ, nouvelles
-- lignes en mode 'reps' avec hold_weight_kg = 24 → pré-rempli à 24 kg de disques comme le
-- lundi / mercredi), 2 genoux-poitrine (mardi, jeudi) et les 2 blocs zone 2. DELETE des 3 blocs
-- cardio orphelins (vélo Z2, vélo Z4, boxe) : 10 logs sauvegardés dans
-- supabase/backups/cardio_velo_boxe_block_logs.json. Le ⏳ CHECKPOINT du 23/09 (notes du
-- mercredi) est retiré : la charge reste figée à 20, la règle de passage à 30 tient en une phrase.
--
-- VOLUME BRAS HEBDO : biceps 4 + 3 + 3 = 10 directs (était 7) ;
--                     triceps 3 + 4 + 3 = 10 directs (était 7) + 3 indirect (pompes).

DO $$
DECLARE
  d_lun UUID; d_mar UUID; d_mer UUID; d_jeu UUID; d_ven UUID;
  bar_ez UUID;
  n_cool TEXT := 'Couché sur le dos, ramener les 2 genoux vers la poitrine, mains autour des tibias, relâcher complètement le bas du dos. Respiration lente.';
BEGIN
  SELECT pd.id INTO d_lun FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_mar FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 2;
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_jeu FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 4;
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;
  SELECT id INTO bar_ez FROM bars WHERE name = 'Barre EZ';

  IF EXISTS (SELECT 1 FROM program_days WHERE id = d_ven AND name = 'Bras C · curl ⇄ overhead') THEN
    RAISE NOTICE 'Migration 052 déjà appliquée';
    RETURN;
  END IF;

  -- ============================================================
  -- 0) Jours : noms et types
  -- ============================================================
  UPDATE program_days SET name = 'Bras A · biceps',          type = 'strength', notes = 'Lundi. 8h, tenue posée la veille. Coudes : la barre au front une seule fois par semaine, c''est ici.' WHERE id = d_lun;
  UPDATE program_days SET name = 'Haut entretien + zone 2',  type = 'strength', notes = 'Mardi. Séance courte, puis 15 min de zone 2 d''un bloc. Pec et épaule en dose d''entretien, pas de chasse.' WHERE id = d_mar;
  UPDATE program_days SET name = 'Bras B · triceps',         type = 'strength', notes = 'Mercredi. Overhead et curl assis en alterné sur le même banc vertical : la séance tient en 20-25 min.' WHERE id = d_mer;
  UPDATE program_days SET name = 'Jambes court + zone 2',    type = 'strength', notes = 'Jeudi. Une seule barre chargée (20 kg de disques) pour les 3 exos, on ne touche pas aux disques. Puis 15 min de zone 2.' WHERE id = d_jeu;
  UPDATE program_days SET name = 'Bras C · curl ⇄ overhead', type = 'strength', notes = 'Vendredi. La séance la plus courte de la semaine : même barre EZ, même charge pour les deux exos, rien à recharger.' WHERE id = d_ven;

  -- ============================================================
  -- 1) Lundi : inchangé (bird dog, side plank, curl EZ, barre au front, genoux-poitrine)
  -- ============================================================

  -- ============================================================
  -- 2) Mardi ← face pulls, pompes, plank (depuis vendredi) + cooldown + zone 2
  -- ============================================================
  UPDATE exercises SET program_day_id = d_mar, order_index = 1 WHERE program_day_id = d_ven AND name = 'Face pulls élastique';
  UPDATE exercises SET program_day_id = d_mar, order_index = 2 WHERE program_day_id = d_ven AND name = 'Pompes mains surélevées (banc)';
  UPDATE exercises SET program_day_id = d_mar, order_index = 3,
         notes = 'Anti-extension pour les lombaires. Coudes sous les épaules, fesses serrées, bassin rentré, regard au sol. Arrête la série dès que les hanches tombent.'
   WHERE program_day_id = d_ven AND name = 'Plank';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, notes)
  VALUES (d_mar, 'Genoux-poitrine', 10, 1, '60s', true, 'cooldown', NULL, false, 'weight', n_cool);

  -- ============================================================
  -- 3) Mercredi : jambes → jeudi ; overhead + curl assis ← vendredi
  -- ============================================================
  UPDATE exercises SET program_day_id = d_jeu, order_index = 0 WHERE program_day_id = d_mer AND name = 'Dead bug';
  UPDATE exercises SET program_day_id = d_jeu, order_index = 1,
         name  = 'Front squat sur banc (barre)',
         notes = 'BOX SQUAT : le banc PLAT (cran 1) derrière toi, tu descends jusqu''à effleurer l''assise (sans t''asseoir lourd) et tu remontes. C''est le banc qui fixe la profondeur, pas toi. Bail-out = tu t''assois, point. '
                 'CHARGE FIGÉE : 10 kg de chaque côté (20 kg de disques + barre = 30 kg). Tu joues sur les reps, pas sur la charge. Passage à 30 kg de disques seulement quand les réveils sont bons 3 semaines de suite, et on fige là. '
                 'Barre sur les deltoïdes avant, prise BRAS CROISÉS (jamais prise olympique). Supports à hauteur d''épaule pour désenquiller, barres de sécurité basses. Coudes hauts, torse vertical.'
   WHERE program_day_id = d_mer AND name = 'Front squat (barre)';
  UPDATE exercises SET program_day_id = d_jeu, order_index = 3,
         notes = 'CHARGE FIGÉE : même barre que le squat (10 kg de chaque côté). Barres de sécurité à hauteur de GENOU = butée : tu descends jusqu''à toucher, jamais plus bas. Barre désenquillée à hauteur de hanche, pas de ramassage au sol. '
                 'Mouvement de hanche (fesses vers l''arrière), dos plat, jambes quasi tendues. La série s''arrête à la première rep où le dos s''arrondit.'
   WHERE program_day_id = d_mer AND name = 'Soulevé de terre jambes tendues (barre)';
  UPDATE exercises SET program_day_id = d_jeu, order_index = 4,
         notes = 'CHARGE FIGÉE : même barre que le SLDL, tu ne rajoutes rien. Monter sur disque ou step pour amplitude complète. Pause 1s en haut, descente lente. Santé du tendon d''Achille à ton poids.'
   WHERE program_day_id = d_mer AND name = 'Mollets debout (barre)';

  UPDATE exercises SET program_day_id = d_mer, order_index = 1,
         notes = 'EN ALTERNÉ avec le curl haltère assis : une série d''overhead, une série de curl, même banc. Le repos de l''un est le temps de l''autre. '
                 'Banc VERTICAL, cran 6 (~90°). Barre derrière la nuque, coudes pointés au plafond et FIXES (ne pas les écarter). Ce n''est pas un press : la charge ne monte pas au-dessus de la tête, ce sont les coudes qui se déplient. Cible : longue portion étirée.'
   WHERE program_day_id = d_ven AND name = 'Extensions overhead barre EZ';
  UPDATE exercises SET program_day_id = d_mer, order_index = 2 WHERE program_day_id = d_ven AND name = 'Curl haltère assis (supination)';
  -- le genoux-poitrine du mercredi reste au mercredi (order 6 → 10)
  UPDATE exercises SET order_index = 10 WHERE program_day_id = d_mer AND section = 'cooldown';

  -- ============================================================
  -- 4) Jeudi : cooldown + zone 2 (boxe supprimée)
  -- ============================================================
  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, notes)
  VALUES (d_jeu, 'Genoux-poitrine', 10, 1, '60s', true, 'cooldown', NULL, false, 'weight', n_cool);

  -- ============================================================
  -- 5) Vendredi : curl EZ ⇄ overhead EZ (nouvelles lignes, même charge que lun / mer)
  -- ============================================================
  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, bar_id, muscle_group, is_per_side, progression_mode, hold_weight_kg, notes)
  VALUES
    (d_ven, 'Curl barre EZ (supination)', 1, 3, '12-16', false, 'main', bar_ez, 'biceps', false, 'reps', 24,
     'EN ALTERNÉ avec l''overhead : même barre, même charge (24 kg de disques), tu passes de l''un à l''autre sans rien toucher. '
     'Coudes fixes le long du corps, pas de balancement, descente contrôlée. 3e passage biceps de la semaine : propre, pas à bloc.'),
    (d_ven, 'Extensions overhead barre EZ', 2, 3, '12-16', false, 'main', bar_ez, 'triceps', false, 'reps', 24,
     'EN ALTERNÉ avec le curl EZ, même barre, même charge. Banc VERTICAL, cran 6. Barre derrière la nuque, coudes pointés au plafond et FIXES. '
     'Pas un press : la charge ne monte pas, ce sont les coudes qui se déplient. 2e passage triceps long, 48 h après le mercredi.');
  -- le genoux-poitrine du vendredi reste (order 11 → 10)
  UPDATE exercises SET order_index = 10 WHERE program_day_id = d_ven AND section = 'cooldown';

  -- ============================================================
  -- 6) Cardio : les 3 blocs orphelins partent, 2 blocs zone 2 arrivent
  -- ============================================================
  DELETE FROM cardio_blocks WHERE program_day_id IN (d_mar, d_jeu);

  INSERT INTO cardio_blocks (program_day_id, name, duration_minutes, order_index, notes, duration_target_max_minutes, progression_step_minutes)
  VALUES
    (d_mar, 'Zone 2 (FC 115-135)', 15, 1,
     'Juste après la séance, 15 min d''UN SEUL bloc, souffle qui laisse parler mais pas chanter. Ce n''est PAS le pad de bureau à 2 km/h : pad à sa vitesse max si la FC monte à 115, sinon vélo dehors assistance coupée. Seule dose cœur de la semaine avec le jeudi.',
     20, 1),
    (d_jeu, 'Zone 2 (FC 115-135)', 15, 1,
     'Juste après les jambes, 15 min d''UN SEUL bloc, souffle qui laisse parler. Même support que le mardi. Jambes déjà chaudes : ça part vite.',
     20, 1);
END $$;
