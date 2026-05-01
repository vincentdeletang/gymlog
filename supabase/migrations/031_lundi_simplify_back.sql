-- Migration 031 : Simplification dos lundi (alignement nouveaux objectifs)
--
-- Objectifs visés (cf. CLAUDE.md mis à jour) :
--   - Dos = entretien santé/posture/anti-blessures, PAS chasse hypertrophie
--   - "Minimum efficace" pour un muscle non-bras = 3-4 sets directs/sem suffit
--   - Rowing barre classique : amplitude réduite par stockage abdominal du user (la barre touche le bide
--     avant rétraction scapulaire complète → faux travail). Problème morphologique connu chez 1m97/136kg.
--   - Rowing haltère unilatéral : pas senti par le user, pas motivant.
--   - Pulldown élastique : conflit avec préférence user (pas d'élastique en muscu, réservé à la rehab).
--
-- Changements lundi :
--   - DROP "Rowing barre (barres de sécurité)" : amplitude limitée par bide (faux travail)
--   - DROP "Rowing haltère unilatéral" : pas senti, redondant
--   - DROP "Pulldown élastique" : élastique en muscu non voulu
--   - ADD "Chest-supported row haltère" 4×8-12 unilatéral : élimine le problème du bide,
--     dos protégé par banc, mind-muscle ++, charge axiale densité osseuse, biceps indirect propre.
--     Seul exo dos de la séance, suffisant pour santé/posture/biceps indirect.
--
-- Bilan post-031 :
--   - Lundi main passe de 5 exos (4 row/curl + pulldown) à 3 exos (1 row + 2 curls) → -15-20 min
--   - Volume dos direct : 10 sets → 4 sets (alignement "minimum efficace")
--   - Volume biceps : inchangé (3 EZ + 3 hammer = 6 directs + ~3-4 indirects via row)

DO $$
DECLARE
  d_lundi     UUID;
  bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_lundi
  FROM program_days pd
  JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 1;

  SELECT id INTO bar_haltere FROM bars WHERE name = 'Haltère';

  -- 1a) Drop set_logs avant les exos (FK constraint) — détruit l'historique de ces 3 exos
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
     WHERE program_day_id = d_lundi
       AND name IN (
         'Rowing barre (barres de sécurité)',
         'Rowing haltère unilatéral',
         'Pulldown élastique'
       )
   );

  -- 1b) Drop des 3 exos dos actuels
  DELETE FROM exercises
   WHERE program_day_id = d_lundi
     AND name IN (
       'Rowing barre (barres de sécurité)',
       'Rowing haltère unilatéral',
       'Pulldown élastique'
     );

  -- 2) Insert du nouvel exo dos (description ultra-détaillée car nouveau pour le user)
  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_lundi AND name = 'Chest-supported row haltère') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id, is_per_side)
    VALUES (
      d_lundi,
      'Chest-supported row haltère',
      5,
      4,
      '8-12',
      false,
      'SETUP : Banc inclinable réglé à ~30° (dossier vers le haut). Haltère posé au sol à côté/sous l''extrémité haute du banc, à portée de main. Te positionner FACE CONTRE le banc : poitrine + ventre appuyés sur le dossier incliné. Pieds au sol stables, légèrement écartés. Le front peut reposer sur le bord haut du banc, regard légèrement vers le haut.

EXÉCUTION : Une main attrape l''haltère, bras pendant librement vers le sol = étirement complet du dos en bas. L''autre main peut tenir le bord du banc pour stabiliser. TIRER l''haltère vers la HANCHE (pas vers la poitrine) en pliant le coude ET en RÉTRACTANT l''omoplate (rapprocher l''omoplate de la colonne). En haut : pause brève, sentir la contraction dans le milieu du dos. DESCENTE LENTE et contrôlée (3-4s) jusqu''à étirement complet en bas. Aucun momentum, aucun mouvement du buste — seul mouvement = bras + omoplate.

POINTS CLÉS :
- COUDE PROCHE DU CORPS (pas écarté à 90°) → cible grand dorsal + rhomboïdes
- INITIER avec l''omoplate, le bras suit (pas l''inverse) → mind-muscle
- ÉTIREMENT COMPLET EN BAS (pas de range partielle) — c''est l''essentiel du bénéfice
- 3s de descente excentrique → maximise le stimulus
- Si tu sens surtout le biceps et peu le dos = soit trop lourd, soit mauvaise initiation (omoplate AVANT bras)

UNILATÉRAL : tous les sets d''un côté puis l''autre, ou alterner set par set selon préférence.

PREMIÈRE SÉANCE : charge légère pour caler la mécanique. Mate quelques vidéos avant ("dumbbell chest-supported row" ou "incline dumbbell row 30 degrees") — Jeff Nippard et Jeff Cavaliere ont des bons tutos.

ATTENTION BIDE : c''est exactement pour ça qu''on remplace le rowing barre — ici le banc te sépare du sol, donc plus aucune limitation d''amplitude liée au ventre.',
      'main',
      bar_haltere,
      true
    );
  END IF;

  -- 3) Re-normaliser les order_index du main (rehab à 1-4, main à 5-7)
  UPDATE exercises SET order_index = 6
   WHERE program_day_id = d_lundi AND name = 'Curl barre EZ (supination)';

  UPDATE exercises SET order_index = 7
   WHERE program_day_id = d_lundi AND name = 'Curl haltères hammer';
END $$;
