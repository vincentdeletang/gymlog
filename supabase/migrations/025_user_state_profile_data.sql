-- Profil utilisateur libre (texte) pour export IA auto-suffisant.
-- 2 champs texte libre stockés en JSON pour rester flexible :
--   { "profil": "...", "objectifs": "..." }
-- Pas de valeur par défaut : chaque user remplit depuis Settings (et la première
-- fois on peut UPDATE manuellement dans le SQL Editor pour pré-remplir).

ALTER TABLE user_state ADD COLUMN IF NOT EXISTS profile_data jsonb;
