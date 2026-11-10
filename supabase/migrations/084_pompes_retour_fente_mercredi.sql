-- Migration 084 : pompes serrées de retour (vendredi), fente au mercredi
--
-- Relecture du découpage de la 083, à sa question « c'est le meilleur découpage ? » (10/11/2026) :
--   1. La 083 avait sorti les pompes serrées, or c'était la dose minimale de pecs voulue par le user
--      (setup-sport, 20/10). Elles reviennent le vendredi, même id, set_logs restaurés depuis
--      supabase/backups/ : historique et progression intacts.
--   2. Le vendredi de la 083 portait 12 séries + bird dog (~55 min) et le mercredi 10. La fente passe
--      au mercredi : mercredi 11 séries, vendredi 12 avec les pompes, les jambes chargées deux fois
--      par semaine (fente mer, SLDL ven) au lieu d'une, jamais deux matins de suite.

INSERT INTO exercises (id, program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, setup, notes)
VALUES ('021d1277-9258-4c9c-a7e1-d45d63e14a80',
        (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5),
        'Pompes serrées mains surélevées (banc)', 3, 3, '8-15/jusqu''à 2 en réserve', true, 'main', 'chest', false,
        'Banc plat, cran 1',
        'Cible : TRICEPS d''abord, pec en indirect. Banc PLAT (cran 1), mains sur le banc LARGEUR D''ÉPAULES, pas plus, coudes qui restent le long du corps (pas écartés). Descendre la poitrine vers le bord du banc : c''est lui qui t''empêche de passer les coudes derrière le torse (épaule G). Remontée contrôlée, sans verrouiller sec. PROGRESSION : les reps jusqu''à 15 sur les 3 séries, puis les mains descendent d''un cran (barres de sécurité plus bas).');

INSERT INTO set_logs (id, session_id, exercise_id, set_number, weight_kg, reps_done, rir, logged_at) VALUES
  ('8540de24-ceb2-4c25-ba39-a0ba28aa57ea', '60475da2-5bdb-4066-aa3f-b0c1a5a31731', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-08-14T15:48:55.306Z'),
  ('27010ecd-8fa8-4377-869c-6153946aa218', '60475da2-5bdb-4066-aa3f-b0c1a5a31731', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-08-14T15:50:37.113Z'),
  ('40613d45-8ab7-4dd4-bf11-a12788fb0e72', '60475da2-5bdb-4066-aa3f-b0c1a5a31731', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 11, 0, '2026-08-14T15:53:04.004Z'),
  ('a48505e7-e833-4698-b1e0-863862df234f', '52c5dfee-1090-4fd3-a225-16912d6aaf2e', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-08-21T15:35:47.587Z'),
  ('3a020dbb-646b-4d9c-a780-abc8a220be9d', '52c5dfee-1090-4fd3-a225-16912d6aaf2e', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-08-21T15:37:28.607Z'),
  ('52ae8399-4c52-4dbe-a4e1-5039b5d113b1', '52c5dfee-1090-4fd3-a225-16912d6aaf2e', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 12, 1, '2026-08-21T15:39:48.727Z'),
  ('ed3d3681-d7cd-4bd4-99d4-b66659a42e67', '0a1c52d6-b32f-4a57-936c-81c5a44c66e3', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-08-28T10:37:03.315Z'),
  ('3eadf65f-a1dc-4110-8874-5e5e72824798', '0a1c52d6-b32f-4a57-936c-81c5a44c66e3', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-08-28T10:38:25.815Z'),
  ('ff5a5515-56d5-4c84-8993-7352a6821617', '0a1c52d6-b32f-4a57-936c-81c5a44c66e3', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 12, 0, '2026-08-28T10:40:15.495Z'),
  ('9f433d51-095e-489e-812f-7dd11143c008', 'ae6a918c-c29e-476e-af41-300d753f1c2d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 12, 2, '2026-09-04T11:59:11.832Z'),
  ('ba01bf30-3cad-47df-9429-cb75dfe870ed', 'ae6a918c-c29e-476e-af41-300d753f1c2d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 1, '2026-09-04T12:01:03.502Z'),
  ('3f00f433-d748-4d3b-8521-f186d9f682d1', 'ae6a918c-c29e-476e-af41-300d753f1c2d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 1, '2026-09-04T12:03:10.044Z'),
  ('d2a487c7-82d1-47da-b040-53e99d6d0631', 'ede3c5ad-93ec-484a-91e1-68f2fbfbcb4d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 1, '2026-09-11T15:08:26.470Z'),
  ('68f948b7-8270-4848-b62f-550ee6da4082', 'ede3c5ad-93ec-484a-91e1-68f2fbfbcb4d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 1, '2026-09-11T15:10:07.135Z'),
  ('7b81537e-b6c9-495a-aa00-c86eb27841a2', 'ede3c5ad-93ec-484a-91e1-68f2fbfbcb4d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 1, '2026-09-11T15:12:32.155Z'),
  ('ae706c47-5475-462a-9e45-b40a2326f0f2', '92abf8d1-3ee7-4e93-a619-d349324fabc4', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-09-18T14:44:31.243Z'),
  ('4df7ea00-d83a-41df-a35b-c35dd85cf091', '92abf8d1-3ee7-4e93-a619-d349324fabc4', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-09-18T14:46:25.130Z'),
  ('85ba5eab-e6ff-4355-912b-7b54507097f9', '92abf8d1-3ee7-4e93-a619-d349324fabc4', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 2, '2026-09-18T14:48:31.205Z'),
  ('c3088856-eb58-4aad-b8d7-dccb4b973320', '82254dfd-20cb-4487-92c9-a50e9cf8fcc4', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-09-25T15:03:09.085Z'),
  ('81375d90-aaad-4c9d-9cb5-a107b6c5cc14', '82254dfd-20cb-4487-92c9-a50e9cf8fcc4', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-09-25T15:05:32.021Z'),
  ('8ff8ac18-ee3c-401f-a2cb-a2d5b430b693', '82254dfd-20cb-4487-92c9-a50e9cf8fcc4', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 2, '2026-09-25T15:07:55.815Z'),
  ('fb143f89-5467-4a7c-ab6a-86146e296d80', '45b41ccd-ed3f-4bdc-8184-dd6843534d3d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-10-02T11:05:05.375Z'),
  ('93ecceca-3a4f-478e-825e-ec5a56007973', '45b41ccd-ed3f-4bdc-8184-dd6843534d3d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-10-02T11:07:04.620Z'),
  ('6d0d7896-1651-48df-a9aa-db8e969bf3d4', '45b41ccd-ed3f-4bdc-8184-dd6843534d3d', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 2, '2026-10-02T11:09:30.033Z'),
  ('01f65a94-49d9-4edf-a04d-69c40bc35c3d', 'b957f7d8-03fa-44f2-a8fb-f9456dd41f91', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-10-20T15:35:26.685Z'),
  ('ecc95b79-8f81-4c5b-9c2b-8bae89e61be1', 'b957f7d8-03fa-44f2-a8fb-f9456dd41f91', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-10-20T15:37:46.829Z'),
  ('8a3fbc8d-3822-4df4-8823-9ffc1eee2312', 'b957f7d8-03fa-44f2-a8fb-f9456dd41f91', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 1, '2026-10-20T15:40:56.126Z'),
  ('f1fb556b-5de1-475e-bc7c-1d5958bd0b40', '5533a14d-dae9-4f8c-be71-2057b82e23b9', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-10-27T13:12:33.294Z'),
  ('154ad386-2120-4294-bab0-8227dcc51576', '5533a14d-dae9-4f8c-be71-2057b82e23b9', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-10-27T13:14:33.100Z'),
  ('5497ce18-cf3b-4cf5-a4b1-72b1a33f89eb', '5533a14d-dae9-4f8c-be71-2057b82e23b9', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 2, '2026-10-27T13:16:56.821Z'),
  ('5a77387f-e8ad-459b-8ac1-be46d0e87f18', 'fbc8202f-663f-424e-9450-77e96932f082', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 1, NULL, 15, 2, '2026-11-03T07:44:55.914Z'),
  ('852bc525-bff0-40b5-bd52-94b39b782ee0', 'fbc8202f-663f-424e-9450-77e96932f082', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 2, NULL, 15, 2, '2026-11-03T07:50:15.822Z'),
  ('a2a57938-96ef-47a1-ba1a-e0ce87d10b77', 'fbc8202f-663f-424e-9450-77e96932f082', '021d1277-9258-4c9c-a7e1-d45d63e14a80', 3, NULL, 15, 1, '2026-11-03T07:52:06.773Z');

UPDATE exercises SET order_index = 5 WHERE id = '2e41e3ab-d52f-4884-a238-cbc00395064a';   -- SLDL en dernier le vendredi

UPDATE exercises SET program_day_id = (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3),
                     order_index = 4
 WHERE id = '249a276c-a264-47a6-a7ce-27134bbe1bd3';                                          -- Fente -> mercredi

UPDATE program_days
   SET notes = replace(notes, ' Depuis la 083 : face pulls en fin de séance (venus du mardi).', ' Depuis la 083-084 : face pulls puis 3 séries de fente poids de corps en fin de séance.')
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 3;

UPDATE program_days
   SET notes = 'Vendredi. Bird dog coché, 3 curls ⇄ 3 overhead (même barre, même charge), 3 séries de pompes serrées, le SLDL (20 kg de disques, figé, butée au genou), puis 20 min de zone 2. ~55 min.'
 WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week = 5;
