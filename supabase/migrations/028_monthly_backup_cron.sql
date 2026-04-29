-- ============================================================
-- Migration 028 — Backup mensuel auto par email
-- ============================================================
-- Pré-requis (à faire AVANT cette migration, cf. SETUP.md section 30) :
--   1. Edge function 'monthly-backup' déployée + secrets RESEND_API_KEY
--      et BACKUP_TO_EMAIL configurés
--   2. Vault secrets créés via Dashboard → Database → Vault :
--        - gymlog_backup_url        = URL complète de l'Edge function
--        - gymlog_service_role_key  = la clé service_role du projet
--   3. Extensions pg_cron et pg_net activées

-- Idempotent : drop l'ancien job si présent
do $unsched$
begin
  perform cron.unschedule('gymlog-monthly-backup');
exception when others then null;
end $unsched$;

-- 1er du mois à 10:00 UTC (≈ 11h-12h Paris selon DST)
select cron.schedule(
  'gymlog-monthly-backup',
  '0 10 1 * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'gymlog_backup_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'gymlog_service_role_key')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $job$
);
