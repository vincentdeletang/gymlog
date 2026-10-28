-- Migration 078 : exos enchaînés + matériel à préparer (QoL demandée le 28/10/2026)
--
-- superset_group : deux exos du même jour avec la même valeur s'enchaînent. L'app ouvre la série
-- du 2e dès que le 1er est logué, sans repos ; le repos part après la paire ; à la fin du repos,
-- la série suivante s'ouvre seule. Ses logs : curl ⇄ overhead (lun, ven) et pompes ⇄ plank (mar)
-- étaient déjà faits en alterné, l'app lançait 2 min de repos entre les deux.
-- setup : une ligne courte de ce qu'il faut installer, listée en haut de la séance avec les charges
-- (la charge vient de l'app, jamais d'ici). Origine : le rowing landmine (070) mort sur le setup.

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS superset_group text;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS setup text;

DO $$
DECLARE
  d1 UUID; d2 UUID; d3 UUID; d4 UUID; d5 UUID;
BEGIN
  SELECT pd.id INTO d1 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d2 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 2;
  SELECT pd.id INTO d3 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d4 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 4;
  SELECT pd.id INTO d5 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  -- Enchaînés
  UPDATE exercises SET superset_group = 'A' WHERE program_day_id IN (d1, d5) AND name IN ('Curl barre EZ (supination)', 'Extensions overhead barre EZ');
  UPDATE exercises SET superset_group = 'A' WHERE program_day_id = d2 AND name IN ('Pompes serrées mains surélevées (banc)', 'Plank');

  -- Matériel (la charge est ajoutée par l'app à partir de la barre et de la dernière séance)
  UPDATE exercises SET setup = 'Banc vertical, cran 6' WHERE program_day_id IN (d1, d5) AND name = 'Extensions overhead barre EZ';
  UPDATE exercises SET setup = 'Élastique sur la barre de traction' WHERE program_day_id = d2 AND name = 'Face pulls élastique';
  UPDATE exercises SET setup = 'Banc plat, cran 1' WHERE program_day_id = d2 AND name = 'Pompes serrées mains surélevées (banc)';
  UPDATE exercises SET setup = 'Banc plat, cran 1' WHERE program_day_id = d3 AND name = 'Barre au front';
  UPDATE exercises SET setup = 'Puis banc vertical, cran 6' WHERE program_day_id = d3 AND name = 'Curl haltère assis (supination)';
  UPDATE exercises SET setup = 'Barres de sécurité à hauteur de genou, barre posée à hauteur de hanche' WHERE program_day_id = d4 AND name = 'Soulevé de terre jambes tendues (barre)';
END $$;
