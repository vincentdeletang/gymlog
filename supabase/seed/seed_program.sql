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
  (d_lundi, 'Plank',                               5, 3, '30-60s', true,  null,                                                                                                        'main'),
  (d_lundi, 'Rowing barre (barres de sécurité)',   6, 4, '8-10',   false, 'Barres à hauteur mi-tibia ou genoux, dos parallèle au sol, tirer vers le nombril, coudes proches du corps', 'main'),
  (d_lundi, 'Rowing haltère unilatéral',           7, 3, '12',     false, 'Appui genou + main sur le banc, dos neutre, amplitude complète, squeeze en haut',                           'main'),
  (d_lundi, 'Curl barre EZ (supination)',          8, 4, '10-12',  false, 'Coudes fixes le long du corps, pas de balancement, descente contrôlée',                                    'main'),
  (d_lundi, 'Curl haltères hammer',                9, 3, '10-12',  false, 'Prise neutre, mouvement lent, squeeze en haut — travaille le brachial et l''avant-bras',                  'main'),
  (d_lundi, 'Curl haltère concentré',             10, 2, '12-15',  false, 'Coude calé sur intérieur de cuisse, contraction max en haut, 2s de hold — connexion neuromusculaire',     'main'),
  (d_lundi, 'Suspension barre fixe',              11, 2, '30s',    true,  'Décompression vertébrale, relâchement complet, genoux pliés si besoin',                                   'cooldown');

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
  (d_mercredi, 'Dead bug',                                  0, 2, '8/côté',   true,  'Activation lombaires avant le travail lourd — allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent', 'main'),
  (d_mercredi, 'Goblet squat',                              1, 3, '8',        false, 'Haltère tenu vertical devant la poitrine, descente profonde, genoux dans l''axe des pieds, torse vertical — charge axiale pour la densité osseuse', 'main'),
  (d_mercredi, 'Fentes marchées haltères',                  2, 3, '10/jambe', false, 'Pas suffisamment large pour que le genou avant ne dépasse pas le pied, descente selon confort', 'main'),
  (d_mercredi, 'Soulevé de terre jambes tendues (barre)',   3, 3, '10-12',    false, 'Dos plat, descente contrôlée le long des jambes, étirement ischio en bas',                      'main'),
  (d_mercredi, 'Suspension barre fixe',                     4, 2, '30s',      true,  'Décompression vertébrale, relâchement complet, genoux pliés si besoin',                       'cooldown');

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
  (d_vendredi, 'Kickbacks haltères',                      8, 3, '12-15', false, 'Finisher triceps, serrer en extension',            'main'),
  (d_vendredi, 'Dead bug',                                 9, 3, '10/côté', true, 'Allongé sur le dos, allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent — gainage profond, protège les lombaires', 'main'),
  (d_vendredi, 'Suspension barre fixe',                  10, 2, '30s',    true,  'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'cooldown');

insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_vendredi, 'Corde à sauter ou Tapis', 25, 1, null);

-- ============================================================
-- SAMEDI — Récupération active (mobilité ~13 min)
-- ============================================================
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_samedi, 'Open book',                  1, 2, '10/côté',        true, 'Allongé sur le côté, genoux à 90°, ouvrir le bras du dessus vers l''arrière en suivant du regard, retour lent — clé pour l''épaule', 'mobility'),
  (d_samedi, '90/90 hip switch',            2, 1, '10 transitions',  true, 'Assis au sol, jambes à 90° des deux côtés, basculer lentement d''un côté à l''autre. Mains au sol si raide.',                        'mobility'),
  (d_samedi, 'Pigeon modifié (sur le dos)', 3, 2, '60s/côté',       true, 'Allongé sur le dos, cheville sur le genou opposé, tirer la cuisse vers la poitrine — fessier et piriforme.',                         'mobility'),
  (d_samedi, 'Respiration diaphragmatique', 4, 1, '10 cycles',      true, 'Allongé sur le ventre, front sur les mains — expirer complètement, inspirer en gonflant le ventre. Active la récupération.',         'mobility');

-- Dimanche : no exercises, no cardio blocks (repos complet)

end $$;
