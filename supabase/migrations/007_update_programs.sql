-- 1) Nouvelle section 'mobility'
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_section_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_section_check
  CHECK (section IN ('main', 'rehab', 'cardio', 'cooldown', 'mobility'));

-- ============================================================
-- LUNDI — nouveau programme Upper Pull + Biceps
-- ============================================================
DO $$
DECLARE
  d_lundi UUID;
  bar_ez      UUID;
  bar_droite  UUID;
  bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_lundi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 1;

  SELECT id INTO bar_ez      FROM bars WHERE name = 'Barre EZ';
  SELECT id INTO bar_droite  FROM bars WHERE name = 'Barre droite';
  SELECT id INTO bar_haltere FROM bars WHERE name = 'Haltère';

  DELETE FROM exercises WHERE program_day_id = d_lundi AND section IN ('main', 'cooldown');

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id) VALUES
    (d_lundi, 'Rowing barre (barres de sécurité)', 5, 4, '8-10',   false, 'Barres à hauteur mi-tibia ou genoux, dos parallèle au sol, tirer vers le nombril, coudes proches du corps', 'main', bar_droite),
    (d_lundi, 'Rowing haltère unilatéral',          6, 3, '12',     false, 'Appui genou + main sur le banc, dos neutre, amplitude complète, squeeze en haut',                           'main', bar_haltere),
    (d_lundi, 'Curl barre EZ (supination)',          7, 4, '10-12',  false, 'Coudes fixes le long du corps, pas de balancement, descente contrôlée',                                    'main', bar_ez),
    (d_lundi, 'Curl haltères hammer',                8, 3, '10-12',  false, 'Prise neutre, mouvement lent, squeeze en haut — travaille le brachial et l''avant-bras',                  'main', bar_haltere),
    (d_lundi, 'Curl haltère concentré',              9, 2, '12-15',  false, 'Coude calé sur intérieur de cuisse, contraction max en haut, 2s de hold — connexion neuromusculaire',     'main', bar_haltere),
    (d_lundi, 'Plank',                              10, 3, '30-60s', true,  null,                                                                                                        'main', null),
    (d_lundi, 'Suspension barre fixe',              11, 2, '30s',    true,  'Décompression vertébrale, relâchement complet, genoux pliés si besoin',                                   'cooldown', null);
END $$;

-- ============================================================
-- VENDREDI — remplace Crunchs par Dead bug
-- ============================================================
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 5;

  UPDATE exercises SET
    name        = 'Dead bug',
    reps_target = '10/côté',
    sets_target = 3,
    notes       = 'Allongé sur le dos, allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent — gainage profond, protège les lombaires'
  WHERE program_day_id = d_vendredi AND name = 'Crunchs';
END $$;

-- ============================================================
-- SAMEDI — remplace cardio par protocole mobilité
-- ============================================================
DO $$
DECLARE
  d_samedi UUID;
BEGIN
  SELECT pd.id INTO d_samedi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 6;

  DELETE FROM cardio_blocks WHERE program_day_id = d_samedi;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) VALUES
    (d_samedi, 'Open book',                   1, 2, '10/côté',       true, 'Allongé sur le côté, genoux à 90°, ouvrir le bras du dessus vers l''arrière en suivant du regard, retour lent — clé pour l''épaule',    'mobility'),
    (d_samedi, '90/90 hip switch',             2, 1, '10 transitions', true, 'Assis au sol, jambes à 90° des deux côtés, basculer lentement d''un côté à l''autre. Mains au sol si raide.',                          'mobility'),
    (d_samedi, 'Pigeon modifié (sur le dos)',  3, 2, '60s/côté',      true, 'Allongé sur le dos, cheville sur le genou opposé, tirer la cuisse vers la poitrine — fessier et piriforme.',                           'mobility'),
    (d_samedi, 'Respiration diaphragmatique',  4, 1, '10 cycles',     true, 'Allongé sur le ventre, front sur les mains — expirer complètement, inspirer en gonflant le ventre. Active la récupération.',           'mobility');
END $$;
