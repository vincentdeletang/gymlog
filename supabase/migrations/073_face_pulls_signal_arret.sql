-- Migration 073 : face pulls, le signal d'arrêt (le user, 28/10 : « j'ai du mal à voir comment
-- je vais m'arrêter de fatigue avec cet exo », il sent bien le curl, pas ça, exo peu familier).
-- Petits muscles = brûlure moins nette qu'au biceps : on s'arrête sur la forme qui lâche.

UPDATE exercises
   SET notes = notes || ' QUAND T''ARRÊTER (2 en réserve) : dès que tu ne tiens plus le squeeze 1 s en arrière, ou que les coudes tombent, ou que les épaules montent. Ce n''est pas la brûlure qui décide ici, c''est la forme qui lâche. Encore 25 propres sans rien de tout ça → élastique plus dur.'
 WHERE name = 'Face pulls élastique' AND notes NOT LIKE '%QUAND T''ARRÊTER%';
