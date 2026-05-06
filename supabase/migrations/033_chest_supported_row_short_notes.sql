-- 033_chest_supported_row_short_notes.sql
--
-- Raccourcit la description du Chest-supported row haltère à l'essentiel.
-- L'exo est en place depuis 031, le user le connaît : on retire le tutoriel
-- détaillé (setup verbeux, "première séance", "attention bide") et on garde
-- uniquement les cues qui font sentir le DOS plutôt que le biceps.

DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  UPDATE exercises
     SET notes = 'Cible : grand dorsal + milieu du dos.

Banc 30°, face contre le dossier. Tirer le COUDE vers la HANCHE en initiant par l''omoplate (omoplate AVANT bras). Descente lente 3s, étirement complet en bas.

Si tu sens le biceps = allège et pense "omoplate d''abord".'
   WHERE program_day_id = d_lundi
     AND name = 'Chest-supported row haltère';
END $$;
