-- Migration 041 : Drop soreness_logs (check-in épaule retiré)
--
-- Le check-in quotidien "Comment va ton épaule gauche ?" (0-3) était en écriture seule :
-- aucune logique ne lisait le niveau pour modifier la séance — juste stocké + réaffiché
-- en courbe. Le user tape "Nickel" par réflexe à chaque fois → données sans valeur, et
-- même la tendance est du bruit. Il auto-régule son épaule au feeling (même logique que
-- le rest timer) et sa vraie gestion vit dans le programme (drop développé incliné migration
-- 039, iso biceps, rehab non-négo). Le check-in ne faisait pas partie de la gestion → retiré
-- côté front (SorenessCheckin, SorenessHistory, store). On drop la table : rien n'y écrit plus,
-- et l'historique accumulé (que des "Nickel") ne vaut pas la peine d'être conservé.

DROP TABLE IF EXISTS soreness_logs;
