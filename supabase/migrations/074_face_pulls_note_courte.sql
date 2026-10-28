-- Migration 074 : note des face pulls réécrite courte, la forme en tête (le user, 28/10 :
-- « décris-moi la forme idéale au début de la note, concis et efficace, pas un roman que je ne
-- lirais pas »). Remplace le cumul 071 + 072 + 073, même contenu, trois fois plus court.

UPDATE exercises
   SET notes = 'FORME : élastique à hauteur des yeux, paumes vers le bas, recule jusqu''à ce qu''il soit tendu bras tendus. Tire vers le front, coudes hauts à hauteur d''épaules. Fin : mains à côté des oreilles, pouces vers l''arrière, omoplates serrées 1 s. Retour en 2 s. Épaules basses, buste droit. '
             || 'SENTIR : arrière des épaules + entre les omoplates. Nuque = épaules qui montent. Biceps = tu tires avec les bras. Douleur à l''avant de l''épaule = stop. '
             || 'STOP (2 en réserve) : squeeze plus tenable, coudes qui tombent ou épaules qui montent. '
             || 'PROGRESSION : 25 propres sur les 2 séries → un pas plus loin ou élastique plus dur.'
 WHERE name = 'Face pulls élastique';
