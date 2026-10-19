-- Migration 055 : Overhead EZ lundi + vendredi, barre au front mercredi
--
-- Proposition du user (19/10/2026, "vraie question") : l'overhead EZ est le meilleur exo
-- triceps du programme (longue portion étirée). Depuis la 052 il tombait mercredi (4) puis
-- vendredi (3) : 48 h entre deux fois le même mouvement, puis 5 jours de vide. Lundi + vendredi
-- = 72 h et 96 h, le triceps arrive frais aux deux séances ; la barre au front (angle différent,
-- coudes sensibles, une seule fois par semaine) remplit le mercredi.
--
-- Coût accepté : le mercredi perd l'alterné sur le même banc (barre au front = banc plat,
-- curl assis = banc vertical) → 6 séries en séquence. Le lundi le récupère : curl EZ debout ⇄
-- overhead assis, même barre EZ, 2 kg d'écart (26 vs 24), on passe de l'un à l'autre.
--
-- Tout en UPDATE (historique conservé). Résultat :
--   LUN  Bras A · curl ⇄ overhead : bird dog 2, side plank 2, curl EZ 4 ⇄ overhead EZ 4   (12)
--   MER  Bras B · barre au front + curl assis : barre au front 3, curl assis 3             (6)
--   VEN  Bras C · curl ⇄ overhead : curl EZ 3 ⇄ overhead EZ 3                             (6)
-- Volume bras hebdo inchangé : biceps 10 directs, triceps 10 directs + 3 indirect (pompes mardi).

DO $$
DECLARE
  d_lun UUID; d_mer UUID; d_ven UUID;
BEGIN
  SELECT pd.id INTO d_lun FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_mer AND name = 'Extensions overhead barre EZ') THEN
    RAISE NOTICE 'Migration 055 déjà appliquée';
    RETURN;
  END IF;

  -- Overhead : mercredi → lundi, en alterné avec le curl EZ
  UPDATE exercises
     SET program_day_id = d_lun, order_index = 7,
         notes = 'EN ALTERNÉ avec le curl EZ : une série de curl debout, une série d''overhead assis, même barre (2 kg d''écart, 1 kg par côté). Le repos de l''un est le temps de l''autre. '
                 'Banc VERTICAL, cran 6 (~90°). Barre derrière la nuque, coudes pointés au plafond et FIXES (ne pas les écarter). Pas un press : la charge ne monte pas, ce sont les coudes qui se déplient. Cible : longue portion étirée. Ton meilleur exo triceps, tu y arrives frais.'
   WHERE program_day_id = d_mer AND name = 'Extensions overhead barre EZ';

  -- Barre au front : lundi → mercredi
  UPDATE exercises
     SET program_day_id = d_mer, order_index = 1,
         notes = 'Banc PLAT, cran 1 (0°). Bras légèrement inclinés vers la tête, coudes FIXES pointés au plafond. Descendre vers le front, stop ~5cm avant. '
                 'Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse. Une seule fois par semaine, c''est ici. Puis tu redresses le banc pour le curl assis.'
   WHERE program_day_id = d_lun AND name = 'Barre au front';

  -- Curl assis : plus d'alterné le mercredi (banc différent)
  UPDATE exercises
     SET order_index = 2,
         notes = 'Après la barre au front, banc redressé en VERTICAL cran 6. Assis dos calé contre le dossier, coude au corps (jamais en arrière : c''est la position qui étirait le tendon du chef long de l''épaule G). '
                 'Un seul haltère → bras par bras en alterné, une ligne de log par série pour les deux bras. Départ paume neutre, SUPINATION COMPLÈTE en montant, squeeze 1s en haut, descente lente. '
                 'PETITS disques (2 × 5 + 1 kg), plafond pratique ~14-16 kg de disques.'
   WHERE program_day_id = d_mer AND name = 'Curl haltère assis (supination)';

  -- Curl EZ lundi : note d'alterné
  UPDATE exercises
     SET notes = 'EN ALTERNÉ avec l''overhead : une série de curl, une série d''overhead, même barre. Double progression courte : tu montes les reps de 10 à 15, et la séance où tu fais 15 avec 2 en réserve, +2 kg et tu repars à 10. Plus jamais 20. Coudes fixes le long du corps, pas de balancement, descente contrôlée.'
   WHERE program_day_id = d_lun AND name = 'Curl barre EZ (supination)';

  UPDATE program_days SET name = 'Bras A · curl ⇄ overhead', notes = 'Lundi. 8h, tenue posée la veille. Curl debout ⇄ overhead assis sur la même barre : 8 séries en ~15 min. Ton meilleur exo triceps est ici, frais.' WHERE id = d_lun;
  UPDATE program_days SET name = 'Bras B · barre au front + curl assis', notes = 'Mercredi. Séance courte : barre au front sur banc plat, puis banc redressé pour le curl assis. La seule barre au front de la semaine (coudes).' WHERE id = d_mer;
END $$;
