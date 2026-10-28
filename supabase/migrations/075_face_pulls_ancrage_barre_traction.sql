-- Migration 075 : face pulls, ancrage sur la barre de traction (le user, 28/10 : il accroche
-- l'élastique à la barre de traction, plus haut que ses yeux). On garde son ancrage : zéro
-- mise en place, et le rack improvisé se soulève sous traction (setup-sport.md), on ne tire pas
-- dessus. L'élastique arrive un peu d'au-dessus : variante classique, la fin du geste ne change pas.

UPDATE exercises
   SET notes = replace(notes,
       'FORME : élastique à hauteur des yeux, paumes vers le bas, recule jusqu''à ce qu''il soit tendu bras tendus. Tire vers le front',
       'FORME : élastique sur la barre de traction, paumes vers le bas, recule jusqu''à ce qu''il soit tendu bras tendus (plus tu recules, moins il vient d''en haut). Tire vers le front')
 WHERE name = 'Face pulls élastique';
