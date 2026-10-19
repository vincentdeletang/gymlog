-- Migration 056 : Zone 2 en fin de séance TOUS les jours, overhead en 10-15, pompes serrées
--
-- Décisions du user (19/10/2026 soir, FDR) :
--
-- 1) ZONE 2 LUNDI, MERCREDI, VENDREDI AUSSI (la 052 ne l'avait mise que mardi et jeudi).
--    "tant qu'à faire comme ça je réfléchis pas, je le fais à chaque fois". Mercredi et
--    vendredi font 6 séries (~20 min) dans un créneau de 45 : 15 min de zone 2 ne coûtent
--    rien. Lundi déborde de ~5 min (12 séries + 15), accepté. 5 × 15 = 75 min/semaine, au-dessus
--    du seuil (60-90) où un pouls de repos commence à bouger. Même bloc que mardi / jeudi :
--    15 min → 20 max, +1 min par séance.
--
-- 2) OVERHEAD EZ EN DOUBLE PROGRESSION COURTE (10-15), comme le curl (054). Il était à 24 kg
--    × 16 reps en mode 'reps' : même série longue, même brûlure. Lundi : dernier log 24 × 16
--    RIR 3 → l'app propose 26 dès lundi → curl ET overhead à 26 kg de disques = même barre,
--    même charge, l'alterné se fait sans toucher un disque. Vendredi (ligne neuve, hold retiré)
--    il tape 26 la première fois.
--
-- 3) POMPES SERRÉES (mardi) : les pompes sont le seul pressing du programme et le bras est la
--    seule cible → mains largeur d'épaules (pas plus), coudes le long du corps : le triceps
--    prend la plus grosse part, le pec passe en indirect. Le banc continue de plafonner
--    l'amplitude (épaule G). Il est à 15 × 3 : les mains descendent d'un cran.

DO $$
DECLARE
  d_lun UUID; d_mar UUID; d_mer UUID; d_ven UUID;
BEGIN
  SELECT pd.id INTO d_lun FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 1;
  SELECT pd.id INTO d_mar FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 2;
  SELECT pd.id INTO d_mer FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 3;
  SELECT pd.id INTO d_ven FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active AND pd.day_of_week = 5;

  IF EXISTS (SELECT 1 FROM cardio_blocks WHERE program_day_id = d_lun) THEN
    RAISE NOTICE 'Migration 056 déjà appliquée';
    RETURN;
  END IF;

  -- 1) Zone 2 lundi / mercredi / vendredi
  INSERT INTO cardio_blocks (program_day_id, name, duration_minutes, order_index, notes, duration_target_max_minutes, progression_step_minutes)
  VALUES
    (d_lun, 'Zone 2 (FC 115-135)', 15, 1, 'Juste après la séance, 15 min d''UN SEUL bloc, souffle qui laisse parler mais pas chanter. Pad à sa vitesse max si ça suffit à monter le souffle, sinon vélo dehors assistance coupée. Même chose chaque jour : tu ne réfléchis pas, tu le fais.', 20, 1),
    (d_mer, 'Zone 2 (FC 115-135)', 15, 1, 'Juste après la séance, 15 min d''UN SEUL bloc, souffle qui laisse parler mais pas chanter. Même support que les autres jours.', 20, 1),
    (d_ven, 'Zone 2 (FC 115-135)', 15, 1, 'Juste après la séance, 15 min d''UN SEUL bloc, souffle qui laisse parler mais pas chanter. 5e dose de la semaine.', 20, 1);

  UPDATE program_days SET name = 'Bras A · curl ⇄ overhead + zone 2', notes = 'Lundi. 8h, tenue posée la veille. Curl ⇄ overhead sur la même barre, même charge. Puis 15 min de zone 2 : la journée la plus longue, ~50 min.' WHERE id = d_lun;
  UPDATE program_days SET name = 'Bras B · barre au front + curl assis + zone 2', notes = 'Mercredi. Barre au front sur banc plat, banc redressé pour le curl assis, puis 15 min de zone 2. ~35 min.' WHERE id = d_mer;
  UPDATE program_days SET name = 'Bras C · curl ⇄ overhead + zone 2', notes = 'Vendredi. Même barre, même charge pour les deux exos, puis 15 min de zone 2. ~35 min.' WHERE id = d_ven;

  -- 2) Overhead EZ en double progression courte
  UPDATE exercises
     SET progression_mode = 'weight', reps_target = '10-15', hold_weight_kg = NULL,
         notes = 'EN ALTERNÉ avec le curl EZ : même barre, même charge (26 dès lundi), tu passes de l''un à l''autre sans toucher un disque. Double progression courte : 10 à 15 reps, la séance où tu fais 15 avec 2 en réserve, +2 kg et retour à 10. Plus jamais 16-20. '
                 'Banc VERTICAL, cran 6 (~90°). Barre derrière la nuque, coudes pointés au plafond et FIXES. Pas un press : la charge ne monte pas, ce sont les coudes qui se déplient. Longue portion étirée, ton meilleur exo triceps.'
   WHERE program_day_id = d_lun AND name = 'Extensions overhead barre EZ';

  UPDATE exercises
     SET progression_mode = 'weight', reps_target = '10-15', hold_weight_kg = NULL,
         notes = 'Même règle que le lundi : 10 à 15 reps, 15 avec 2 en réserve → +2 kg, retour à 10. Première séance : tape la charge du lundi. EN ALTERNÉ avec le curl EZ, même barre, même charge. '
                 'Banc VERTICAL, cran 6. Barre derrière la nuque, coudes pointés au plafond et FIXES. Pas un press.'
   WHERE program_day_id = d_ven AND name = 'Extensions overhead barre EZ';

  -- 3) Pompes serrées
  UPDATE exercises
     SET name = 'Pompes serrées mains surélevées (banc)',
         notes = 'Cible : TRICEPS d''abord, pec en indirect. Banc PLAT (cran 1), mains sur le banc LARGEUR D''ÉPAULES, pas plus, coudes qui restent le long du corps (pas écartés). '
                 'Descendre la poitrine vers le bord du banc : c''est lui qui t''empêche de passer les coudes derrière le torse (épaule G). Remontée contrôlée, sans verrouiller sec. '
                 'PROGRESSION : les reps jusqu''à 15 sur les 3 séries, puis les mains descendent d''un cran (barres de sécurité plus bas). Tu es à 15 × 3 : descends d''un cran dès cette semaine, et ça s''allège tout seul avec le poids.'
   WHERE program_day_id = d_mar AND name = 'Pompes mains surélevées (banc)';
END $$;
