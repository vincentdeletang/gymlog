-- Migration 080 : mardi, 2e dose de fente + rowing à l'élastique en test
--
-- Le user (03/11/2026), après une vidéo sur les découpages : « ok pour les fentes, franchement ça
-- marche bien, le jeudi dernier ça m'a buté les jambes, vrai exo » et « je pourrais retenter du
-- rowing ». Les jambes sont la priorité n°3 (au-dessus des bras) et n'avaient que 3 séries par
-- semaine : la fente revient le mardi, même exo, mêmes règles, volume jambes doublé, zéro charge
-- sur le dos ; mardi et jeudi ne sont jamais deux matins de suite.
-- Rowing : le dossier tirage avait été clos (042, 070) sur 5 variantes barre / haltère / landmine
-- qui coinçaient au setup (ventre, entrejambe, rack qui se soulève). Celle-ci n'ajoute rien : même
-- élastique, même ancrage que les face pulls. Coudes arrêtés à hauteur du torse (épaule G).
-- Le développé couché barre reste interdit : c'est lui qui avait lancé la douleur d'épaule (ses
-- mots), pas seulement l'amplitude.
-- Mardi : 7 → 12 séries, ~+8 min.

DO $$
DECLARE
  d2 UUID;
  d4 UUID;
BEGIN
  SELECT pd.id INTO d2 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 2;
  SELECT pd.id INTO d4 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 4;

  UPDATE program_days
     SET name = 'Haut + fente + zone 2',
         notes = 'Mardi. Face pulls puis rowing (même élastique, rien à bouger), pompes ⇄ plank, 3 séries de fente, puis 15 min de zone 2. 12 séries, ~35 min.'
   WHERE id = d2;

  UPDATE exercises SET order_index = 3 WHERE program_day_id = d2 AND name = 'Pompes serrées mains surélevées (banc)';
  UPDATE exercises SET order_index = 4 WHERE program_day_id = d2 AND name = 'Plank';

  INSERT INTO exercises (id, program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, setup, notes)
  VALUES (gen_random_uuid(), d2, 'Rowing élastique debout', 2, 2, '15-25/jusqu''à 2 en réserve', true, 'main', 'back', false, 'weight',
          'Élastique sur la barre de traction (celui des face pulls)',
          'EN TEST depuis le 03/11 : même élastique, même ancrage que les face pulls, tu enchaînes sans rien toucher. Recule LOIN pour que l''élastique arrive le plus à l''horizontale possible, buste droit, genoux légèrement fléchis. Tire les mains vers le BAS DES CÔTES, coudes LE LONG du corps (écartés = c''est un face pull). Fin du mouvement : coudes à hauteur du torse, PAS plus loin derrière (épaule G). Omoplates serrées 1 s, retour lent en 2 s. SENTIR : milieu du dos et dorsaux. Biceps qui brûlent avant le dos = tu tires avec les bras, pense « coudes vers l''arrière ». Pincement à l''avant de l''épaule = stop, tu me le dis. PROGRESSION : 25 propres avec 2 en réserve sur les 2 séries → un pas plus loin ou élastique plus dur.');

  INSERT INTO exercises (id, program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, setup, notes)
  SELECT gen_random_uuid(), d2, name, 5, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, setup,
         '2e DOSE DE LA SEMAINE (le jeudi reste la 1re), mêmes règles. ' || notes
    FROM exercises
   WHERE program_day_id = d4 AND name = 'Fente statique (poids de corps)';

  UPDATE cardio_blocks
     SET notes = replace(notes, ' Seule dose cœur de la semaine avec le jeudi.', ' Jambes déjà chaudes par la fente : ça part vite.')
   WHERE program_day_id = d2;
END $$;
