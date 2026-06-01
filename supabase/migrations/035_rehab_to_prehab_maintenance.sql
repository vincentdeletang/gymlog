-- Migration 035 : Rehab épaule → dose d'entretien (prehab)
--
-- Contexte : l'épaule gauche du user va nettement mieux, il ne la sent que
-- rarement. Le protocole rehab a fait son travail. On NE supprime PAS le bloc
-- (récidive classique chez profil 136 kg + poussée + douleurs récurrentes ;
-- cf. objectifs #2 santé/posture et #3 éviter blessures, prioritaires sur
-- l'hypertrophie). On passe de dose thérapeutique à dose d'entretien.
--
-- CHANGE (lundi + vendredi) :
--   - "Rotations externes élastique" : 3×15 → 2×15
--   - "Face pulls élastique"         : 3×15 → 2×15
--
-- GARDÉS tels quels :
--   - "Stretch doorway" 2×30s : utile pour la posture (capsule antérieure /
--     enroulement d'épaules) indépendamment de la douleur. Programmé et non
--     "à la demande" car le user ne tient pas les habitudes non-loggables.
--
-- Aucun set_log supprimé : on ne change que sets_target.

DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE exercises
     SET sets_target = 2
   WHERE program_day_id IN (d_lundi, d_vendredi)
     AND name IN ('Rotations externes élastique', 'Face pulls élastique');
END $$;
