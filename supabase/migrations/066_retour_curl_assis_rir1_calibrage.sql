-- Migration 066 : retour du curl haltère assis (le curl pupitre de la 065 est retiré avant
-- d'avoir servi), dernière série à 1 en réserve sur tous les exos bras, calibrage mensuel.
--
-- Le user (22/10, le soir même) : « debout penché avec le bras sur le banc relevé, ça me
-- paraît foireux pour le dos ». Il a raison : à 1m97 derrière un dossier à 45°, c'est un torse
-- incliné tenu 40 s par série, la posture qu'on retire partout ailleurs. Aucune autre façon
-- d'avoir un pupitre sans sol ni ventre contre le banc → on supprime au lieu d'optimiser :
-- le curl EZ debout en amplitude complète passe déjà par la position étirée (Kassiano 2023 :
-- amplitude complète ≈ partielles étirées), le gain du pupitre est régional et petit.
-- Le curl assis revient avec son id d'origine et ses 9 logs (restaurés depuis
-- supabase/backups/curl_halt_re_assis_supination_set_logs.json).
--
-- RIR : « je n'ai jamais eu mal au coude » (ses mots) → la prudence sur l'overhead et la barre
-- au front était une précaution, pas un historique. Dernière série à 1 en réserve sur TOUS
-- les exos bras (Refalo 2024, Robinson 2024) ; la règle « ça tire sur le tendon → tu arrêtes »
-- reste le garde-fou. Le 1er lundi du mois, la 4e série du curl EZ va à l'échec vrai : c'est
-- le seul moyen de savoir ce que vaut son « 2 en réserve » (les débutants surestiment le RIR).
-- Le badge 10-15 reste : en mode charge l'app ne lit cette plage que pour proposer +2 kg
-- quand la 1re série tape 15 avec 2 en réserve ; les reps ne sont jamais pré-remplies.

DO $$
DECLARE d_mer uuid; d_lun uuid; d_ven uuid;
BEGIN
  SELECT pd.id INTO d_lun FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  DELETE FROM set_logs WHERE exercise_id IN (SELECT id FROM exercises WHERE name LIKE 'Curl pupitre un bras%');
  DELETE FROM exercises WHERE name LIKE 'Curl pupitre un bras%';

  INSERT INTO exercises (id, program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, bar_id, notes)
  VALUES ('3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', d_mer, 'Curl haltère assis (supination)', 3, 3, '10-15', false, 'main', 'biceps', false, 'weight',
          (SELECT id FROM bars WHERE name = 'Haltère'),
          'Après la barre au front, banc redressé en VERTICAL cran 6. Assis dos calé contre le dossier, coude au corps (jamais en arrière : c''est la position qui étirait le tendon du chef long de l''épaule G). Un seul haltère → bras par bras en alterné, une ligne de log par série pour les deux bras. Départ paume neutre, SUPINATION COMPLÈTE en montant, squeeze 1s en haut, descente lente. La série va jusqu''à 2 en réserve, la dernière jusqu''à 1 : tu logues les reps que ça donne, la plage 10-15 n''est que le déclencheur du +1 kg (15 atteintes avec 2 en réserve). PETITS disques (2 × 5 + 1 kg), plafond pratique ~15 kg de disques ; au plafond, tu montes les reps jusqu''à 20 près de l''échec au lieu de stagner.')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO set_logs (id, session_id, exercise_id, set_number, weight_kg, reps_done, rir, logged_at) VALUES
  ('b935b37d-4c05-41fa-a0e1-0d409cb5be83', '82254dfd-20cb-4487-92c9-a50e9cf8fcc4', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 1, 10, 12, 3, '2026-09-25T15:10:23.263Z'),
  ('7670b095-0166-4c00-bb2e-cbaa4ac1192d', '82254dfd-20cb-4487-92c9-a50e9cf8fcc4', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 2, 10, 12, 3, '2026-09-25T15:11:57.708Z'),
  ('0f01efcb-8080-45fe-a670-0d434fc7aedf', '82254dfd-20cb-4487-92c9-a50e9cf8fcc4', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 3, 10, 12, 3, '2026-09-25T15:15:01.087Z'),
  ('cc7cc811-1e1d-4cc9-8dee-4575168f7077', '45b41ccd-ed3f-4bdc-8184-dd6843534d3d', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 1, 12, 12, 3, '2026-10-02T11:11:23.052Z'),
  ('158fd55e-238a-424e-b4fa-32c194c99556', '45b41ccd-ed3f-4bdc-8184-dd6843534d3d', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 2, 12, 12, 3, '2026-10-02T11:14:03.502Z'),
  ('1ff7cb4e-ba48-447f-9005-6aeb22b7a56c', '45b41ccd-ed3f-4bdc-8184-dd6843534d3d', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 3, 12, 12, 3, '2026-10-02T11:18:06.753Z'),
  ('24ff6079-3839-4eef-877c-93330b7f5b72', '0c3f3d5d-91f3-403c-8d40-df91cd29f7f7', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 1, 12, 12, 4, '2026-10-21T14:56:13.204Z'),
  ('de64986f-7132-4ac0-947d-4ad76ab1074a', '0c3f3d5d-91f3-403c-8d40-df91cd29f7f7', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 2, 12, 12, 4, '2026-10-21T14:57:44.885Z'),
  ('7ad942c2-5751-4651-95dc-9df5cfd4841b', '0c3f3d5d-91f3-403c-8d40-df91cd29f7f7', '3334c9ec-63d9-4fed-ae83-ff6ae24e1ac1', 3, 12, 12, 4, '2026-10-21T14:59:22.112Z')
  ON CONFLICT (id) DO NOTHING;

  UPDATE exercises SET notes = 'Banc PLAT, cran 1 (0°). Bras légèrement inclinés vers la tête, coudes FIXES pointés au plafond. Descendre vers le front, stop ~5cm avant. Une seule fois par semaine, c''est ici. Dernière série à 1 en réserve ; si ça tire sur le tendon du coude pendant une série, tu arrêtes la série, c''est le seul garde-fou. Puis tu redresses le banc pour le curl assis.'
   WHERE name = 'Barre au front';

  UPDATE exercises SET notes = 'EN ALTERNÉ avec le curl EZ : même barre, même charge, tu passes de l''un à l''autre sans toucher un disque. Double progression courte : 10 à 15 reps, la séance où la 1re série fait 15 avec 2 en réserve, +2 kg et retour à 10. Banc VERTICAL, cran 6 (~90°). Barre derrière la nuque, coudes pointés au plafond et FIXES, descente profonde. Pas un press : la charge ne monte pas, ce sont les coudes qui se déplient. Ton meilleur exo triceps, la littérature le confirme (Maeo 2023). 4e série à 1 en réserve.'
   WHERE name = 'Extensions overhead barre EZ' AND program_day_id = d_lun;
  UPDATE exercises SET notes = 'Même règle que le lundi : 10 à 15 reps, 15 avec 2 en réserve → +2 kg, retour à 10. Tape la charge du lundi. EN ALTERNÉ avec le curl EZ, même barre, même charge. Banc VERTICAL, cran 6. Barre derrière la nuque, coudes pointés au plafond et FIXES, descente profonde. Pas un press. 4e série à 1 en réserve.'
   WHERE name = 'Extensions overhead barre EZ' AND program_day_id = d_ven;

  UPDATE exercises SET notes = 'EN ALTERNÉ avec l''overhead : une série de curl, une série d''overhead, même barre. Chaque série va jusqu''à 2 en réserve, la 4e jusqu''à 1 : tu logues les reps que ça donne. La plage 10-15 n''est que le déclencheur : la séance où la 1re série fait 15 avec 2 en réserve, +2 kg et retour à 10. Coudes collés ou LÉGÈREMENT DEVANT le corps, jamais derrière, pas de balancement, descente contrôlée. LE 1er LUNDI DU MOIS : la 4e série va à l''échec vrai (la barre ne monte plus), tu logues 0 en réserve. C''est ton calibrage : si tu fais 6 reps de plus que d''habitude, ton « 2 en réserve » en valait 8.'
   WHERE name = 'Curl barre EZ (supination)' AND program_day_id = d_lun;
END $$;
