-- Migration 065 : programme bras ajusté sur la littérature (demande du user, 22/10/2026 :
-- « envoie des agents faire des recherches scientifiques pour l'hypertrophie des bras »).
-- Sources et chiffres : FDR projects/sante/etudes-sport.md, sections 4 et 5.
--
-- 1) MERCREDI — Curl haltère assis → Curl pupitre un bras sur le dossier (TEST).
--    Le curl assis doublonne le curl EZ debout (même position raccourcie en haut). Le curl
--    pupitre travaille le bas de l'amplitude, muscle étiré, épaule fléchie ~45° : Pedrosa 2023
--    (ES 0,89 sur la partie basse du biceps), Sato 2021 (+8,9 % vs +3,4 % en 5 semaines),
--    Zabaleta-Korta 2023 (seul le pupitre a fait grossir), Oliveira 2009 (chef long maximal
--    près du bras tendu au pupitre, en haut au curl debout : les deux se complètent). Épaule
--    fléchie = tendon du chef long relâché (Lamplot 2020, cadavres : l'extension d'épaule le
--    met en surtension) → compatible avec son épaule gauche, l'inverse du curl incliné.
--    TEST parce que le setup (debout derrière le banc, bras sur le haut du dossier au cran 3
--    ou 4) n'a jamais été essayé à 1m97 / 134 kg : s'il doit se pencher ou que le ventre
--    bloque, le curl assis revient (9 logs sauvegardés, supabase/backups).
-- 2) VENDREDI — curl EZ et overhead EZ : 3 → 4 séries. Volume ~10 → ~11 directes par muscle
--    (Baz-Valle 2022 : 12-20 ; Schoenfeld 2019 : 5 séries/séance > 1 pour le biceps, 3 vs 5
--    rien ; Pelland 2025 : l'indirect compte 0,5, les pompes serrées = 1,5 triceps).
--    Le vendredi était la séance courte (6 séries), il passe à 8, dans la règle 7-11.
-- 3) RIR — dernière série de chaque curl à 1 en réserve (Refalo 2024 : 1-2 RIR = échec ;
--    Robinson 2024 : l'hypertrophie monte vers l'échec). Overhead et barre au front restent
--    à 2 (tendon du coude). Pas de changement de plage : 10-15, décidé le 19/10 ; au plafond
--    de l'haltère (17 kg), 20-30 reps près de l'échec valent autant (Schoenfeld 2015,
--    biceps +8,6 % vs +5,3 %, ns) : c'est la sortie de secours, pas le défaut.
-- 4) OVERHEAD — rien ne change, la littérature le confirme comme l'exo triceps n°1
--    (Maeo 2023 : triceps entier +19,9 % vs +13,9 % bras le long du corps).

DO $$
DECLARE d_mer uuid; d_ven uuid;
BEGIN
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  -- 1) Mercredi : curl assis → curl pupitre (TEST)
  DELETE FROM set_logs WHERE exercise_id IN (SELECT id FROM exercises WHERE name = 'Curl haltère assis (supination)');
  DELETE FROM exercises WHERE name = 'Curl haltère assis (supination)';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, section, muscle_group, is_per_side, progression_mode, bar_id, notes)
  VALUES (d_mer, 'Curl pupitre un bras (haltère, dossier) — TEST', 3, 3, '10-15', false, 'main', 'biceps', false, 'weight',
          (SELECT id FROM bars WHERE name = 'Haltère'),
          'TEST du setup : si tu dois te pencher, ou que le ventre bloque, tu arrêtes et tu me le dis, le curl assis revient. SETUP : dossier au cran 3 (~45°), tu te mets DEBOUT DERRIÈRE le banc, l''aisselle calée sur le haut du dossier, le bras posé à plat dessus, coude DEVANT toi (épaule fléchie = tendon du chef long relâché, c''est l''inverse du curl incliné). Prends l''haltère posé sur le banc, jamais au sol. EXÉCUTION : descente lente jusqu''à presque tendu, JAMAIS verrouillé en bas (c''est là que le coude encaisse), montée en supination, descente contrôlée. 10-15 reps, un bras puis l''autre, une ligne de log pour les deux. Dernière série à 1 en réserve, puis 3-4 demi-reps dans la moitié BASSE (position étirée). Démarre à 10 kg de disques. Progression : 15 reps avec 1-2 en réserve → +1 kg, retour à 10. Au plafond de l''haltère (15 kg de disques), tu montes les reps jusqu''à 20-30 près de l''échec au lieu de stagner.');

  -- 2) Vendredi : 3 → 4 séries
  UPDATE exercises SET sets_target = 4,
         notes = 'Même règle que le lundi : 10 à 15 reps, 15 avec 2 en réserve → +2 kg, retour à 10. Tape la charge du lundi. EN ALTERNÉ avec l''overhead : même barre, même charge, tu passes de l''un à l''autre sans rien toucher. Coudes collés ou LÉGÈREMENT DEVANT le corps, jamais derrière, descente contrôlée. 4e série : 1 en réserve, pas 2.'
   WHERE program_day_id = d_ven AND name = 'Curl barre EZ (supination)';
  UPDATE exercises SET sets_target = 4,
         notes = 'Même règle que le lundi : 10 à 15 reps, 15 avec 2 en réserve → +2 kg, retour à 10. Tape la charge du lundi. EN ALTERNÉ avec le curl EZ, même barre, même charge. Banc VERTICAL, cran 6. Barre derrière la nuque, coudes pointés au plafond et FIXES, descente profonde. Pas un press. Ton meilleur exo triceps, la littérature le confirme. 2 en réserve sur toutes les séries (coudes).'
   WHERE program_day_id = d_ven AND name = 'Extensions overhead barre EZ';
  UPDATE program_days SET notes = 'Vendredi. 4 curls ⇄ 4 overhead, même barre, même charge, puis 15 min de zone 2. ~40 min.' WHERE id = d_ven;

  -- 3) Lundi : dernière série de curl à 1 en réserve
  UPDATE exercises
     SET notes = 'EN ALTERNÉ avec l''overhead : une série de curl, une série d''overhead, même barre. Double progression courte : tu montes les reps de 10 à 15, et la séance où tu fais 15 avec 2 en réserve, +2 kg et tu repars à 10. Plus jamais 20. Coudes collés ou LÉGÈREMENT DEVANT le corps, jamais derrière, pas de balancement, descente contrôlée. 4e série : 1 en réserve, pas 2.'
   WHERE name = 'Curl barre EZ (supination)' AND program_day_id <> d_ven;
END $$;
