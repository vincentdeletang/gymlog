-- Migration 045 : Mercredi — Goblet squat → Front squat (barre)
--
-- CONTEXTE : le goblet squat a atteint 42 kg. Le mouvement passe très bien, mais **monter
-- l'haltère du sol à la poitrine** est devenu le point dangereux : mini-deadlift dos rond,
-- en début de séance, lombaires déjà faibles. Verbatim : "42kg c'est déjà trop pour lever
-- l'haltère". C'est le plafond STRUCTUREL du goblet, pas un plafond de force — figer la
-- charge (mode 'reps' de la 044) réglerait l'aggravation mais pas le risque.
--
-- LE GOBLET N'A JAMAIS ÉTÉ CHOISI CONTRE LE SQUAT BARRE : la 009 l'a *ajouté* (jour jambes
-- trop léger), pas substitué. La morpho 1m97 n'est intervenue que dans la 026, et uniquement
-- pour calibrer la PROFONDEUR (parallèle stricte, butt wink). Aucune décision passée à
-- contredire ici.
--
-- FRONT ET PAS BACK : l'a priori du user ("ça va me niquer le corps") est fondé mais vise le
-- back squat — à 1m97, fémurs longs + stockage abdominal, barre sur le dos = torse penché =
-- cisaillement lombaire. Le front squat n'a pas ce problème : charge à l'avant, si le torse
-- penche la barre tombe. Auto-correcteur — exactement la contrainte qui rendait le goblet
-- safe. Un front squat = son goblet squat avec le chargement résolu.
--
-- SÉCURITÉ : barres de sécurité montables au-dessus de sa tête + 2 supports mobiles.
-- Supports à hauteur d'épaule pour désenquiller, barres de sécurité basses = bail-out.
-- Le rack léger qui se soulevait en 042 n'est pas un problème : l'inverted row TIRAIT vers
-- le haut, le squat POUSSE vers le bas (cas nominal d'un rack).
--
-- ÉPAULE G : prise BRAS CROISÉS, jamais prise olympique. Pas de rotation externe → n'agace
-- pas le chef long du biceps (039). L'épaule en flexion n'a jamais posé problème (040).
--
-- MISE À JOUR EN PLACE (≠ delete + insert) : la RLS n'ouvre que UPDATE sur `exercises`
-- (017), pas INSERT ni DELETE. On réécrit donc la ligne du goblet au lieu de la remplacer —
-- ce qui rend la migration applicable depuis un client authentifié normal, sans service_role.
-- Effet de bord bienvenu : l'order_index et les FK sont préservés.
--
-- SET_LOGS PURGÉS (45 lignes, sauvegardées dans supabase/backups/goblet_squat_set_logs.json) :
-- obligatoire. En gardant l'historique, `progression.js` lirait 42 kg et proposerait 44 kg
-- dès la 1ère séance d'un mouvement jamais pratiqué.

DO $$
DECLARE
  d_mercredi UUID;
  ex_id      UUID;
  bar_droite UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 3;

  SELECT id INTO bar_droite FROM bars WHERE name = 'Barre droite';

  SELECT id INTO ex_id FROM exercises
   WHERE program_day_id = d_mercredi AND name = 'Goblet squat';

  IF ex_id IS NULL THEN
    RAISE NOTICE 'Goblet squat introuvable — migration déjà appliquée ?';
    RETURN;
  END IF;

  -- 1) Purge de l'historique (sinon suggestion à 44 kg sur un mouvement neuf)
  DELETE FROM set_logs WHERE exercise_id = ex_id;

  -- 2) Réécriture de la ligne en place
  UPDATE exercises
     SET name             = 'Front squat (barre)',
         sets_target      = 3,
         reps_target      = '8',
         is_bodyweight    = false,
         muscle_group     = 'quads',
         bar_id           = bar_droite,
         progression_mode = 'weight',
         notes            = 'Barre sur les deltoïdes avant, prise BRAS CROISÉS (jamais prise olympique). '
                            'Supports à hauteur d''épaule pour désenquiller, barres de sécurité en position basse = bail-out. '
                            'Coudes hauts, torse vertical, descente jusqu''à parallèle (cuisses //sol). '
                            'Repars léger : 20-30 kg barre comprise le temps de caler la position.'
   WHERE id = ex_id;
END $$;
