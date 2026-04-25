-- Allow authenticated users to update exercises and cardio_blocks.
-- The program is shared (no user_id on these tables) and SELECT is already open
-- to all authenticated users. Without an UPDATE policy, RLS silently filters
-- the rows out → the SettingsView "change bar" feature was a no-op in DB
-- while updating local state optimistically.

create policy "Authenticated users can update exercises"
  on exercises for update to authenticated
  using (true) with check (true);

create policy "Authenticated users can update cardio_blocks"
  on cardio_blocks for update to authenticated
  using (true) with check (true);
