-- Migration 069 : vendredi, retour à 3 ⇄ 3 (annule la 4e série de la 065).
-- Le user (22/10) : « ça va me demander beaucoup plus de temps, les séances vont s'allonger ».
-- La 4e série coûtait 5-6 min et c'est le changement le moins soutenu (Schoenfeld 2019 :
-- 3 vs 5 séries par séance, rien pour le biceps). Amplitude complète et dernière série à
-- 1 en réserve (mieux soutenus, quasi gratuits en temps) restent.
DO $$
DECLARE d_ven uuid;
BEGIN
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;
  UPDATE exercises SET sets_target = 3, reps_target = '10-15/jusqu''à 2 en réserve, 3e à 1',
         notes = replace(notes, '4e série : 1 en réserve, pas 2.', '3e série : 1 en réserve, pas 2.')
   WHERE program_day_id = d_ven AND name = 'Curl barre EZ (supination)';
  UPDATE exercises SET sets_target = 3, reps_target = '10-15/jusqu''à 2 en réserve, 3e à 1',
         notes = replace(notes, '4e série à 1 en réserve.', '3e série à 1 en réserve.')
   WHERE program_day_id = d_ven AND name = 'Extensions overhead barre EZ';
  UPDATE program_days SET notes = 'Vendredi. 3 curls ⇄ 3 overhead, même barre, même charge, puis 15 min de zone 2. ~35 min.' WHERE id = d_ven;
END $$;
