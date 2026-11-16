-- Migration 086 : curl EZ (lundi, vendredi) → curl haltère debout
--
-- 16/11/2026, le soir de la 085. Ses mots : « c la barre ez c sur et si jla prend plus large c comme si
-- jprenait une barre droite donc bon ». Le curl haltère du mercredi ne fait pas mal : c'est la barre.
-- La prise large de la 085 ne tient pas (barre droite = supination forcée, même souci). L'haltère laisse
-- le poignet tourner seul. Un seul haltère : bras par bras, en alterné avec l'overhead EZ, qui ne bouge pas.
-- Coût : le lundi s'allonge de ~5 min (4 séries × 2 bras). Logs EZ sauvegardés dans supabase/backups.

DO $$
DECLARE d_lun uuid; d_ven uuid; halt uuid;
BEGIN
  SELECT pd.id INTO d_lun FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;
  SELECT id INTO halt FROM bars WHERE name = 'Haltère';

  DELETE FROM set_logs WHERE exercise_id IN (SELECT id FROM exercises WHERE name = 'Curl barre EZ (supination)');
  DELETE FROM exercises WHERE name = 'Curl barre EZ (supination)';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, bar_id, superset_group, notes)
  VALUES
  (d_lun, 'Curl haltère debout (supination)', 6, 4, '10-15/jusqu''à 2 en réserve, 4e à 1', false, 'main', 'biceps', false, 'weight', halt, 'A',
   'Remplace le curl EZ depuis le 16/11 (la barre faisait mal aux avant-bras). DÉPART : la charge du curl assis du mercredi. EN ALTERNÉ avec l''overhead EZ : une série de curl (bras droit puis gauche, une ligne de log pour les deux), une série d''overhead. Debout, coude au corps, DEVANT la hanche, jamais derrière. Départ paume neutre, SUPINATION COMPLÈTE en montant, le poignet trouve seul son angle. Squeeze 1 s en haut, descente lente 2-3 s, jamais verrouillé en bas. Chaque série à 2 en réserve, la 4e à 1. 15 avec 2 en réserve sur la 1re → +1 kg, retour à 10. Plafond pratique ~15 kg de disques : au plafond, les reps montent jusqu''à 20. LE 1er LUNDI DU MOIS : la 4e série à l''échec vrai, tu logues 0 en réserve. Douleur à l''avant-bras > 3/10 : stop la série, dis-le.'),
  (d_ven, 'Curl haltère debout (supination)', 1, 3, '10-15/jusqu''à 2 en réserve, 3e à 1', false, 'main', 'biceps', false, 'weight', halt, 'A',
   'Même exo et même règle que le lundi, tape la charge du lundi. EN ALTERNÉ avec l''overhead EZ. Debout, coude au corps devant la hanche, supination complète en montant, descente lente, jamais verrouillé. 3e série à 1 en réserve.');

  UPDATE exercises SET notes = replace(replace(notes,
         'EN ALTERNÉ avec le curl EZ : même barre, même charge, tu passes de l''un à l''autre sans toucher un disque.',
         'EN ALTERNÉ avec le curl haltère debout.'),
         'EN ALTERNÉ avec le curl EZ, même barre, même charge.',
         'EN ALTERNÉ avec le curl haltère debout.')
   WHERE name = 'Extensions overhead barre EZ';

  UPDATE program_days SET name = 'Bras A · curl haltère ⇄ overhead + zone 2',
         notes = 'Lundi. 8h, tenue posée la veille. Curl haltère debout ⇄ overhead EZ en alterné. Puis 20 min de zone 2 : la journée la plus longue, ~60 min.'
   WHERE id = d_lun;
  UPDATE program_days SET notes = replace(notes, '3 curls ⇄ 3 overhead (même barre, même charge)', '3 curls haltère ⇄ 3 overhead EZ')
   WHERE id = d_ven;
END $$;
