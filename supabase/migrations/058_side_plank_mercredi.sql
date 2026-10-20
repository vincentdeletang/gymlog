-- Migration 058 : Side plank lundi → mercredi (équilibrage des jours)
--
-- Question du user (20/10/2026) : les exos de gainage sont-ils bien répartis ? Presque.
-- Lundi portait bird dog + side plank + 8 séries bras + zone 2 (~50 min, le jour le plus long),
-- mercredi n'avait que 6 séries bras + zone 2 (~30 min). Le side plank (2 séries, sans charge)
-- passe au mercredi, en ouverture avant la barre au front : lundi 10 séries, mercredi 8.
-- Chaque jour de bras ouvre ainsi par un exo de gainage anti-mouvement (lun bird dog, mar plank,
-- mer side plank, jeu dead bug), vendredi reste la séance courte. UPDATE, historique conservé.

UPDATE exercises e
   SET program_day_id = (SELECT pd.id FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3),
       order_index = 0
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
 WHERE e.program_day_id = pd.id AND p.is_active AND pd.day_of_week = 1
   AND e.name = 'Side plank';
