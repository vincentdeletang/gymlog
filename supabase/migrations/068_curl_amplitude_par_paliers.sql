-- Migration 068 : amplitude du curl, de 90° à presque tendu, par paliers (décision du user, 22/10)
--
-- Ses mots : « je fais jamais d'amplitude complète au curl, j'ai pas envie de me déchirer le
-- biceps, j'arrête à 90° à peu près, je tends jamais les bras ». Donné une fois : le haut de
-- l'amplitude est la moitié la moins productive (Pedrosa 2023 : le bas fait grossir nettement
-- plus, ES 0,89 ; Kassiano 2023 : partielles du haut < complète ≈ partielles du bas), et un
-- tendon se renforce en étant chargé sur toute sa longueur (Lazarczuk 2022, méta de 61 études),
-- pas en étant évité. Il choisit la descente par paliers : chaque semaine un peu plus bas,
-- 2-3 s de descente, jamais verrouillé (10-15° de marge), charge inchangée pendant la descente,
-- amplitude complète en 4-6 semaines. FDR : projects/sante/setup-sport.md, etudes-sport.md § 5.

UPDATE exercises
   SET notes = notes || ' AMPLITUDE (depuis le 26/10) : tu descendais à 90°, tu descends chaque semaine un peu plus bas, descente lente 2-3 s, JAMAIS verrouillé en bas (il reste 10-15°). Semaine 1 : un poil sous 90°. Semaine 4-6 : presque tendu. La charge ne bouge pas tant que tu descends. Le bas du mouvement, c''est là que le biceps grossit et que le tendon se renforce.'
 WHERE name IN ('Curl barre EZ (supination)', 'Curl haltère assis (supination)');
