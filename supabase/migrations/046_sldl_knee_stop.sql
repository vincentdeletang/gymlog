-- Migration 046 : Mercredi — SLDL, amplitude plafonnée par butée au genou
--
-- Le user refuse d'"entraîner ses lombaires" (peur de se les niquer). Le SLDL n'entraîne
-- pas le rachis en mouvement — c'est une charnière de hanche, lombaires isométriques (même
-- catégorie que le plank). Mais son instinct pointe un vrai risque : à 1m97 avec stockage
-- abdominal, le BAS de l'amplitude est exactement là où il s'arrondit (ischios courts +
-- bras de levier énorme). Le risque n'est pas l'exo, c'est les 20 derniers centimètres.
--
-- Le rack réglable (cf. 045) permet de supprimer cette portion : barres de sécurité calées
-- à hauteur de genou = butée physique, impossible de descendre dans la zone à risque.
-- Bénéfice conservé (ischios, fessiers, gainage isométrique), portion dangereuse supprimée.
-- Amplitude réduite volontaire, pas une dégradation.
--
-- Aucun set_log touché — seul `notes` change.

DO $$
DECLARE
  d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 3;

  UPDATE exercises
     SET notes = 'Barres de sécurité à hauteur de GENOU = butée : tu descends jusqu''à toucher, jamais plus bas. '
                 'Barre désenquillée à hauteur de hanche, pas de ramassage au sol. '
                 'Mouvement de hanche (fesses vers l''arrière), dos plat, jambes quasi tendues.'
   WHERE program_day_id = d_mercredi
     AND name = 'Soulevé de terre jambes tendues (barre)';
END $$;
