-- Migration 049 : Retrait de la suspension barre fixe (cooldown lundi / mercredi / vendredi)
--
-- Le user a mal à l'avant-bras "à force" : la suspension fait porter 136 kg sur les doigts,
-- de loin la plus grosse charge de grip du programme, 3×/semaine, en plus des curls EZ et
-- hammer du lundi. La note "pieds au sol pour décharger le grip" n'a pas suffi. Les logs
-- confirment que l'exo est déjà abandonné en pratique : dernier log le 26/08, alors que
-- genoux-poitrine (même cooldown) est logué à chaque séance depuis.
--
-- Pas de remplacement : le genoux-poitrine reste et couvre le relâchement lombaire du
-- cooldown sans aucune charge sur les mains. Set_logs sauvegardés dans
-- supabase/backups/suspension_barre_fixe_set_logs.json (FK sans ON DELETE).
--
-- Volume bras hebdo inchangé : biceps 8 directs, triceps 7 directs + 3 indirect (pompes).

DO $$
BEGIN
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT e.id FROM exercises e
       JOIN program_days pd ON pd.id = e.program_day_id
       JOIN programs p ON p.id = pd.program_id
      WHERE p.is_active AND e.name = 'Suspension barre fixe');

  DELETE FROM exercises
   WHERE id IN (
     SELECT e.id FROM exercises e
       JOIN program_days pd ON pd.id = e.program_day_id
       JOIN programs p ON p.id = pd.program_id
      WHERE p.is_active AND e.name = 'Suspension barre fixe');
END $$;
