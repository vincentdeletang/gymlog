-- Migration 081 : retrait de la mobilité du samedi (open book, pigeon modifié)
--
-- Audit du programme (03/11/2026) : la « Récupération active » du samedi n'a été faite qu'une
-- fois, le 25/04 (2 logs par exo). Une ligne que personne ne fait ment sur le programme ; le user
-- choisit de la retirer. Le samedi reste un jour de repos (type 'rest'), la journée existe toujours.
-- Set_logs sauvegardés dans supabase/backups/open_book_set_logs.json et
-- pigeon_modifi_sur_le_dos_set_logs.json. Aucun autre exo touché.

DELETE FROM set_logs
 WHERE exercise_id IN (SELECT id FROM exercises WHERE name IN ('Open book', 'Pigeon modifié (sur le dos)'));

DELETE FROM exercises WHERE name IN ('Open book', 'Pigeon modifié (sur le dos)');
