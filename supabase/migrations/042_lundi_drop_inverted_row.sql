-- Migration 042 : Lundi — Drop inverted row (tirage horizontal supprimé)
--
-- Fin d'itération sur le slot tirage. Le user (1m97/136kg) a échoué à exécuter
-- correctement TOUTES les variantes testées : rowing barre = ventre bloque l'amplitude ;
-- rowing haltère unilatéral SOUTENU = pas senti ; chest-supported row incliné = écrase
-- l'entrejambe ; inverted row = le rack improvisé (léger) se soulève à l'arrière sous
-- ses 136kg → pas safe. 5 variantes, aucune ne tient. Le thrash lui-même est un signal.
--
-- Décision assumée : on SUPPRIME sans remplacer. Le dos n'est pas une cible hypertrophie
-- ("dose minimale efficace, pas volume max"). Sur les 3 jobs que portait ce tirage :
--   - biceps indirect → déjà couvert par les curls directs (seule cible croissance) ;
--   - rétraction scapulaire / santé épaule G → déjà porté par les face pulls + rotations
--     externes (rehab, non-négociables, conservés) ;
--   - contrepoids postural au pressing → seule vraie perte, mais le pressing est lui-même
--     en dose minimale (pec pas chassé) → déséquilibre antérieur modéré, surveillable.
-- Coût net faible. Lundi raccourcit (meilleure adhérence). Pas de remplacement bras :
-- déjà au plafond utile en déficit (au-delà = junk volume).
--
-- ⚠️ Supprime un exo avec set_logs historiques (inverted row) : suppression des logs avant
--    l'exo (FK constraint), détruit l'historique. Même pattern que 010, 011, 030, 031, 032,
--    039, 040.

DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id = d_lundi
        AND name = 'Inverted row (barres de sécurité)'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_lundi
     AND name = 'Inverted row (barres de sécurité)';
END $$;
