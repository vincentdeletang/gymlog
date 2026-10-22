-- Migration 060 : Dead bug en PRÉVENTION (case à cocher) + retrait des mollets
--
-- Deux questions du user (22/10/2026).
--
-- 1) « Pourquoi le dead bug est compté comme un exo de muscu avec des RIR et tout ? »
--    Parce qu'il date du seed d'avril (section 'main' par défaut) et n'a jamais bougé, alors
--    que les autres exos de gainage ajoutés en 047 (bird dog, side plank) et les face pulls
--    vivent en section 'rehab' = tap-to-log, pas de modal reps/RIR. Un exo d'activation à
--    poids de corps n'a pas de RIR : on l'aligne sur le bird dog (rehab, par côté).
--    Historique conservé (UPDATE, 46 logs).
--
-- 2) « Les mollets, c'est vraiment utile niveau santé ? L'hypertrophie je m'en fous. »
--    Non. 3 × 20 à 30 kg avec 4 en réserve = zéro stimulus (ses mollets portent 134 kg à
--    chaque pas, 30 kg de plus ne changent rien). Le tendon d'Achille n'a besoin de ça que
--    pour courir ou sauter, les impacts sont interdits. Ce que les mollets protègent chez
--    lui (équilibre, chevilles, marche), le pad et la marche le font déjà. 3 séries de moins
--    le jeudi = la séance jambes raccourcit, la zone 2 passe mieux. Set_logs (66) sauvegardés
--    dans supabase/backups/mollets_debout_barre_set_logs.json (même procédé que la 057).

UPDATE exercises
   SET section = 'rehab',
       is_per_side = true,
       notes = 'Activation du gainage avant la barre, pas de la muscu : tu coches, pas de RIR. Allongé sur le dos, lombaires plaquées au sol, allonger bras et jambe opposés en expirant, retour lent, 8 de chaque côté.'
 WHERE name = 'Dead bug';

DELETE FROM set_logs
 WHERE exercise_id IN (SELECT id FROM exercises WHERE name = 'Mollets debout (barre)');

DELETE FROM exercises WHERE name = 'Mollets debout (barre)';
