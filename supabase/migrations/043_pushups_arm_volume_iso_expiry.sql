-- Migration 043 : Retour d'un pressing (pompes) + remontée du volume bras + date de sortie de l'iso
--
-- CONTEXTE — le budget bras n'avait jamais été recompté après les drops.
-- Le plafond "10-13 sets effectifs/sem par bras" de CLAUDE.md comptait l'INDIRECT
-- (développé→triceps, tirage→biceps). Or on a retiré les deux compounds qui le
-- fournissaient : développé incliné le 05/06 (039, épaule G) puis tirage le 17/06
-- (042, 5 variantes échouées). Chaque décision était bonne isolément, mais personne
-- n'a refait l'addition : biceps 6 directs + 0 indirect, triceps 7 directs + 0 indirect.
-- Le stimulus bras avait baissé de ~30-40% sans que ce soit décidé. Le user l'a senti.
--
-- DÉFICIT : le user ne perd pas de poids → il n'est PAS en déficit, il est à l'entretien.
-- Le poids sur 2-3 semaines est le seul arbitre (cf. CLAUDE.md : le déficit alimentaire
-- est le levier, pas la dépense des séances). Conséquence programme : la récup n'est plus
-- plafonnée, donc CLAUDE.md dit explicitement de proposer d'augmenter le volume bras.
-- C'est ce que fait cette migration.
--
-- ============================================================
-- 1) VENDREDI — ADD "Pompes mains surélevées (banc)" 3×8-15
-- ============================================================
-- Comble le trou pec (0 set direct depuis 039) et restaure du triceps indirect.
--
-- Pourquoi PAS la barre (le user a demandé, il a fait du développé couché en salle) :
--   - 1m97 = bras longs = amplitude énorme. Avec une barre l'amplitude n'est pas
--     plafonnable : elle s'arrête sur la poitrine, donc coudes forcément derrière la
--     ligne du torse = exactement la position qui irrite le chef long du biceps
--     (cf. 039). C'est déjà ce qui lui avait niqué l'épaule en salle.
--   - Mains fixées en pronation, aucune liberté de rotation.
--   - Sécurité : seul dans le garage, sans pareur, sur un rack assez léger pour se
--     soulever sous une traction (cf. 042). Barre chargée au-dessus de la gorge = non.
--
-- Pourquoi PAS le développé haltère (option pré-tranchée dans CLAUDE.md) : un SEUL
-- haltère → unilatéral alterné → 3 séries = 6 séries en temps réel. Cher pour un muscle
-- non-prioritaire quand la contrainte n°1 est la durée de séance.
--
-- Pourquoi les pompes MAINS SURÉLEVÉES et pas au sol : se mettre au sol du garage = pas
-- d'adhérence (c'est ce qui avait fait refuser le floor press).
--
-- Pourquoi c'est le meilleur choix ici :
--   - Chaîne fermée → OMOPLATES LIBRES (vs plaquées sur un banc) = l'argument santé
--     d'épaule le plus solide.
--   - La poitrine descend vers le bord du banc → les coudes ne peuvent PHYSIQUEMENT pas
--     partir derrière le torse. Amplitude plafonnée par le matos, pas par la discipline.
--   - Mains hautes = pattern décliné = la variante de pressing la moins stressante pour
--     l'épaule antérieure.
--   - À 136kg, mains sur banc plat ≈ 75-80kg poussés. Charge réelle, pas un échauffement.
--   - Zéro setup, zéro disque → friction minimale.
--   - S'allège tout seul à mesure qu'il perd du gras (comme l'inverted row de 040).
--
-- ORDRE : order_index 6, AVANT les 2 exos triceps (slot libéré par les élévations
-- latérales en 032). Compound d'abord : c'est le seul exo qui donne quelque chose au pec,
-- il doit être fait frais, et son apport triceps indirect est précisément ce qu'on
-- restaure. Le coût = un peu moins de charge sur l'isolation triceps derrière, ce qui est
-- le compromis le moins cher. Bonus sécurité : un pressing frais = forme propre.
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_vendredi AND name = 'Pompes mains surélevées (banc)') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, muscle_group, is_per_side)
    VALUES (
      d_vendredi,
      'Pompes mains surélevées (banc)',
      6,
      3,
      '8-15',
      true,
      'Cible : pec. Triceps en indirect.

SETUP : banc PLAT (cran 1). Mains sur le banc, largeur épaules ou un peu plus, pieds au sol, corps gainé droit de la tête aux talons. Pas au sol : sur le banc.

EXÉCUTION : descendre la poitrine vers le bord du banc, coudes à ~45° du corps (pas écartés à 90°). Ne force pas plus bas que le banc ne te laisse aller — c''est justement lui qui t''empêche de passer les coudes derrière le torse (la position qui agace l''épaule G). Remontée contrôlée, sans verrouiller sec.

CHARGE : mains hautes = plus facile. Le banc plat te fait pousser ~75-80kg à ton poids, c''est déjà du lourd.

PROGRESSION : d''abord les reps (jusqu''à 15). Quand tu tapes 15 propre sur les 3 séries, tu descends les mains d''un cran (barres de sécurité plus bas). Et ça s''allège tout seul à mesure que tu perds du gras.

ÉPAULE : si ça pique comme le développé incliné, tu me le dis — on drop, on aura la réponse en une séance.',
      'main',
      'chest',
      false
    );
  END IF;
END $$;

-- ============================================================
-- 2) LUNDI — Volume biceps 6 → 8 sets/bras
-- ============================================================
-- On annule le cut de la 030 ("Curl barre EZ 4 → 3"), qui était justifié par le déficit
-- et par le rééquilibrage vers le triceps. Le déficit n'existe pas (poids stable), et le
-- triceps garde l'avantage : 7 directs + l'indirect des pompes ≈ 9-10 vs 8 pour le biceps.
-- On ajoute des SÉRIES sur les exos existants plutôt qu'un nouvel exo : aucun mouvement à
-- apprendre, aucun setup en plus, ~6 min sur la séance la plus courte de la semaine.
-- Si besoin de pousser plus loin dans quelques semaines, le curl concentré (droppé en 030)
-- revient facilement pour passer à 10.
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  UPDATE exercises
     SET sets_target = 4
   WHERE program_day_id = d_lundi
     AND name IN ('Curl barre EZ (supination)', 'Curl haltères hammer');
END $$;

-- ============================================================
-- 3) LUNDI + VENDREDI — Face pulls 2 → 3 séries
-- ============================================================
-- Le slot tirage reste FERMÉ (décision 042 confirmée par le user : 5 variantes échouées,
-- le rack élimine définitivement l'inverted row). Mais on réintroduit un pressing dans
-- cette même migration, donc le contrepoids postural — seule vraie perte listée en 042 —
-- redevient d'actualité. On remonte les face pulls à la dose thérapeutique (annule le cut
-- de 035). Ce n'est pas du dos, c'est de la rétraction scapulaire : honnête sur ce que ça
-- fait, et ça coûte 1 série d'élastique.
DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE exercises
     SET sets_target = 3
   WHERE program_day_id IN (d_lundi, d_vendredi)
     AND name = 'Face pulls élastique';
END $$;

-- ============================================================
-- 4) LUNDI + VENDREDI — Isométrie biceps : date de sortie explicite
-- ============================================================
-- Ajoutée le 05/06 (039) comme "temporaire". On est le 09/08 : 9 semaines. Elle est en
-- train de mourir d'inertie, exactement le sort classique des trucs "provisoires".
--
-- Pourquoi on ne la retire pas MAINTENANT : elle a été ajoutée le même jour où on retirait
-- le développé incliné. On ne sait donc pas si l'épaule est calme grâce à l'iso ou juste
-- parce que l'exo qui faisait mal est parti (hypothèse la plus probable : 3×30s 2×/sem est
-- une dose faible pour du protocole tendineux type Baar, plutôt ~4×30-45s quasi quotidien).
-- Et cette migration réintroduit justement un pressing. Retirer le filet ET remettre l'exo
-- suspect la même semaine = si ça flambe, on ne saura pas lequel des deux accuser.
--
-- Donc : on la garde 4 semaines de plus comme variable de contrôle, avec le critère d'arrêt
-- DANS LE NOM (visible sans ouvrir la note) et DANS la note. C'est l'app qui se souvient,
-- pas le user.
--
-- Le rename préserve l'historique : les set_logs sont liés par exercise_id, pas par nom.
DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE exercises
     SET name  = 'Isométrie biceps (stop le 06/09)',
         notes = '⏳ DATE DE SORTIE : 06/09/2026.

Pourquoi elle est encore là : ajoutée le 05/06 en même temps qu''on retirait le développé incliné — impossible de savoir si c''est elle qui a calmé l''épaule ou juste le retrait de l''exo. On la garde le temps de réintroduire un pressing (pompes mains surélevées, vendredi).

RÈGLE D''ARRÊT : 4 séances de pompes sans douleur à l''épaule G → on la supprime (migration). Si la douleur revient → c''est le pressing le coupable, pas l''iso, et c''est le pressing qui saute.

POSITION : milieu d''un curl tenu STATIQUE. Coude collé au corps à ~90° (avant-bras // sol), paume vers le haut (supinée). Tu ne montes ni ne descends, tu RÉSISTES immobile ~30s.

CHARGE : ton poids de curl pour un set dur de 8-12 reps. Ça doit devenir vraiment dur sur les 10 dernières secondes (RPE 7-8) mais tenable sans douleur > 3/10. Trop facile à 30s = trop léger.

Supination qui tire sur l''épaule ? → prise neutre (hammer).'
   WHERE program_day_id IN (d_lundi, d_vendredi)
     AND name = 'Isométrie biceps (temporaire)';
END $$;
