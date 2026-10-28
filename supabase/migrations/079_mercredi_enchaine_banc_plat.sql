-- Migration 079 : mercredi, barre au front ⇄ curl haltère assis enchaînés, tout sur banc plat
--
-- Sa proposition (28/10/2026) : enchaîner les deux, curl assis sur le banc plat « si je garde le
-- dos droit ». Oui : biceps et triceps sont antagonistes, alterner ne coûte rien à l'un ni à
-- l'autre et coupe le temps de séance ; et plus de changement de cran au milieu. Sans dossier,
-- le seul risque est de se pencher en arrière : le coude passe derrière le corps, la position
-- qui tend le tendon du chef long de l'épaule G (interdit maintenu). D'où la consigne : torse
-- droit ou très légèrement penché en avant, coude devant la hanche.

DO $$
DECLARE
  d3 UUID;
BEGIN
  SELECT pd.id INTO d3 FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;

  UPDATE program_days SET notes = 'Mercredi. Barre au front et curl assis EN ALTERNÉ, tout sur le banc plat (cran 1), puis 15 min de zone 2. ~30 min.' WHERE id = d3;

  UPDATE exercises SET superset_group = 'A'
   WHERE program_day_id = d3 AND name IN ('Barre au front', 'Curl haltère assis (supination)');

  UPDATE exercises
     SET notes = replace(notes, ' Puis tu redresses le banc pour le curl assis.', ' EN ALTERNÉ avec le curl assis, même banc.')
   WHERE program_day_id = d3 AND name = 'Barre au front';

  UPDATE exercises
     SET setup = NULL,
         notes = replace(notes,
           'Après la barre au front, banc redressé en VERTICAL cran 6. Assis dos calé contre le dossier, coude au corps (jamais en arrière : c''est la position qui étirait le tendon du chef long de l''épaule G).',
           'EN ALTERNÉ avec la barre au front, sur le MÊME banc plat : assis au bout, pieds à plat au sol, torse droit ou très légèrement penché en avant. Coude au corps, DEVANT la hanche, jamais en arrière : sans dossier, si tu te penches en arrière, le coude passe derrière toi, c''est la position qui étirait le tendon du chef long de l''épaule G.')
   WHERE program_day_id = d3 AND name = 'Curl haltère assis (supination)';
END $$;
