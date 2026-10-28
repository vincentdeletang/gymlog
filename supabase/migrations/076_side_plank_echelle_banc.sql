-- Migration 076 : side plank, l'échelle au banc (le user, 28/10 : « je les fais sur mon banc avec
-- les genoux au sol, c'est ok ? »). Coude sur le banc + genoux = deux allègements cumulés ; ses logs
-- 19 et 21/10 : 44-47 s par côté pour une cible de 20-30 s → trop facile. On garde le banc (pas de
-- descente au sol à 134 kg), on retire un allègement : jambes tendues.

UPDATE exercises
   SET notes = 'FORME : avant-bras sur le banc, coude sous l''épaule, JAMBES TENDUES, pieds l''un devant l''autre au sol. Corps aligné tête-hanches-pieds, hanche haute, elle ne s''affaisse pas. '
             || 'ÉCHELLE : genoux au sol avec le coude sur le banc = trop facile (tu tenais 45 s). Jambes tendues, coude sur le banc = ta version. Si tu tiens 30 s propres → avant-bras au sol. Si la hanche tombe avant 20 s → genoux le temps d''une semaine. '
             || 'Cible : carré des lombes + obliques, ce qui tient quand tu portes ta fille sur une hanche.'
 WHERE name = 'Side plank';
