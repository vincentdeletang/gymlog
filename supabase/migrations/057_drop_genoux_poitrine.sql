-- Migration 057 : Retrait du genoux-poitrine (cooldown) sur les 5 jours
--
-- Question du user (19/10/2026) : "le genoux-poitrine à chaque jour, vraiment utile ?" Non :
-- 60 s d'étirement passif du bas du dos, aucun renforcement, pas de "décompression" mesurable,
-- preuves minces. Ses mots : "je le fais pour cocher". Mais : "quand j'étais plus jeune j'avais
-- tendance à le faire instinctivement dans le lit quand mon dos tirait et ça me faisait du bien".
-- Les deux sont vrais : c'est un outil de SOULAGEMENT, pas d'entraînement. Sa place est le lit
-- quand le dos tire (noté dans FDR, `projects/sante/setup-sport.md`), pas une case dans l'app.
--
-- DROP des 5 lignes (une par jour de séance). Set_logs (62) sauvegardés dans
-- supabase/backups/genoux_poitrine_set_logs.json. Le cooldown disparaît : la séance se termine
-- par la zone 2 (056). Aucun autre exo touché.

DELETE FROM set_logs
 WHERE exercise_id IN (SELECT id FROM exercises WHERE name = 'Genoux-poitrine');

DELETE FROM exercises WHERE name = 'Genoux-poitrine';
