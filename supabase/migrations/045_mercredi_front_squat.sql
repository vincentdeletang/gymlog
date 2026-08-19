-- Migration 045 : Mercredi — Goblet squat → Front squat (barre)
--
-- CONTEXTE : le goblet squat a atteint 42 kg. Le user signale que le mouvement lui-même
-- passe très bien, mais que **monter l'haltère du sol jusqu'à la poitrine** est devenu le
-- point dangereux : c'est un mini-deadlift dos rond, en début de séance, avec des lombaires
-- déjà identifiées comme faibles. Verbatim : "42kg c'est déjà trop pour lever l'haltère".
-- C'est le plafond structurel du goblet, pas un plafond de force.
--
-- POURQUOI PAS "GARDER LE GOBLET EN FIGEANT LA CHARGE" : ça règle l'aggravation, pas le
-- risque — il faut toujours ramasser 42 kg au sol chaque mercredi.
--
-- POURQUOI LE SQUAT BARRE EST LÉGITIME ICI : vérification faite, le goblet n'a JAMAIS été
-- choisi contre le squat barre. La 009 l'a *ajouté* (jour jambes trop léger), pas substitué.
-- La morpho 1m97 n'est intervenue que dans la 026, et uniquement pour calibrer la
-- PROFONDEUR (parallèle stricte, pas plus bas si butt wink). Aucune migration n'a évalué
-- ni rejeté le squat barre — il n'y a donc pas de décision passée à contredire.
--
-- POURQUOI FRONT ET PAS BACK : l'a priori du user ("ça va me niquer le corps") est fondé,
-- mais il vise le back squat. À 1m97, fémurs longs + stockage abdominal, barre sur le dos
-- = torse penché en avant pour garder la barre sur le milieu du pied = cisaillement lombaire.
-- Le front squat n'a pas ce problème : charge à l'avant, donc si le torse penche la barre
-- tombe. Le mouvement est auto-correcteur — c'est exactement la contrainte qui rendait le
-- goblet safe pour lui. Un front squat = son goblet squat avec le chargement résolu.
--
-- SÉCURITÉ (nouveau matos) : le user peut monter ses barres de sécurité au-dessus de sa tête
-- et dispose de 2 supports mobiles supplémentaires. Setup : supports à hauteur d'épaule pour
-- désenquiller, barres de sécurité en position basse comme bail-out. Le rack léger qui se
-- soulevait en 042 n'est pas un problème ici : l'inverted row TIRAIT vers le haut, le squat
-- POUSSE vers le bas — c'est le cas nominal d'un rack.
--
-- ÉPAULE G : prise BRAS CROISÉS, pas prise olympique. Pas de rotation externe → n'agace pas
-- le chef long du biceps (cf. 039). L'épaule en flexion n'a jamais posé de problème (cf. 040).
--
-- SLDL CONSERVÉ : c'est le seul travail chaîne postérieure, et des lombaires faibles se
-- renforcent en étant entraînées, pas en étant évitées. Le front squat étant nettement moins
-- lombaire que le back squat, le cumul passe à 3 séries chacun. Bénéfice collatéral du
-- nouveau matos : le SLDL se désenquille lui aussi désormais → le 2e pickup au sol de la
-- séance disparaît en même temps que le premier.
--
-- SET_LOGS : l'historique du goblet est supprimé (précédent 032). Volontaire et nécessaire —
-- réutiliser la ligne aurait fait hériter 42 kg au front squat, donc une suggestion de 44 kg
-- dès la 1ère séance sur un mouvement jamais pratiqué. Repart de zéro, charge légère.
--
-- Progression : mode 'weight' (exo neuf, la charge doit remonter). Il pourra basculer en
-- 'reps' depuis l'app quand il jugera la charge assez lourde (cf. 044).

DO $$
DECLARE
  d_mercredi UUID;
  bar_droite UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 3;

  SELECT id INTO bar_droite FROM bars WHERE name = 'Barre droite';

  -- 1) Drop goblet squat (set_logs d'abord pour la FK)
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id = d_mercredi AND name = 'Goblet squat'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_mercredi AND name = 'Goblet squat';

  -- 2) Front squat au même slot (order_index 1, juste après le dead bug)
  INSERT INTO exercises
    (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight,
     notes, section, muscle_group, bar_id, progression_mode)
  SELECT d_mercredi, 'Front squat (barre)', 1, 3, '8', false,
    'Barre sur les deltoïdes avant, prise BRAS CROISÉS (jamais prise olympique). '
    'Supports à hauteur d''épaule pour désenquiller, barres de sécurité en position basse = bail-out. '
    'Coudes hauts, torse vertical, descente jusqu''à parallèle (cuisses //sol). '
    'Repars léger : 20-30 kg barre comprise le temps de caler la position.',
    'main', 'quads', bar_droite, 'weight'
  WHERE NOT EXISTS (
    SELECT 1 FROM exercises
     WHERE program_day_id = d_mercredi AND name = 'Front squat (barre)'
  );

  -- 3) SLDL : plus de ramassage au sol non plus
  UPDATE exercises
     SET notes = 'Barre désenquillée à hauteur de hanche sur les supports — plus de ramassage au sol. '
                 'Dos plat, descente contrôlée le long des jambes, étirement ischio en bas.'
   WHERE program_day_id = d_mercredi
     AND name = 'Soulevé de terre jambes tendues (barre)';
END $$;
