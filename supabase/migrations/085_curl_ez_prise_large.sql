-- Migration 085 : curl EZ, prise large et règle de douleur (avant-bras)
--
-- 16/11/2026, ses mots : douleur dans les 2 avant-bras depuis le passage à 30 kg, côté extérieur, vers le bas
-- (vers le poignet), pire juste après avoir posé la barre. Carrure large : sur la prise étroite de l'EZ,
-- ses avant-bras rentrent vers l'intérieur et le poignet se tord sous la charge. Tendons qui protestent,
-- pas l'os. Geste : prise sur les coudes EXTÉRIEURS de l'EZ, et une règle de sortie vers le curl haltère
-- (le poignet y trouve seul son angle). Le hammer reste interdit (grip, 051).

UPDATE exercises SET notes = 'PRISE (depuis le 16/11, douleur aux avant-bras) : mains sur les coudes EXTÉRIEURS de la barre, le plus large que l''EZ permet, poignets dans l''axe des avant-bras, jamais cassés vers l''intérieur. DOULEUR : au-delà de 3/10 pendant une série, ou encore là le lendemain matin → la série s''arrête et le curl EZ passe au curl haltère (dis-le, la grille change). ' || notes
WHERE name = 'Curl barre EZ (supination)'
  AND program_day_id IN (SELECT id FROM program_days WHERE program_id = '0ab65b42-5e7f-4f63-9f3a-9d112fd0d8e3' AND day_of_week IN (1, 5));
