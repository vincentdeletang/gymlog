-- 036_friday_triceps_short_notes.sql
--
-- Raccourcit les descriptions des 2 exos triceps du vendredi à l'essentiel.
-- Le user a assimilé l'exécution (overhead 22kg testé, sensations triceps OK,
-- aucune douleur épaule/coude) : on retire le tutoriel détaillé et on garde
-- ce qui compte au quotidien — l'ANGLE DU BANC (le cue le plus facile à oublier
-- et qui change tout) + 1-2 cues clés. Pour la barre au front on conserve la
-- mise en garde coudes (sécurité tendineuse).

DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  -- Extensions overhead barre EZ : banc vertical, coudes fixes
  UPDATE exercises
     SET notes = 'Dossier VERTICAL (~85-90°). Barre derrière la nuque, coudes pointés au plafond et fixes (ne pas les écarter). Cible : longue portion étirée.'
   WHERE program_day_id = d_vendredi
     AND name = 'Extensions overhead barre EZ';

  -- Barre au front : banc plat, coudes fixes, garde la sécurité tendineuse
  UPDATE exercises
     SET notes = 'Banc PLAT (0°). Bras légèrement inclinés vers la tête, coudes fixes pointés au plafond. Descendre vers le front, s''arrêter ~5cm avant.

Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse.'
   WHERE program_day_id = d_vendredi
     AND name = 'Barre au front';
END $$;
