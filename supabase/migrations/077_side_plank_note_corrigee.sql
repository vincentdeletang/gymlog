-- Migration 077 : correction de la 076. Les 44-47 s logués n'étaient pas par côté mais le TOTAL
-- des deux côtés (le chrono logue la somme ; le côté 1 coupait au minimum de 20 s, le côté 2
-- partait en bonus jusqu'au bouton). Il tenait donc ~20-25 s par côté, genoux SUR le banc (tout
-- le corps sur le banc), pas au sol. La conclusion « trop facile » était fausse. Il passe quand
-- même pieds au sol, avant-bras sur le banc : plus pratique à mettre en place (ses mots, 28/10).
-- Même commit : le chrono s'arrête seul au max de la plage (30 s), bip au mini (20 s).

UPDATE exercises
   SET notes = 'FORME : avant-bras sur le banc, coude sous l''épaule, JAMBES TENDUES, pieds l''un devant l''autre au sol (corps un peu incliné, c''est normal). Corps aligné tête-hanches-pieds, hanche haute, elle ne s''affaisse pas. '
             || 'CHRONO : bip à 20 s (le mini), il s''arrête seul à 30 s et passe au côté 2. Si tu lâches avant, appuie sur arrêter. Le temps logué = les deux côtés additionnés. '
             || 'ÉCHELLE : si tu vas au bout des 30 s des deux côtés proprement → avant-bras au sol. Si la hanche tombe avant le bip des 20 s → genoux sur le banc le temps d''une semaine. '
             || 'Cible : carré des lombes + obliques, ce qui tient quand tu portes ta fille sur une hanche.'
 WHERE name = 'Side plank';
