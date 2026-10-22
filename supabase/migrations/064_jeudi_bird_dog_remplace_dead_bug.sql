-- Migration 064 : le jeudi ouvre par un bird dog, plus par un dead bug
--
-- Recherche demandée par le user le 22/10 (« de vraies études »). McGill & Karpowicz 2009,
-- Arch Phys Med Rehabil 90(1):118 : le « Big 3 » de McGill = curl-up, side bridge, bird dog ;
-- le dead bug y est mesuré hors Big 3 et n'active presque rien (grand droit 6 %, obliques
-- 5-8 % de la contraction maximale). Callaghan 1998, Phys Ther 78(1):8 : le bird dog est
-- l'exo extenseur-dominant « low-risk given the low spine load ». Avant un SLDL, ce sont
-- les extenseurs qu'on veut réveiller : le bird dog, déjà le lundi, prend la place.
-- UPDATE en place (historique des 46 logs conservé sous le nouveau nom), section rehab.

UPDATE exercises
   SET name = 'Bird dog',
       reps_target = '8/côté',
       notes = 'Réveil des extenseurs du dos avant le SLDL, tu coches, pas de RIR. À 4 pattes, mains sous les épaules, genoux sous les hanches. Tendre bras droit + jambe gauche à l''horizontale SANS cambrer ni tourner le bassin (un verre d''eau posé sur les lombaires ne tomberait pas). Tenir 3 s, revenir lentement, alterner, 8 de chaque côté.'
 WHERE name = 'Dead bug';
