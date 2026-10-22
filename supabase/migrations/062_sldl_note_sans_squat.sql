-- Migration 062 : note du SLDL, qui renvoyait encore au squat retiré en 061. Seul exo barre
-- du jeudi désormais ; charge figée, butée au genou, rien d'autre ne change.
UPDATE exercises
   SET notes = 'CHARGE FIGÉE : 10 kg de chaque côté (20 kg de disques + barre = 30 kg), la seule barre du jeudi. Barres de sécurité à hauteur de GENOU = butée : tu descends jusqu''à toucher, jamais plus bas. Barre désenquillée à hauteur de hanche, pas de ramassage au sol. Mouvement de hanche (fesses vers l''arrière), dos plat, jambes quasi tendues. La série s''arrête à la première rep où le dos s''arrondit. C''est le seul exo du programme qui charge tes lombaires : si le réveil du vendredi dit non, tu me le dis.'
 WHERE name = 'Soulevé de terre jambes tendues (barre)';
