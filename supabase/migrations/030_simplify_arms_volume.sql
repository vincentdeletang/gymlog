-- Migration 030 : Simplification volume bras (priorité adhérence + rééquilibrage triceps>biceps)
--
-- VENDREDI :
--   - Drop "Kickbacks haltères" (user ne sent pas les triceps sur cet exo, peu efficace pour lui)
--   - Drop "Farmer's carry" (1 seul haltère dispo, pickup risqué pour lombaires faibles à 136kg)
--   - "Plank" 3 → 2 sets (compromis adhérence vs stabilisation lombaire)
--   - "Extensions triceps barre EZ" renommé en "Extensions overhead barre EZ" (clarification :
--     l'exo réellement effectué est de l'overhead, pas du skull crusher — banc quasi-vertical)
--   - Ajout "Barre au front" (skull crusher EZ) : complément en position mi-longueur pour
--     stimuler la longue portion du triceps à une 2e amplitude (lengthened-bias bonus)
--
-- LUNDI :
--   - Drop "Curl haltère concentré" (volume biceps compressé en déficit, alignement CLAUDE.md)
--   - "Curl barre EZ (supination)" 4 → 3 sets (rééquilibrage biceps/triceps : pour gros bras
--     le triceps représente ~60-65% du volume du bras donc doit recevoir + de stimulus direct)

-- ============================================================
-- LUNDI
-- ============================================================
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
  FROM program_days pd
  JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 1;

  -- Drop set_logs avant l'exo (FK constraint) — détruit l'historique du curl concentré
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
     WHERE program_day_id = d_lundi AND name = 'Curl haltère concentré'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_lundi
     AND name = 'Curl haltère concentré';

  UPDATE exercises
     SET sets_target = 3
   WHERE program_day_id = d_lundi
     AND name = 'Curl barre EZ (supination)';
END $$;

-- ============================================================
-- VENDREDI
-- ============================================================
DO $$
DECLARE
  d_vendredi UUID;
  bar_ez     UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
  FROM program_days pd
  JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 5;

  SELECT id INTO bar_ez FROM bars WHERE name = 'Barre EZ';

  -- Drop set_logs avant les exos (FK constraint) — détruit l'historique de ces exos
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
     WHERE program_day_id = d_vendredi
       AND name IN ('Kickbacks haltères', 'Farmer''s carry')
   );

  -- Drop kickbacks (libère order 8)
  DELETE FROM exercises
   WHERE program_day_id = d_vendredi
     AND name = 'Kickbacks haltères';

  -- Drop farmer's carry
  DELETE FROM exercises
   WHERE program_day_id = d_vendredi
     AND name = 'Farmer''s carry';

  -- Plank : 3 → 2 sets
  UPDATE exercises
     SET sets_target = 2
   WHERE program_day_id = d_vendredi
     AND name = 'Plank';

  -- Renommer + clarifier la description (overhead, banc 85-90°)
  UPDATE exercises
     SET name = 'Extensions overhead barre EZ',
         notes = 'EXÉCUTION : Assis sur le banc, dossier le plus VERTICAL possible (~85-90°, PAS 30° comme le développé incliné — sinon les bras ne peuvent pas vraiment passer au-dessus de la tête et tu perds le bénéfice principal). Tenir la barre EZ bras tendus au-dessus du crâne, prise pronation sur les courbes intérieures. COUDES POINTÉS VERS LE PLAFOND, fixes : ils ne bougent pas, ne s''écartent pas vers l''extérieur. Descendre la barre derrière la nuque en pliant uniquement les coudes. Remonter en extension contrôlée, pas de verrouillage brutal en haut. CIBLE : longue portion du triceps en position étirée maximale (épaule en flexion 180° + coude fléchi = double étirement de la longue portion qui croise les 2 articulations).'
   WHERE program_day_id = d_vendredi
     AND name = 'Extensions triceps barre EZ';

  -- Ajout "Barre au front" (skull crusher EZ) à l'order 8 (libéré par le drop kickbacks)
  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_vendredi AND name = 'Barre au front') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
    VALUES (
      d_vendredi,
      'Barre au front',
      8,
      3,
      '10-12',
      false,
      'EXÉCUTION : Allongé sur le banc PLAT (0°). Tenir la barre EZ bras tendus, légèrement INCLINÉS VERS LA TÊTE (pas strictement perpendiculaires au sol — ça maintient la tension sur le triceps en haut et réduit le levier sur le coude). Coudes fixes, pointés vers le plafond, ne pas les écarter latéralement. Descendre la barre vers le HAUT du front : s''arrêter ~5cm AVANT de toucher le front (préserver les coudes, pas besoin de full ROM). Remonter en extension contrôlée sans verrouillage brutal. CIBLE : longue portion du triceps en position mi-longueur (complément de l''overhead qui couvre l''étirement max). ATTENTION COUDES : exo très exigeant pour les tendons. Charge MODÉRÉE, jamais forcer si douleur tendineuse. Si le coude souffre après 2-3 séances, on ré-évalue.',
      'main',
      bar_ez
    );
  END IF;
END $$;
