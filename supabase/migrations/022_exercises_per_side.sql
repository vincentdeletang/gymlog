-- Add is_per_side flag for exercises that work both sides per set
-- Used by the timer overlay to enforce a 2-phase Côté 1 → Côté 2 flow.

alter table exercises add column if not exists is_per_side boolean not null default false;

update exercises set is_per_side = true
  where name in ('Pendulaires de Codman', 'Stretch doorway');
