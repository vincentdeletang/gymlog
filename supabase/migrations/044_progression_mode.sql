-- Migration 044 : Mode de progression par exercice (charge ⇄ reps)
--
-- CONTEXTE : la surcharge progressive n'existait que sur UNE variable, la charge.
-- Règle unique : reps au max de la plage + RIR >= 2 → +2kg. Ça marche tant qu'on veut
-- monter en charge indéfiniment.
--
-- Or le user a une contrainte explicite : "l'idée c'était de monter en poids jusqu'à ce
-- que je sente que c'est assez lourd et de stabiliser à ce poids, j'ai pas envie de trop
-- pousser car j'ai pas envie de me faire des blessures." Cohérent avec ses objectifs #2
-- (santé/longévité) et #3 (éviter les blessures), qui passent avant l'hypertrophie.
--
-- Le problème n'était donc pas qu'il refusait la charge — c'est que refuser la charge
-- supprimait TOUTE progression : plage `10-12`, il est à 12, charge figée → plus aucune
-- surcharge, donc plus aucune raison pour le muscle de grossir. Constaté en base : curl
-- barre EZ bloqué à 36kg × 12 × RIR 2 pendant 8 séances (15/06 → 03/08), alors que
-- l'app lui proposait 38kg à chaque fois.
--
-- SOLUTION : un mode par exercice. Le user décide quelle variable monte.
--   'weight' (défaut, comportement actuel) : reps plafonnées par reps_target, charge +2kg
--   'reps'   : charge FIGÉE à la dernière valeur loggée, objectif +1 rep par séance
--
-- En mode 'reps', `reps_target` ne pilote plus rien : l'objectif du jour = reps de la
-- séance précédente + 1 (si RIR >= 2), plafonné à 20 reps côté front (REPS_CEILING).
-- Au plafond l'app propose d'ajouter 2kg — proposition, jamais automatique : c'est lui
-- qui décide quand la charge bouge. Bénéfice sécurité : dans ce schéma il n'augmente la
-- charge que quand il tient déjà 20 reps avec, au lieu de 12 aujourd'hui.
--
-- Marche aussi pour les exos au poids de corps (pompes mains surélevées de la 043),
-- qui n'avaient aucune suggestion jusqu'ici faute de charge à incrémenter.
--
-- Bascule depuis l'app : SetLogModal, sous le badge de progression (RLS OK, policy
-- UPDATE sur `exercises` ouverte depuis la migration 017).
--
-- Aucun set_log touché.

ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS progression_mode TEXT NOT NULL DEFAULT 'weight';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'exercises_progression_mode_check'
  ) THEN
    ALTER TABLE exercises
      ADD CONSTRAINT exercises_progression_mode_check
      CHECK (progression_mode IN ('weight', 'reps'));
  END IF;
END $$;

-- Curl barre EZ : le user a explicitement dit que 36kg est assez lourd pour lui.
-- On le bascule d'office — les autres exos restent en mode 'weight', il les bascule
-- lui-même depuis l'app quand il juge la charge suffisante.
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  UPDATE exercises
     SET progression_mode = 'reps'
   WHERE program_day_id = d_lundi
     AND name = 'Curl barre EZ (supination)';
END $$;
