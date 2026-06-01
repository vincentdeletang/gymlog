-- 037_drop_xp_levels.sql
--
-- Suppression du système XP / niveaux (gamification cosmétique sans valeur pour
-- un usage solo : pas de classement, seuils arbitraires, "gamable" par le user
-- qui code l'app). On garde le STREAK (seul mécanisme appuyé par la science du
-- comportement, et aligné sur la contrainte n°1 = adhérence) : colonnes
-- streak_current / streak_best / last_session_date conservées.
--
-- Colonnes droppées :
--   - program_days.xp_reward
--   - user_state.xp_total
--   - user_state.level

ALTER TABLE program_days DROP COLUMN IF EXISTS xp_reward;
ALTER TABLE user_state   DROP COLUMN IF EXISTS xp_total;
ALTER TABLE user_state   DROP COLUMN IF EXISTS level;
