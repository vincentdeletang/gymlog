-- Programme V1 - Avril 2026
-- Run AFTER migrations

do $$
declare
  prog_id uuid := gen_random_uuid();

  -- Days
  d_lundi    uuid := gen_random_uuid();
  d_mardi    uuid := gen_random_uuid();
  d_mercredi uuid := gen_random_uuid();
  d_jeudi    uuid := gen_random_uuid();
  d_vendredi uuid := gen_random_uuid();
  d_samedi   uuid := gen_random_uuid();
  d_dimanche uuid := gen_random_uuid();
begin

-- ============================================================
-- PROGRAM
-- ============================================================
insert into programs (id, name, description, is_active)
values (prog_id, 'Programme V1 - Avril 2026', 'Programme hypertrophie 5j + 2j cardio/repos', true);

-- ============================================================
-- DAYS
-- ============================================================
insert into program_days (id, program_id, day_of_week, name, type, xp_reward) values
  (d_lundi,    prog_id, 1, 'Upper Pull + Biceps', 'strength', 200),
  (d_mardi,    prog_id, 2, 'Cardio Boxe',         'cardio',   150),
  (d_mercredi, prog_id, 3, 'Lower Body',           'strength', 200),
  (d_jeudi,    prog_id, 4, 'Cardio Vélo',          'cardio',   120),
  (d_vendredi, prog_id, 5, 'Upper Push + Triceps', 'strength', 200),
  (d_samedi,   prog_id, 6, 'Récupération active',  'rest',      50),
  (d_dimanche, prog_id, 0, 'Repos complet',        'rest',       0);

-- ============================================================
-- LUNDI — Upper Pull + Biceps
-- ============================================================

-- REHAB (bodyweight)
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_lundi, 'Rotations externes élastique',  1, 3, '15',   true, 'Coude collé, rotation lente vers l''extérieur', 'rehab'),
  (d_lundi, 'Face pulls élastique',          2, 3, '15',   true, 'Tirer vers le visage en ouvrant les bras',      'rehab'),
  (d_lundi, 'Pendulaires de Codman',         3, 2, '30s',  true, 'Bras relâché, petits cercles, décompression passive', 'rehab'),
  (d_lundi, 'Stretch doorway',               4, 2, '30s',  true, 'Jamais forcer',                                 'rehab');

-- MAIN
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_lundi, 'Rowing haltère unilatéral', 5, 4, '10-12', false, 'Dos neutre, amplitude complète',                 'main'),
  (d_lundi, 'Curl barre EZ (supination)', 6, 4, '10-12', false, 'Coudes fixes, pas de balancement',              'main'),
  (d_lundi, 'Curl haltères hammer',       7, 3, '10-12', false, 'Prise neutre, mouvement lent, squeeze en haut', 'main'),
  (d_lundi, 'Curl haltère concentré',     8, 3, '12-15', false, 'Finisher biceps, contraction max',              'main'),
  (d_lundi, 'Plank',                      9, 3, '30-60s', true, null,                                            'main');

-- CARDIO FIN
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_lundi, 'Corde à sauter', 20, 1, 'Séries 2-3 min / 30s récup');

-- ============================================================
-- MARDI — Cardio Boxe
-- ============================================================
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_mardi, 'Music Boxing', 15, 1, 'Échauffement, montée progressive'),
  (d_mardi, 'Sac de boxe',  25, 2, 'Rounds 3 min / 1 min récup');

-- ============================================================
-- MERCREDI — Lower Body
-- ============================================================
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_mercredi, 'Fentes marchées haltères',  1, 4, '10/jambe', false, null,                                   'main'),
  (d_mercredi, 'Split squat bulgare',        2, 3, '10/jambe', false, null,                                   'main'),
  (d_mercredi, 'Hip thrust (barre sur banc)',3, 3, '12-15',    false, 'Squeeze fessiers 2s en haut',          'main'),
  (d_mercredi, 'Mollets debout (barre)',     4, 4, '15-20',    false, 'Monter sur disque pour amplitude',     'main'),
  (d_mercredi, 'Reverse crunches',           5, 3, '15-20',    true,  null,                                   'main');

insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_mercredi, 'Tapis 3%', 30, 1, 'FC cible 110-130 bpm');

-- ============================================================
-- JEUDI — Cardio Vélo
-- ============================================================
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_jeudi, 'Zone 2 (FC 120-140)', 50, 1, 'Rythme conversation, assistance électrique dans les côtes'),
  (d_jeudi, 'Zone 4 (FC 160-175)', 10, 2, 'Sprint plat ou côte');

-- ============================================================
-- VENDREDI — Upper Push + Triceps
-- ============================================================

-- REHAB (same as lundi)
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_vendredi, 'Rotations externes élastique', 1, 3, '15',  true, 'Coude collé, rotation lente vers l''extérieur', 'rehab'),
  (d_vendredi, 'Face pulls élastique',         2, 3, '15',  true, 'Tirer vers le visage en ouvrant les bras',      'rehab'),
  (d_vendredi, 'Pendulaires de Codman',        3, 2, '30s', true, 'Bras relâché, petits cercles, décompression passive', 'rehab'),
  (d_vendredi, 'Stretch doorway',              4, 2, '30s', true, 'Jamais forcer',                                 'rehab');

-- MAIN
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_vendredi, 'Développé haltères neutre (incliné 30°)', 5, 4, '10-12', false, 'Prise neutre = safe épaule',                       'main'),
  (d_vendredi, 'Élévations latérales haltères',           6, 3, '12-15', false, 'Jamais au-dessus de l''horizontale',               'main'),
  (d_vendredi, 'Extensions triceps barre EZ',             7, 4, '10-12', false, 'Coudes fixes pointés plafond',                     'main'),
  (d_vendredi, 'Kickbacks haltères',                      8, 4, '12-15', false, 'Finisher triceps, serrer en extension',            'main'),
  (d_vendredi, 'Crunchs',                                 9, 3, '15-20', true,  null,                                               'main');

insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_vendredi, 'Corde à sauter ou Tapis', 25, 1, null);

-- ============================================================
-- SAMEDI — Récupération active
-- ============================================================
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_samedi, 'Marche / mobilité', 30, 1, 'Optionnel, écoute ton corps');

-- Dimanche : no exercises, no cardio blocks (repos complet)

end $$;
