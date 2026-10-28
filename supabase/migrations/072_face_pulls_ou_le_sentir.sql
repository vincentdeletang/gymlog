-- Migration 072 : face pulls, où il doit sentir l'effort (sa question du 28/10 : « je suis censé
-- sentir le haut du dos en muscle qui fatigue ? »). Ajout en tête de note, rien d'autre ne bouge.

UPDATE exercises
   SET notes = 'TU DOIS LE SENTIR à l''arrière des épaules et entre les omoplates, une brûlure qui monte sur les dernières reps. PAS dans la nuque (tu hausses les épaules → épaules basses), PAS dans les biceps (tu tires avec les bras → pense à pousser les coudes vers l''arrière, les mains finissent à côté des oreilles), PAS dans les lombaires (tu te penches en arrière → reste droit). Une douleur à l''avant de l''épaule = tu arrêtes. ' || notes
 WHERE name = 'Face pulls élastique' AND notes NOT LIKE 'TU DOIS LE SENTIR%';
