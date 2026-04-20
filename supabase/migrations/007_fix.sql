-- Correction de 007 : UPDATE à la place de DELETE pour préserver les set_logs existants
-- La contrainte 'mobility' du début de 007 a déjà été appliquée, ne pas relancer

-- ============================================================
-- LUNDI — update en place + insert du nouveau rowing barre
-- ============================================================
DO $$
DECLARE
  d_lundi     UUID;
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

  UPDATE exercises SET order_index=6, sets_target=3, reps_target='12',
    notes='Appui genou + main sur le banc, dos neutre, amplitude complète, squeeze en haut',
    bar_id=bar_haltere
  WHERE program_day_id=d_lundi AND name='Rowing haltère unilatéral';

  UPDATE exercises SET order_index=7,
    notes='Coudes fixes le long du corps, pas de balancement, descente contrôlée',
    bar_id=bar_ez
  WHERE program_day_id=d_lundi AND name='Curl barre EZ (supination)';

  UPDATE exercises SET order_index=8,
    notes='Prise neutre, mouvement lent, squeeze en haut — travaille le brachial et l''avant-bras',
    bar_id=bar_haltere
  WHERE program_day_id=d_lundi AND name='Curl haltères hammer';

  UPDATE exercises SET order_index=9, sets_target=2,
    notes='Coude calé sur intérieur de cuisse, contraction max en haut, 2s de hold — connexion neuromusculaire',
    bar_id=bar_haltere
  WHERE program_day_id=d_lundi AND name='Curl haltère concentré';

  UPDATE exercises SET order_index=10 WHERE program_day_id=d_lundi AND name='Plank';
  UPDATE exercises SET order_index=11 WHERE program_day_id=d_lundi AND name='Suspension barre fixe';

  -- Nouveau : insérer le rowing barre seulement s'il n'existe pas déjà
  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
  SELECT d_lundi, 'Rowing barre (barres de sécurité)', 5, 4, '8-10', false,
    'Barres à hauteur mi-tibia ou genoux, dos parallèle au sol, tirer vers le nombril, coudes proches du corps',
    'main', bar_droite
  WHERE NOT EXISTS (
    SELECT 1 FROM exercises WHERE program_day_id=d_lundi AND name='Rowing barre (barres de sécurité)'
  );
END $$;

-- ============================================================
-- VENDREDI — Crunchs → Dead bug
-- ============================================================
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 5;

  UPDATE exercises SET
    name='Dead bug', reps_target='10/côté', sets_target=3,
    notes='Allongé sur le dos, allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent — gainage profond, protège les lombaires'
  WHERE program_day_id=d_vendredi AND name='Crunchs';
END $$;

-- ============================================================
-- SAMEDI — supprimer cardio block, insérer mobilité
-- ============================================================
DO $$
DECLARE
  d_samedi UUID;
BEGIN
  SELECT pd.id INTO d_samedi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 6;

  DELETE FROM cardio_blocks WHERE program_day_id=d_samedi;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT * FROM (VALUES
    (d_samedi, 'Open book',                  1, 2, '10/côté',        true, 'Allongé sur le côté, genoux à 90°, ouvrir le bras du dessus vers l''arrière en suivant du regard — clé épaule',  'mobility'),
    (d_samedi, '90/90 hip switch',            2, 1, '10 transitions',  true, 'Assis au sol, jambes à 90° des deux côtés, basculer lentement. Mains au sol si raide.',                          'mobility'),
    (d_samedi, 'Pigeon modifié (sur le dos)', 3, 2, '60s/côté',       true, 'Allongé sur le dos, cheville sur le genou opposé, tirer la cuisse vers la poitrine.',                             'mobility'),
    (d_samedi, 'Respiration diaphragmatique', 4, 1, '10 cycles',      true, 'Allongé sur le ventre, front sur les mains — expirer ventre, pas poitrine. Active la récupération.',              'mobility')
  ) AS t(program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  WHERE NOT EXISTS (
    SELECT 1 FROM exercises WHERE exercises.program_day_id=d_samedi AND exercises.name=t.name
  );
END $$;
