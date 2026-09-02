-- Migration 047 : Charge figée explicite (mercredi), gainage lundi, prehab épaule au strict minimum
--
-- CONTEXTE : réveils "cassé de partout", lombaires ressenties faibles en portant sa fille.
-- Les logs pointent UN suspect : le SLDL est monté de +2 kg CHAQUE semaine pendant 8 semaines
-- (30 → 50 kg de disques, soit 40 → 60 kg réels, +50 %), toujours logué 3×12 RIR 2 à la
-- virgule. Seul exo qui charge les lombaires, seul exo dont la charge s'est envolée. L'app
-- (mode 'weight') proposait +2 kg mécaniquement à chaque top de plage.
--
-- Décision du user : figer les 3 exos barre du mercredi à une charge FACILE — 10 kg de
-- chaque côté (20 kg de disques + barre droite 10 kg = 30 kg réels). Jambes et dos ne sont
-- pas des cibles d'hypertrophie (CLAUDE.md, objectif #5), donc chaque kilo au-delà de
-- "assez lourd" est du risque sans bénéfice. Une seule barre chargée pour toute la séance,
-- on ne touche plus aux disques : front squat → SLDL → mollets.
--
-- ============================================================
-- 1) COLONNE exercises.hold_weight_kg
-- ============================================================
-- Le mode 'reps' (044) fige la charge sur le DERNIER LOG. Ici on veut figer PLUS BAS que le
-- dernier log (50 → 20) : sans colonne, l'app afficherait "🔒 50kg ↑ 13 reps" et le user
-- (qui tape le pré-rempli par réflexe) loguerait 50 alors qu'il a 20 sur la barre.
--   hold_weight_kg NULL  → comportement 044 inchangé (charge = dernier log)
--   hold_weight_kg = 20  → charge pré-remplie à 20, quel que soit l'historique
-- Tant que le dernier log n'est pas à la charge figée, l'objectif reps est remis sur la
-- plage reps_target (12 reps à 50 kg ne dit rien sur 20 kg). Repasser en mode 'weight'
-- depuis l'app remet la colonne à NULL (useProgramStore).
--
-- ============================================================
-- 2) MERCREDI — Front squat, SLDL, Mollets → mode 'reps', hold 20 kg
-- ============================================================
-- Mollets figés aussi (demande du user) : ils suivaient exactement la charge du SLDL
-- (barre laissée chargée), soit 60 kg sur les épaules en équilibre sur un disque pour rien.
-- Aucun set_log touché : l'historique reste visible dans les stats.
--
-- ============================================================
-- 3) LUNDI — ADD Bird dog 2×8/côté + Side plank 2×20-30s/côté (section rehab, tap-to-log)
-- ============================================================
-- Le gainage lombaire de la semaine se résumait à dead bug 2×8 (mer) + plank 2×34s (ven).
-- Porter un enfant sur une hanche = anti-flexion latérale, que rien ne travaillait. Les
-- lombaires "faiblardes" sont typiquement un manque d'ENDURANCE des extenseurs, qui se
-- travaille en isométrie rachis neutre, pas en soulevant plus lourd.
-- Bird dog (extenseurs + hanche, rachis neutre) + side plank (QL/obliques) complètent le
-- trio de McGill avec le dead bug. Poids de corps, ~4 min, tap-to-log sans modal.
-- LUNDI parce que : séance la plus courte (2 exos main), zéro gainage, et le retrait de
-- 6 sets de prehab (point 4) libère plus de temps que ces 4 sets n'en prennent → la
-- séance RACCOURCIT. Résultat : gainage 3×/semaine réparti, aucune séance surchargée.
--
-- ============================================================
-- 4) LUNDI + VENDREDI — Prehab épaule : 10 sets → 4 sets
-- ============================================================
-- Épaule G en amélioration nette, le user trouve le bloc long et chiant en début de séance.
-- 80/20 :
--   - DROP "Rotations externes élastique" 2×15 : redondant avec les face pulls (rotation
--     externe + rétraction scapulaire + delt post = le face pull couvre tout ça).
--   - DROP "Isométrie biceps (stop le 06/09)" 3×30s : date de sortie atteinte à 4 jours près,
--     critère 043 rempli (3 séances de pompes 14/08 → 28/08 sans douleur épaule G).
--   - GARDÉ "Face pulls élastique" 3×15 → 2×15 : l'exo le plus complet.
--   - GARDÉ "Rotation interne élastique" 2×15 : seul exo qui cible le subscapulaire, donc
--     le chef long du biceps (hypothèse de travail 039). Rien d'autre ne le couvre.
-- Set_logs des exos retirés sauvegardés dans supabase/backups/ (FK sans ON DELETE).
--
-- ============================================================
-- VOLUME BRAS HEBDO (inchangé, rappel obligatoire)
-- ============================================================
-- Biceps : curl EZ 4 + hammer 4 = 8 directs, 0 indirect. L'iso biceps était de la prehab,
-- jamais comptée dans le volume.
-- Triceps : overhead EZ 4 + barre au front 3 = 7 directs + pompes 3 indirect.

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS hold_weight_kg NUMERIC;

DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  -- 2) Mercredi : charge figée à 10 kg de chaque côté
  UPDATE exercises
     SET progression_mode = 'reps',
         hold_weight_kg   = 20,
         notes = 'CHARGE FIGÉE : 10 kg de chaque côté (20 kg de disques + barre = 30 kg). Ne monte pas, tu joues sur les reps. '
                 'Barre sur les deltoïdes avant, prise BRAS CROISÉS (jamais prise olympique). '
                 'Supports à hauteur d''épaule pour désenquiller, barres de sécurité en position basse = bail-out. '
                 'Coudes hauts, torse vertical, descente jusqu''à parallèle (cuisses //sol).'
   WHERE program_day_id = d_mercredi AND name = 'Front squat (barre)';

  UPDATE exercises
     SET progression_mode = 'reps',
         hold_weight_kg   = 20,
         notes = 'CHARGE FIGÉE : 10 kg de chaque côté (20 kg de disques + barre = 30 kg), même barre que le front squat. Ne monte pas, tu joues sur les reps. '
                 'Barres de sécurité à hauteur de GENOU = butée : tu descends jusqu''à toucher, jamais plus bas. '
                 'Barre désenquillée à hauteur de hanche, pas de ramassage au sol. '
                 'Mouvement de hanche (fesses vers l''arrière), dos plat, jambes quasi tendues. La série s''arrête à la première rep où le dos s''arrondit.'
   WHERE program_day_id = d_mercredi AND name = 'Soulevé de terre jambes tendues (barre)';

  UPDATE exercises
     SET progression_mode = 'reps',
         hold_weight_kg   = 20,
         notes = 'CHARGE FIGÉE : même barre que le SLDL (10 kg de chaque côté), tu ne rajoutes rien. '
                 'Monter sur disque ou step pour amplitude complète. Pause 1s en haut, descente lente. '
                 'Important pour santé Achille à ton poids + cardio régulier.'
   WHERE program_day_id = d_mercredi AND name = 'Mollets debout (barre)';

  -- 4) Lundi + vendredi : prehab épaule au strict minimum
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id IN (d_lundi, d_vendredi)
        AND name IN ('Rotations externes élastique', 'Isométrie biceps (stop le 06/09)'));

  DELETE FROM exercises
   WHERE program_day_id IN (d_lundi, d_vendredi)
     AND name IN ('Rotations externes élastique', 'Isométrie biceps (stop le 06/09)');

  UPDATE exercises SET sets_target = 2
   WHERE program_day_id IN (d_lundi, d_vendredi) AND name = 'Face pulls élastique';

  -- 3) Lundi : gainage après la prehab épaule, avant les curls
  UPDATE exercises SET order_index = 3
   WHERE program_day_id = d_lundi AND name = 'Rotation interne élastique';

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_lundi AND name = 'Bird dog') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, notes)
    VALUES (d_lundi, 'Bird dog', 4, 2, '8/côté', true, 'rehab', 'core', true,
            'À 4 pattes, mains sous les épaules, genoux sous les hanches. Tendre bras droit + jambe gauche à l''horizontale, '
            'SANS cambrer ni tourner le bassin (un verre d''eau posé sur les lombaires ne tomberait pas). Tenir 3s, revenir lentement, alterner. '
            'Cible : endurance des extenseurs lombaires, rachis neutre.');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_lundi AND name = 'Side plank') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, notes)
    VALUES (d_lundi, 'Side plank', 5, 2, '20-30s/côté', true, 'rehab', 'core', true,
            'Sur le côté, coude sous l''épaule, corps aligné tête-hanches-pieds, hanche décollée du sol. '
            'Sur les GENOUX (jambes pliées) si 20s impossible en version pieds — c''est la version attendue au départ à ton poids. '
            'Cible : carré des lombes + obliques = ce qui tient quand tu portes ta fille sur une hanche.');
  END IF;
END $$;
