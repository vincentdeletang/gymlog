# Supabase — Setup & Migrations

Tout coller dans **SQL Editor** de ton projet Supabase, dans l'ordre indiqué.

---

## 1. Migration initiale (schéma complet)

> À ne lancer qu'une seule fois, au premier setup. Si la BDD est déjà initialisée, passe directement à l'étape 2.

```sql
-- Enable UUID extension
create extension if not exists "pgcrypto";

create table if not exists programs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists program_days (
  id uuid primary key default gen_random_uuid(),
  program_id uuid references programs(id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6),
  name text not null,
  type text not null check (type in ('strength', 'cardio', 'rest')),
  xp_reward int default 0,
  notes text
);

create table if not exists exercises (
  id uuid primary key default gen_random_uuid(),
  program_day_id uuid references program_days(id) on delete cascade,
  name text not null,
  order_index int not null default 0,
  sets_target int not null default 3,
  reps_target text default '10',
  is_bodyweight boolean default false,
  notes text,
  section text not null default 'main' check (section in ('main', 'rehab', 'cardio'))
);

create table if not exists cardio_blocks (
  id uuid primary key default gen_random_uuid(),
  program_day_id uuid references program_days(id) on delete cascade,
  name text not null,
  duration_minutes int not null default 20,
  order_index int not null default 0,
  notes text
);

create table if not exists workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  program_day_id uuid references program_days(id),
  session_date date not null default current_date,
  completed boolean default false,
  completed_at timestamptz,
  cardio_duration_seconds int,
  notes text,
  created_at timestamptz default now()
);

create table if not exists set_logs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references workout_sessions(id) on delete cascade,
  exercise_id uuid references exercises(id),
  set_number int not null,
  weight_kg decimal,
  reps_done int,
  rir int check (rir between 0 and 10),
  logged_at timestamptz default now()
);

create table if not exists user_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete cascade,
  xp_total int default 0,
  streak_current int default 0,
  streak_best int default 0,
  last_session_date date,
  level int default 1,
  created_at timestamptz default now()
);

-- RLS
alter table programs         enable row level security;
alter table program_days     enable row level security;
alter table exercises        enable row level security;
alter table cardio_blocks    enable row level security;
alter table workout_sessions enable row level security;
alter table set_logs         enable row level security;
alter table user_state       enable row level security;

create policy "Authenticated users can read programs"
  on programs for select to authenticated using (true);

create policy "Authenticated users can read program_days"
  on program_days for select to authenticated using (true);

create policy "Authenticated users can read exercises"
  on exercises for select to authenticated using (true);

create policy "Authenticated users can read cardio_blocks"
  on cardio_blocks for select to authenticated using (true);

create policy "Users own their workout_sessions"
  on workout_sessions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users own their set_logs"
  on set_logs for all to authenticated
  using (
    exists (
      select 1 from workout_sessions ws
      where ws.id = set_logs.session_id and ws.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from workout_sessions ws
      where ws.id = set_logs.session_id and ws.user_id = auth.uid()
    )
  );

create policy "Users own their user_state"
  on user_state for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.user_state (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

---

## 2. Seed — Programme V1

> À ne lancer qu'une seule fois. Si le programme est déjà en BDD, ne pas relancer.

```sql
do $$
declare
  prog_id uuid := gen_random_uuid();
  d_lundi    uuid := gen_random_uuid();
  d_mardi    uuid := gen_random_uuid();
  d_mercredi uuid := gen_random_uuid();
  d_jeudi    uuid := gen_random_uuid();
  d_vendredi uuid := gen_random_uuid();
  d_samedi   uuid := gen_random_uuid();
  d_dimanche uuid := gen_random_uuid();
begin

insert into programs (id, name, description, is_active)
values (prog_id, 'Programme V1 - Avril 2026', 'Programme hypertrophie 5j + 2j cardio/repos', true);

insert into program_days (id, program_id, day_of_week, name, type, xp_reward) values
  (d_lundi,    prog_id, 1, 'Upper Pull + Biceps', 'strength', 200),
  (d_mardi,    prog_id, 2, 'Cardio Boxe',         'cardio',   150),
  (d_mercredi, prog_id, 3, 'Lower Body',           'strength', 200),
  (d_jeudi,    prog_id, 4, 'Cardio Vélo',          'cardio',   120),
  (d_vendredi, prog_id, 5, 'Upper Push + Triceps', 'strength', 200),
  (d_samedi,   prog_id, 6, 'Récupération active',  'rest',      50),
  (d_dimanche, prog_id, 0, 'Repos complet',        'rest',       0);

-- Lundi — Upper Pull + Biceps
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_lundi, 'Rotations externes élastique',  1, 3, '15',    true, 'Coude collé, rotation lente vers l''extérieur', 'rehab'),
  (d_lundi, 'Face pulls élastique',          2, 3, '15',    true, 'Tirer vers le visage en ouvrant les bras',      'rehab'),
  (d_lundi, 'Pendulaires de Codman',         3, 2, '30s',   true, 'Bras relâché, petits cercles, décompression passive', 'rehab'),
  (d_lundi, 'Stretch doorway',               4, 2, '30s',   true, 'Jamais forcer',                                 'rehab'),
  (d_lundi, 'Rowing haltère unilatéral',     5, 4, '10-12', false, 'Dos neutre, amplitude complète',               'main'),
  (d_lundi, 'Curl barre EZ (supination)',    6, 4, '10-12', false, 'Coudes fixes, pas de balancement',             'main'),
  (d_lundi, 'Curl haltères hammer',          7, 3, '10-12', false, 'Prise neutre, mouvement lent, squeeze en haut','main'),
  (d_lundi, 'Curl haltère concentré',        8, 3, '12-15', false, 'Finisher biceps, contraction max',             'main'),
  (d_lundi, 'Plank',                         9, 3, '30-60s', true, null,                                           'main');

insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_lundi, 'Corde à sauter', 20, 1, 'Séries 2-3 min / 30s récup');

-- Mardi — Cardio Boxe
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_mardi, 'Music Boxing', 15, 1, 'Échauffement, montée progressive'),
  (d_mardi, 'Sac de boxe',  25, 2, 'Rounds 3 min / 1 min récup');

-- Mercredi — Lower Body
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_mercredi, 'Fentes marchées haltères',                 1, 4, '10/jambe', false, 'Pas suffisamment large pour que le genou avant ne dépasse pas le pied, descente selon confort', 'main'),
  (d_mercredi, 'Soulevé de terre jambes tendues (barre)',  2, 3, '10-12',    false, 'Dos plat, descente contrôlée le long des jambes, étirement ischio en bas',                      'main'),
  (d_mercredi, 'Mollets debout (barre)',                   3, 4, '15-20',    false, 'Monter sur disque pour amplitude',                                                               'main'),
  (d_mercredi, 'Reverse crunches',                         4, 3, '15-20',    true,  null,                                                                                              'main');

insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_mercredi, 'Tapis 3%', 30, 1, 'FC cible 110-130 bpm');

-- Jeudi — Cardio Vélo
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_jeudi, 'Zone 2 (FC 120-140)', 50, 1, 'Rythme conversation, assistance électrique dans les côtes'),
  (d_jeudi, 'Zone 4 (FC 160-175)', 10, 2, 'Sprint plat ou côte');

-- Vendredi — Upper Push + Triceps
insert into exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) values
  (d_vendredi, 'Rotations externes élastique',          1, 3, '15',    true, 'Coude collé, rotation lente vers l''extérieur',   'rehab'),
  (d_vendredi, 'Face pulls élastique',                  2, 3, '15',    true, 'Tirer vers le visage en ouvrant les bras',         'rehab'),
  (d_vendredi, 'Pendulaires de Codman',                 3, 2, '30s',   true, 'Bras relâché, petits cercles, décompression passive','rehab'),
  (d_vendredi, 'Stretch doorway',                       4, 2, '30s',   true, 'Jamais forcer',                                    'rehab'),
  (d_vendredi, 'Développé haltères neutre (incliné 30°)',5, 4, '10-12',false, 'Prise neutre = safe épaule',                      'main'),
  (d_vendredi, 'Élévations latérales haltères',         6, 3, '12-15', false, 'Jamais au-dessus de l''horizontale',              'main'),
  (d_vendredi, 'Extensions triceps barre EZ',           7, 4, '10-12', false, 'Coudes fixes pointés plafond',                    'main'),
  (d_vendredi, 'Kickbacks haltères',                    8, 4, '12-15', false, 'Finisher triceps, serrer en extension',           'main'),
  (d_vendredi, 'Crunchs',                               9, 3, '15-20', true,  null,                                              'main');

insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_vendredi, 'Corde à sauter ou Tapis', 25, 1, null);

-- Samedi — Récupération active
insert into cardio_blocks (program_day_id, name, duration_minutes, order_index, notes) values
  (d_samedi, 'Marche / mobilité', 30, 1, 'Optionnel, écoute ton corps');

end $$;
```

---

## 3. Migration 002 — Table `bars` + `bar_id` sur `exercises`

```sql
CREATE TABLE IF NOT EXISTS bars (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT NOT NULL,
  weight_kg DECIMAL(5,2) NOT NULL
);

ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS bar_id UUID REFERENCES bars(id) ON DELETE SET NULL;

-- RLS pour bars (lecture publique comme les autres tables de programme)
ALTER TABLE bars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read bars"
  ON bars FOR SELECT TO authenticated USING (true);
```

---

## 4. Seed — Barres & auto-assignation

> À lancer juste après la migration 002.

```sql
INSERT INTO bars (name, weight_kg) VALUES
  ('Barre droite', 10),
  ('Barre EZ',      6),
  ('Haltère',       2.5);

DO $$
DECLARE
  bar_ez      UUID;
  bar_droite  UUID;
  bar_haltere UUID;
BEGIN
  SELECT id INTO bar_ez      FROM bars WHERE name = 'Barre EZ';
  SELECT id INTO bar_droite  FROM bars WHERE name = 'Barre droite';
  SELECT id INTO bar_haltere FROM bars WHERE name = 'Haltère';

  -- Barre EZ : "Curl barre EZ (supination)", "Extensions triceps barre EZ"
  UPDATE exercises SET bar_id = bar_ez
  WHERE name ILIKE '%EZ%' AND NOT is_bodyweight;

  -- Barre droite : "Hip thrust (barre sur banc)", "Mollets debout (barre)"
  UPDATE exercises SET bar_id = bar_droite
  WHERE name ILIKE '%barre%' AND name NOT ILIKE '%EZ%' AND NOT is_bodyweight;

  -- Haltères : tous les exos contenant "haltère" / "haltères"
  UPDATE exercises SET bar_id = bar_haltere
  WHERE (name ILIKE '%haltère%' OR name ILIKE '%haltères%') AND NOT is_bodyweight;
END $$;
```

---

## 5. Migration 003 — Nouveau programme Mercredi

> À lancer si la BDD est déjà initialisée avec l'ancien programme (Split squat + Hip thrust).

```sql
DO $$
DECLARE
  day_id     UUID;
  bar_droite UUID;
BEGIN
  SELECT pd.id INTO day_id
  FROM program_days pd
  JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  SELECT id INTO bar_droite FROM bars WHERE name = 'Barre droite';

  DELETE FROM exercises
  WHERE program_day_id = day_id
    AND name IN ('Split squat bulgare', 'Hip thrust (barre sur banc)');

  UPDATE exercises SET
    order_index = 1,
    notes = 'Pas suffisamment large pour que le genou avant ne dépasse pas le pied, descente selon confort'
  WHERE program_day_id = day_id AND name = 'Fentes marchées haltères';

  INSERT INTO exercises
    (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
  VALUES
    (day_id, 'Soulevé de terre jambes tendues (barre)', 2, 3, '10-12', false,
     'Dos plat, descente contrôlée le long des jambes, étirement ischio en bas', 'main', bar_droite);

  UPDATE exercises SET order_index = 3
  WHERE program_day_id = day_id AND name = 'Mollets debout (barre)';

  UPDATE exercises SET order_index = 4
  WHERE program_day_id = day_id AND name = 'Reverse crunches';
END $$;
```

---

## 6. Migration 004 — Suspension barre fixe (fin de séance muscu)

> Ajoute l'exercice en dernière position sur lundi, mercredi et vendredi.

```sql
DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 1;

  SELECT pd.id INTO d_mercredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  SELECT pd.id INTO d_vendredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 5;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) VALUES
    (d_lundi,    'Suspension barre fixe', 10, 2, '30s', true, 'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'rehab'),
    (d_mercredi, 'Suspension barre fixe',  5, 2, '30s', true, 'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'rehab'),
    (d_vendredi, 'Suspension barre fixe', 10, 2, '30s', true, 'Décompression vertébrale, relâchement complet, genoux pliés si besoin', 'rehab');
END $$;
```

---

## 7. Migration 005 — Section cooldown

> Ajoute `'cooldown'` comme type de section valide et bascule les suspensions de `rehab` → `cooldown`.

```sql
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_section_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_section_check
  CHECK (section IN ('main', 'rehab', 'cardio', 'cooldown'));

UPDATE exercises SET section = 'cooldown' WHERE name = 'Suspension barre fixe';
```

---

## 8. Migration 006 — Section mobility + mise à jour programmes Lundi/Vendredi/Samedi

> Idempotent : utilise des UPDATE au lieu de DELETE pour préserver l'historique des set_logs.

```sql
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_section_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_section_check
  CHECK (section IN ('main', 'rehab', 'cardio', 'cooldown', 'mobility'));

DO $$
DECLARE
  d_lundi UUID; bar_ez UUID; bar_droite UUID; bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 1;
  SELECT id INTO bar_ez FROM bars WHERE name = 'Barre EZ';
  SELECT id INTO bar_droite FROM bars WHERE name = 'Barre droite';
  SELECT id INTO bar_haltere FROM bars WHERE name = 'Haltère';

  UPDATE exercises SET order_index=6, sets_target=3, reps_target='12',
    notes='Appui genou + main sur le banc, dos neutre, amplitude complète, squeeze en haut', bar_id=bar_haltere
  WHERE program_day_id=d_lundi AND name='Rowing haltère unilatéral';

  UPDATE exercises SET order_index=7, notes='Coudes fixes le long du corps, pas de balancement, descente contrôlée', bar_id=bar_ez
  WHERE program_day_id=d_lundi AND name='Curl barre EZ (supination)';

  UPDATE exercises SET order_index=8, notes='Prise neutre, mouvement lent, squeeze en haut — travaille le brachial et l''avant-bras', bar_id=bar_haltere
  WHERE program_day_id=d_lundi AND name='Curl haltères hammer';

  UPDATE exercises SET order_index=9, sets_target=2,
    notes='Coude calé sur intérieur de cuisse, contraction max en haut, 2s de hold — connexion neuromusculaire', bar_id=bar_haltere
  WHERE program_day_id=d_lundi AND name='Curl haltère concentré';

  UPDATE exercises SET order_index=10 WHERE program_day_id=d_lundi AND name='Plank';
  UPDATE exercises SET order_index=11 WHERE program_day_id=d_lundi AND name='Suspension barre fixe';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
  SELECT d_lundi, 'Rowing barre (barres de sécurité)', 5, 4, '8-10', false,
    'Barres à hauteur mi-tibia ou genoux, dos parallèle au sol, tirer vers le nombril, coudes proches du corps', 'main', bar_droite
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_lundi AND name='Rowing barre (barres de sécurité)');
END $$;

DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 5;
  UPDATE exercises SET name='Dead bug', reps_target='10/côté', sets_target=3,
    notes='Allongé sur le dos, allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent — gainage profond, protège les lombaires'
  WHERE program_day_id=d_vendredi AND name='Crunchs';
END $$;

DO $$
DECLARE
  d_samedi UUID;
BEGIN
  SELECT pd.id INTO d_samedi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 6;
  DELETE FROM cardio_blocks WHERE program_day_id=d_samedi;
  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT * FROM (VALUES
    (d_samedi, 'Open book',                  1, 2, '10/côté',        true, 'Allongé sur le côté, genoux à 90°, ouvrir le bras du dessus vers l''arrière en suivant du regard — clé épaule',  'mobility'),
    (d_samedi, '90/90 hip switch',            2, 1, '10 transitions',  true, 'Assis au sol, jambes à 90° des deux côtés, basculer lentement. Mains au sol si raide.',                          'mobility'),
    (d_samedi, 'Pigeon modifié (sur le dos)', 3, 2, '60s/côté',       true, 'Allongé sur le dos, cheville sur le genou opposé, tirer la cuisse vers la poitrine.',                             'mobility'),
    (d_samedi, 'Respiration diaphragmatique', 4, 1, '10 cycles',      true, 'Allongé sur le ventre, front sur les mains — expirer ventre, pas poitrine. Active la récupération.',              'mobility')
  ) AS t(program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  WHERE NOT EXISTS (
    SELECT 1 FROM exercises WHERE exercises.program_day_id=d_samedi AND exercises.name=t.name
  );
END $$;
```

---

## 9. Migration 007 — Dead bug mercredi + suppression Reverse crunches

```sql
DO $$
DECLARE
  d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
  FROM program_days pd JOIN programs p ON p.id = pd.program_id
  WHERE p.is_active = true AND pd.day_of_week = 3;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_mercredi, 'Dead bug', 0, 2, '8/côté', true,
    'Activation lombaires avant le travail lourd — allonger bras et jambe opposés en expirant, lombaires plaquées au sol, retour lent',
    'main'
  WHERE NOT EXISTS (
    SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Dead bug'
  );

  DELETE FROM set_logs
  WHERE exercise_id IN (
    SELECT id FROM exercises WHERE program_day_id=d_mercredi AND name='Reverse crunches'
  );

  DELETE FROM exercises WHERE program_day_id=d_mercredi AND name='Reverse crunches';
END $$;
```

---

## 10. Migration 008 — Plank début de bloc lundi + Kickbacks 4→3 séries vendredi

```sql
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  -- Décaler rowing + biceps (order 5-9) → 6-10 pour libérer la place
  UPDATE exercises SET order_index=order_index+1
  WHERE program_day_id=d_lundi AND section='main' AND order_index BETWEEN 5 AND 9;

  -- Plank en première position du bloc muscu
  UPDATE exercises SET order_index=5 WHERE program_day_id=d_lundi AND name='Plank';
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE exercises SET sets_target=3 WHERE program_day_id=d_vendredi AND name='Kickbacks haltères';
END $$;
```

---

## 11. Migration 009 — Goblet squat mercredi + fentes 4→3 + suppression mollets

```sql
DO $$
DECLARE d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=3;

  -- Décaler fentes + SLDL pour insérer goblet squat en order 1
  UPDATE exercises SET order_index=order_index+1
  WHERE program_day_id=d_mercredi AND order_index BETWEEN 1 AND 2;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_mercredi, 'Goblet squat', 1, 3, '8', false,
    'Haltère tenu vertical devant la poitrine, descente profonde, genoux dans l''axe des pieds, torse vertical — charge axiale pour la densité osseuse',
    'main'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Goblet squat');

  UPDATE exercises SET bar_id=(SELECT id FROM bars WHERE name='Haltère')
  WHERE program_day_id=d_mercredi AND name='Goblet squat';

  UPDATE exercises SET sets_target=3
  WHERE program_day_id=d_mercredi AND name='Fentes marchées haltères';

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_mercredi AND name='Mollets debout (barre)');

  DELETE FROM exercises WHERE program_day_id=d_mercredi AND name='Mollets debout (barre)';
END $$;
```

---

## 12. Migration 010 — Curl barre EZ avant Rowing haltère (lundi) + suppression Dead bug (vendredi)

```sql
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  UPDATE exercises SET order_index=7 WHERE program_day_id=d_lundi AND name='Curl barre EZ (supination)';
  UPDATE exercises SET order_index=8 WHERE program_day_id=d_lundi AND name='Rowing haltère unilatéral';
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_vendredi AND name='Dead bug');

  DELETE FROM exercises WHERE program_day_id=d_vendredi AND name='Dead bug';
END $$;
```

---

## 13. Migration 011 — Plank lundi→vendredi + suppression Élévations latérales

```sql
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_lundi AND name='Plank');
  DELETE FROM exercises WHERE program_day_id=d_lundi AND name='Plank';

  UPDATE exercises SET order_index=order_index-1
  WHERE program_day_id=d_lundi AND section='main' AND order_index BETWEEN 6 AND 10;
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  DELETE FROM set_logs
  WHERE exercise_id IN (SELECT id FROM exercises WHERE program_day_id=d_vendredi AND name='Élévations latérales haltères');
  DELETE FROM exercises WHERE program_day_id=d_vendredi AND name='Élévations latérales haltères';

  UPDATE exercises SET order_index=order_index-1
  WHERE program_day_id=d_vendredi AND section='main' AND order_index BETWEEN 7 AND 8;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_vendredi, 'Plank', 8, 3, '30-60s', true, null, 'main'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Plank');
END $$;
```

---

## Récap — ce qui est auto-assigné

| Exercice | Barre |
|---|---|
| Curl barre EZ (supination) | Barre EZ (6kg) |
| Extensions triceps barre EZ | Barre EZ (6kg) |
| Soulevé de terre jambes tendues (barre) | Barre droite (10kg) |
| Rowing haltère unilatéral | Haltère (2.5kg) |
| Goblet squat | Haltère (2.5kg) |
| Curl haltères hammer | Haltère (2.5kg) |
| Curl haltère concentré | Haltère (2.5kg) |
| Fentes marchées haltères | Haltère (2.5kg) |
| Développé haltères neutre | Haltère (2.5kg) |
| Élévations latérales haltères | Haltère (2.5kg) |
| Kickbacks haltères | Haltère (2.5kg) |

---

## 14. Migration 012 — Suppression Music Boxing (Mardi)

> Le timer de boxe intègre l'échauffement directement (Round Échauffement). Supprime le bloc "Music Boxing" et remet l'ordre à 1 pour "Sac de boxe".

```sql
DO $$
DECLARE d_mardi UUID;
BEGIN
  SELECT pd.id INTO d_mardi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=2;

  DELETE FROM cardio_blocks WHERE program_day_id=d_mardi AND name='Music Boxing';
  UPDATE cardio_blocks SET order_index=1 WHERE program_day_id=d_mardi AND name='Sac de boxe';
END $$;
```

---

## 15. Migration 013 — Remplace corde à sauter par tapis incliné (lundi + vendredi)

> La corde à sauter n'est pas adaptée au gabarit (impact articulaire trop élevé à 136kg). Remplacée par de la marche inclinée : même stimulus cardio zone 2, sans impact et meilleur pour les lombaires.

```sql
DO $$
DECLARE
  d_lundi UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE cardio_blocks
     SET name='Tapis incliné',
         duration_minutes=20,
         notes='Pente 8-12%, FC cible 110-130 bpm, torse droit'
   WHERE program_day_id=d_lundi AND name='Corde à sauter';

  UPDATE cardio_blocks
     SET name='Tapis incliné',
         duration_minutes=25,
         notes='Pente 8-12%, FC cible 110-130 bpm, torse droit'
   WHERE program_day_id=d_vendredi AND name='Corde à sauter ou Tapis';
END $$;
```

---

## 16. Migration 014 — Suspension barre fixe assistée

> À 136kg le dead hang pur est limité par le grip avant que l'étirement vertébral soit vraiment profitable. Pieds en soutien (sol ou genoux sur banc) déchargent 40-60% du poids → tu tiens 30s propres et la traction spinale est réelle. Épaules engagées légèrement (scapular hang) pour protéger la gauche.

```sql
DO $$
BEGIN
  UPDATE exercises
     SET notes='Pieds au sol ou genoux en appui sur un banc pour décharger le grip. Corps relâché, suspension depuis les épaules (scapular hang léger, pas dead hang passif). 30s continus.'
   WHERE name='Suspension barre fixe'
     AND section='cooldown'
     AND program_day_id IN (
       SELECT pd.id FROM program_days pd
       JOIN programs p ON p.id=pd.program_id
       WHERE p.is_active=true AND pd.day_of_week IN (1, 3, 5)
     );
END $$;
```

---

## 17. Migration 015 — Table `cardio_block_logs`

> Permet de tracker la complétion individuelle de chaque bloc cardio dans une session (important pour les jours muscu+cardio où tu peux faire la muscu sans le cardio).

```sql
create table if not exists cardio_block_logs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references workout_sessions(id) on delete cascade,
  cardio_block_id uuid references cardio_blocks(id) on delete cascade,
  completed_at timestamptz default now(),
  unique (session_id, cardio_block_id)
);

alter table cardio_block_logs enable row level security;

create policy "Users own their cardio_block_logs"
  on cardio_block_logs for all to authenticated
  using (
    exists (
      select 1 from workout_sessions ws
      where ws.id = cardio_block_logs.session_id and ws.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from workout_sessions ws
      where ws.id = cardio_block_logs.session_id and ws.user_id = auth.uid()
    )
  );
```

---

## 18. Migration 016 — Backfill cardios des sessions passées

> Pour chaque session complétée (completed=true), crée un cardio_block_logs pour chaque bloc cardio du program_day. Idempotent (peut être relancée sans doublons).

```sql
insert into cardio_block_logs (session_id, cardio_block_id, completed_at)
select ws.id, cb.id, coalesce(ws.completed_at, ws.session_date::timestamptz)
from workout_sessions ws
join cardio_blocks cb on cb.program_day_id = ws.program_day_id
where ws.completed = true
on conflict (session_id, cardio_block_id) do nothing;
```

---

## 19. Migration 017 — Policy UPDATE sur `exercises` + `cardio_blocks`

> La migration 001 n'a créé qu'une policy SELECT sur ces tables. Du coup l'UPDATE depuis SettingsView (changement de barre) était silencieusement bloqué par RLS — pas d'erreur côté client, juste 0 ligne affectée. Cette migration ouvre l'UPDATE aux utilisateurs authentifiés (cohérent avec le SELECT existant, programme partagé sans `user_id`).

```sql
create policy "Authenticated users can update exercises"
  on exercises for update to authenticated
  using (true) with check (true);

create policy "Authenticated users can update cardio_blocks"
  on cardio_blocks for update to authenticated
  using (true) with check (true);
```

---

## 20. Migration 018 — Table `bodyweight_logs`

> Tracking du poids corporel au fil du temps (graph dans Stats). Une entrée par jour max (upsert sur `user_id + log_date`).

```sql
create table if not exists bodyweight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null default current_date,
  weight_kg decimal(5,1) not null check (weight_kg > 0 and weight_kg < 500),
  notes text,
  created_at timestamptz default now(),
  unique (user_id, log_date)
);

create index if not exists idx_bodyweight_logs_user_date
  on bodyweight_logs (user_id, log_date desc);

alter table bodyweight_logs enable row level security;

create policy "Users own their bodyweight_logs"
  on bodyweight_logs for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

---

## 21. Migration 019 — Table `soreness_logs`

> Check-in douleur avant séance (épaule G prioritaire). `level` 0-3, une entrée par (jour, body_part).

```sql
create table if not exists soreness_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null default current_date,
  body_part text not null,
  level int not null check (level between 0 and 3),
  notes text,
  created_at timestamptz default now(),
  unique (user_id, log_date, body_part)
);

create index if not exists idx_soreness_logs_user_date
  on soreness_logs (user_id, log_date desc);

alter table soreness_logs enable row level security;

create policy "Users own their soreness_logs"
  on soreness_logs for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

---

## 22. Migration 020 — Colonne `muscle_group` sur `exercises` + backfill

> Permet le calcul du volume hebdomadaire par groupe musculaire. Backfill best-effort via `name ILIKE`. Si un exo te semble mal classé, fix-le manuellement dans la table `exercises`.

```sql
alter table exercises add column if not exists muscle_group text;

update exercises set muscle_group = 'back'
  where section = 'main' and (name ilike '%rowing%');

update exercises set muscle_group = 'biceps'
  where section = 'main' and name ilike 'curl%';

update exercises set muscle_group = 'chest'
  where section = 'main' and name ilike '%développé%';

update exercises set muscle_group = 'triceps'
  where section = 'main' and (name ilike '%triceps%' or name ilike '%kickback%');

update exercises set muscle_group = 'quads'
  where section = 'main' and (name ilike '%squat%' or name ilike '%fente%');

update exercises set muscle_group = 'hamstrings'
  where section = 'main' and name ilike '%soulevé de terre%';

update exercises set muscle_group = 'core'
  where section = 'main' and (name ilike '%plank%' or name ilike '%dead bug%');
```

---

## 23. Migration 021 — Métriques sur `cardio_block_logs`

> Permet de logger la durée réelle, la FC moyenne et des notes par bloc cardio. Utile pour valider que tu es bien en zone 2 (FC 120-140) sur Vélo, ou la durée réelle vs cible sur Tapis incliné.

```sql
alter table cardio_block_logs
  add column if not exists duration_seconds int,
  add column if not exists avg_hr int check (avg_hr is null or (avg_hr between 40 and 250)),
  add column if not exists notes text;
```

---

## 24. Migration 022 — Flag `is_per_side` sur `exercises`

> Pour les exos unilatéraux qui se font "sur les deux côtés par série" (Pendulaires de Codman, Stretch doorway), le timer enchaîne automatiquement Côté 1 → Côté 2 avec un mini-décompte entre les deux. La cible `30s` reste par côté ; le total loggué est `60s` (somme des deux côtés).

```sql
alter table exercises add column if not exists is_per_side boolean not null default false;

update exercises set is_per_side = true
  where name in ('Pendulaires de Codman', 'Stretch doorway');
```

---

## 25. Migration 023 — Cooldown décompression : Suspension 2×30s → 1×30-45s + ajout Genoux-poitrine

> La suspension barre fixe debout n'apporte pas vraiment de décompression lombaire à 136kg (le grip sature avant que le bassin tire passivement). Du coup on la garde pour l'épaule (capsule, sous-acromial, scapular hang) avec **1×30-45s** au lieu de 2×30s, et on ajoute **Genoux-poitrine 1×60s** pour la déco lombaire passive (zéro effort, max relâchement). 2 séries de cooldown au total au lieu de 2 séries identiques.

```sql
UPDATE exercises
   SET sets_target = 1,
       reps_target = '30-45s'
 WHERE name = 'Suspension barre fixe'
   AND section = 'cooldown';

DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
  notes_text TEXT := 'Couché sur le dos, ramener les 2 genoux vers la poitrine, mains autour des tibias, relâcher complètement le bas du dos. Respiration lente.';
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_lundi, 'Genoux-poitrine',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_lundi),
    1, '60s', true, notes_text, 'cooldown'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_lundi AND name='Genoux-poitrine');

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_mercredi, 'Genoux-poitrine',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_mercredi),
    1, '60s', true, notes_text, 'cooldown'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Genoux-poitrine');

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_vendredi, 'Genoux-poitrine',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_vendredi),
    1, '60s', true, notes_text, 'cooldown'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Genoux-poitrine');
END $$;
```

---

## 26. Migration 024 — Notes tapis incliné recalibrées (pente max 3% + repères sans capteur FC)

> Le tapis perso plafonne à 3% (impossible de viser 8-12%). Sans chest strap / montre la fourchette FC est inutilisable. On bascule sur vitesse + talk test + RPE.

```sql
UPDATE cardio_blocks
   SET notes = 'Pente 3% (max), 5,5-6,5 km/h. Talk test : phrases complètes possibles. RPE 4-5/10 (effort modéré, soutenable 1h théorique). Torse droit.'
 WHERE name = 'Tapis incliné'
   AND program_day_id IN (
     SELECT pd.id FROM program_days pd
     JOIN programs p ON p.id = pd.program_id
     WHERE p.is_active = true AND pd.day_of_week IN (1, 5)
   );
```

---

## 27. Migration 025 — Colonne `profile_data` sur `user_state`

> Stockage du profil utilisateur (texte libre `profil` + `objectifs`) pour l'export markdown destiné à l'analyse IA. La feature dans Settings remplit ces champs et les inclut dans le markdown généré. Aucune donnée perso n'est commitée — chaque utilisateur remplit son profil depuis l'UI.

```sql
ALTER TABLE user_state ADD COLUMN IF NOT EXISTS profile_data jsonb;
```

---

## 28. Migration 026 — Améliorations programme post-audit IA

> Suite à un audit IA, 4 ajustements pour combler les vrais trous identifiés (les autres critiques étaient à côté de la plaque, parasitées par une incompréhension du modèle de tare — fixée séparément côté export markdown).
>
> 1. **Pulldown élastique** sur lundi → comble le trou tirage vertical, santé scapulaire / épaule G (lower trap + rhomboïdes)
> 2. **Mollets debout (barre)** sur mercredi → santé tendineuse à 136kg + cardio impact régulier
> 3. **Pallof press élastique** sur vendredi → anti-rotation core, transfert lombaire sur tous les compounds
> 4. **Goblet squat** : note recalibrée pour morpho 1m97 + stockage abdominal (parallèle stricte, plus profond uniquement si mobilité OK — évite le butt wink à 136kg)

```sql
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
  SELECT d_lundi, 'Pulldown élastique',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_lundi AND section = 'main'),
    3, '12-15', true,
    'Élastique fixé en hauteur (porte / barre fixe), tirer vers la poitrine en abaissant les omoplates en fin de mouvement. Comble le tirage vertical absent du programme — recrute lower trap + rhomboïdes, clé pour la santé scapulaire et l''épaule gauche.',
    'main'
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_lundi AND name='Pulldown élastique');
END $$;

DO $$
DECLARE d_mercredi UUID; bar_droite UUID;
BEGIN
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT id INTO bar_droite FROM bars WHERE name='Barre droite';

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
  SELECT d_mercredi, 'Mollets debout (barre)',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_mercredi AND section = 'main'),
    3, '15-20', false,
    'Monter sur disque ou step pour amplitude complète. Pause 1s en haut, descente lente. Important pour santé Achille à ton poids + cardio régulier.',
    'main', bar_droite
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_mercredi AND name='Mollets debout (barre)');
END $$;

DO $$
DECLARE d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;

  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, is_per_side)
  SELECT d_vendredi, 'Pallof press élastique',
    (SELECT COALESCE(MAX(order_index), 0) + 1 FROM exercises WHERE program_day_id = d_vendredi AND section = 'main'),
    3, '10', true,
    'Élastique fixé sur le côté à hauteur de poitrine, debout perpendiculaire au point d''ancrage. Pousser l''élastique droit devant, résister à la rotation, retour lent. Anti-rotation = transfert direct sur la stabilité lombaire dans tous les compounds.',
    'main', true
  WHERE NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Pallof press élastique');
END $$;

UPDATE exercises
   SET notes = 'Haltère tenu vertical devant la poitrine, descente jusqu''à parallèle stricte (cuisses parallèles au sol). Plus bas seulement si mobilité chevilles/hanches le permet sans cambrer le bas du dos (butt wink à éviter, surtout vu morpho longues jambes + stockage abdominal). Genoux dans l''axe des pieds, torse vertical — charge axiale pour la densité osseuse.'
 WHERE name = 'Goblet squat'
   AND program_day_id IN (
     SELECT pd.id FROM program_days pd
     JOIN programs p ON p.id = pd.program_id
     WHERE p.is_active = true AND pd.day_of_week = 3
   );
```

---

## 29. Migration 027 — Élévations latérales + swap cardio mardi/jeudi + Pallof → Farmer's carry

> 3 ajustements ciblés issus du 2e audit IA :
> 1. **Élévations latérales haltères** (vendredi, 3×12-15) — comble le trou delt latéral, levier V-taper / focus bras
> 2. **Swap cardio** : boxe → jeudi (48h après upper pull, fini l'interférence dorsaux/biceps/delts post), vélo → mardi
> 3. **Pallof press → Farmer's carry** (vendredi) — plus simple à exécuter, meilleur transfert "rester droit sous charge" pour profil 136kg + lombaires faibles. Reps cible 20-30s (≈ 30-40m de marche)

```sql
DO $$
DECLARE d_vendredi UUID; bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT id INTO bar_haltere FROM bars WHERE name='Haltère';

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Élévations latérales haltères') THEN
    UPDATE exercises SET order_index = order_index + 1
    WHERE program_day_id = d_vendredi AND section = 'main' AND order_index >= 6;

    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
    VALUES (d_vendredi, 'Élévations latérales haltères', 6, 3, '12-15', false,
      'Haltères, mouvement latéral, jamais au-dessus de l''horizontale (épaule G). Pause brève en haut, descente contrôlée. Légère flexion du coude pour réduire stress poignet.',
      'main', bar_haltere);
  END IF;
END $$;

DO $$
DECLARE d_vendredi UUID; bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT id INTO bar_haltere FROM bars WHERE name='Haltère';

  UPDATE exercises
     SET name='Farmer''s carry', sets_target=3, reps_target='20-30s',
         is_bodyweight=false, is_per_side=false, bar_id=bar_haltere,
         notes='Haltères chargées le plus lourd possible avec posture parfaite (~30-40m de marche, soit 20-30s sous charge). Tronc gainé, scapulae rétractées, ne pas se laisser tirer en avant ni latéralement. Respiration courte et active. Repos 60-90s entre séries.'
   WHERE program_day_id=d_vendredi AND name='Pallof press élastique';
END $$;

DO $$
DECLARE d_mardi UUID; d_jeudi UUID;
BEGIN
  SELECT pd.id INTO d_mardi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=2;
  SELECT pd.id INTO d_jeudi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=4;

  IF EXISTS (SELECT 1 FROM cardio_blocks WHERE name='Sac de boxe' AND program_day_id=d_mardi) THEN
    UPDATE cardio_blocks SET program_day_id=d_jeudi
    WHERE name='Sac de boxe' AND program_day_id=d_mardi;
    UPDATE cardio_blocks SET program_day_id=d_mardi
    WHERE name IN ('Zone 2 (FC 120-140)', 'Zone 4 (FC 160-175)') AND program_day_id=d_jeudi;
    UPDATE program_days SET name='Cardio Vélo' WHERE id=d_mardi;
    UPDATE program_days SET name='Cardio Boxe' WHERE id=d_jeudi;
  END IF;
END $$;
```

---

## 30. Migration 028 — Backup mensuel auto par email

> Edge function qui dump toutes les tables en JSON et l'envoie en pièce jointe via Resend. pg_cron déclenche ça le 1er du mois à 10h UTC.

### A. Compte Resend (gratuit, 3000 mails/mois)

1. Créer un compte sur https://resend.com avec ton email perso
2. Aller dans **API Keys** → **Create API Key** → permissions « Sending access » → copier la clé `re_...`
3. Le sender de test `onboarding@resend.dev` envoie uniquement vers l'email du compte Resend → c'est exactement notre cas, aucun domaine à configurer

### B. Activer les extensions Supabase

Dans Supabase Dashboard → **Database** → **Extensions** :
- `pg_cron` (s'installe dans `pg_catalog` automatiquement)
- `pg_net` (schema `extensions`)

### C. Déployer l'Edge function

Code source : `supabase/functions/monthly-backup/index.ts`

1. Dashboard → **Edge Functions** → **Deploy a new function**
2. Nom : `monthly-backup`
3. Coller le contenu de `supabase/functions/monthly-backup/index.ts`
4. Deploy
5. Dans la fiche de la function → **Secrets** → ajouter :
   - `RESEND_API_KEY` = ta clé `re_...`
   - `BACKUP_TO_EMAIL` = ton email perso
   - `BACKUP_FROM_EMAIL` (optionnel) = `GymLog Backup <onboarding@resend.dev>` par défaut
6. Noter l'**URL d'invocation** affichée en haut de la fiche (forme `https://<project>.supabase.co/functions/v1/monthly-backup`) — utilisée à l'étape D

### D. Stocker l'URL et la service_role key dans Vault

Dashboard → **Database** → **Vault** → **Add new secret** (à faire 2 fois) :

| Name | Secret |
|---|---|
| `gymlog_backup_url` | URL d'invocation notée à l'étape C5 |
| `gymlog_service_role_key` | Project Settings → API → `service_role` (jamais committer cette clé) |

### E. Créer le cron

```sql
do $unsched$
begin
  perform cron.unschedule('gymlog-monthly-backup');
exception when others then null;
end $unsched$;

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
```

### F. Tester

- Dans la PWA : **Réglages → Données → 📧 Envoyer un backup par email** → vérifier la réception (1-2 min)
- Vérifier le job cron : `select * from cron.job where jobname = 'gymlog-monthly-backup';`
- Voir les dernières exécutions : `select * from cron.job_run_details order by start_time desc limit 5;`

---

## 31. Migration 029 — Progression cardio (overload progressif sur la durée)

> Mirroring de la double progression poids (`src/lib/progression.js`) appliquée à la durée cardio. Pour la perte de gras (priorité #1) et à 136kg, le levier sûr est la **durée** (pas la vitesse/incline → charge articulaire). La logique vit dans `src/lib/cardioProgression.js` : si les 2 dernières séances ont été complétées au target courant, on suggère le palier suivant (+`progression_step_minutes`), capé à `duration_target_max_minutes`.
>
> Cette migration ajoute les 2 colonnes nécessaires + recalibre les targets initiaux et les plafonds par bloc.
>
> **Plafonds & cibles initiales** :
> | Bloc | Target initial | Plafond |
> |---|---|---|
> | Tapis incliné lundi (post Pull) | 35 min | 50 min |
> | Tapis 3% mercredi (post Lower) | 35 min | 45 min ← asymétrie post-lower |
> | Tapis incliné vendredi (post Push) | 35 min | 50 min |
> | Sac de boxe jeudi | 25 min | 30 min |
> | Vélo Z2 mardi | 40 min ← alignement réalité | 50 min |
> | Vélo Z4 mardi | 10 min | 15 min |

```sql
ALTER TABLE cardio_blocks
  ADD COLUMN IF NOT EXISTS duration_target_max_minutes int,
  ADD COLUMN IF NOT EXISTS progression_step_minutes int NOT NULL DEFAULT 2;

DO $$
DECLARE
  d_lundi    UUID;
  d_mardi    UUID;
  d_mercredi UUID;
  d_jeudi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_mardi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=2;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT pd.id INTO d_jeudi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=4;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE cardio_blocks SET duration_minutes=35, duration_target_max_minutes=50
   WHERE program_day_id=d_lundi AND name='Tapis incliné';

  UPDATE cardio_blocks SET duration_minutes=35, duration_target_max_minutes=45
   WHERE program_day_id=d_mercredi AND name='Tapis 3%';

  UPDATE cardio_blocks SET duration_minutes=35, duration_target_max_minutes=50
   WHERE program_day_id=d_vendredi AND name='Tapis incliné';

  UPDATE cardio_blocks SET duration_minutes=40, duration_target_max_minutes=50
   WHERE program_day_id=d_mardi AND name='Zone 2 (FC 120-140)';

  UPDATE cardio_blocks SET duration_target_max_minutes=15
   WHERE program_day_id=d_mardi AND name='Zone 4 (FC 160-175)';

  UPDATE cardio_blocks SET duration_target_max_minutes=30
   WHERE program_day_id=d_jeudi AND name='Sac de boxe';
END $$;
```

---

## 32. Migration 030 — Simplification volume bras (adhérence + rééquilibrage triceps>biceps)

> **Vendredi** :
> - Drop **Kickbacks haltères** — non senti par l'utilisateur, exo peu efficace pour lui (resistance peak en position raccourcie = pic de charge où le triceps a le moins de levier)
> - Drop **Farmer's carry** — 1 seul haltère dispo à la maison + pickup risqué pour lombaires faibles à 136kg sans trap bar. Couverture anti-extension/anti-flexion latérale assurée par dead bug (mercredi) + plank
> - **Plank** 3 → 2 sets — compromis adhérence / stabilisation lombaire post-développé
> - **Extensions triceps barre EZ** renommé **Extensions overhead barre EZ** — clarification, l'exo réellement effectué est de l'overhead (banc 85-90°), pas du skull crusher. La description est étoffée pour préciser l'angle correct (≠ 30° du développé incliné)
> - Ajout **Barre au front** (skull crusher EZ, 3×10-12) — complément en position mi-longueur sur la longue portion du triceps. Avec l'overhead = couverture biomécanique complète (étirement max + mi-longueur)
>
> **Lundi** :
> - Drop **Curl haltère concentré** — compression du volume biceps en phase déficit (cf. CLAUDE.md "compresser à 3-4 exos suffit pour préserver")
> - **Curl barre EZ (supination)** 4 → 3 sets — rééquilibrage volume biceps/triceps. Le triceps représente ~60-65% du volume du bras vs ~30-35% pour le biceps : pour l'objectif "gros bras", le triceps doit recevoir plus de stimulus direct que le biceps
>
> **Bilan post-migration** :
> - Triceps direct : 4+3 = **7 sets/sem** (vs 4 avant)
> - Biceps direct : 3+3 = **6 sets/sem** (vs 9 avant)
> - Vendredi : **13 sets main** (vs 20 avant) → -7 sets, ~15 min gagnées sur la séance pour adhérence

**⚠️ Note** : cette migration supprime des exos qui ont des `set_logs` historiques (curl concentré, kickbacks, farmer's carry). Il faut donc supprimer les logs avant l'exo (FK constraint), ce qui détruit l'historique. Même pattern qu'utilisé par les migrations 010 et 011.

```sql
DO $$
DECLARE d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
     WHERE program_day_id=d_lundi AND name='Curl haltère concentré'
   );

  DELETE FROM exercises
   WHERE program_day_id=d_lundi AND name='Curl haltère concentré';

  UPDATE exercises SET sets_target=3
   WHERE program_day_id=d_lundi AND name='Curl barre EZ (supination)';
END $$;

DO $$
DECLARE d_vendredi UUID; bar_ez UUID;
BEGIN
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT id INTO bar_ez FROM bars WHERE name='Barre EZ';

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
     WHERE program_day_id=d_vendredi
       AND name IN ('Kickbacks haltères', 'Farmer''s carry')
   );

  DELETE FROM exercises
   WHERE program_day_id=d_vendredi AND name='Kickbacks haltères';

  DELETE FROM exercises
   WHERE program_day_id=d_vendredi AND name='Farmer''s carry';

  UPDATE exercises SET sets_target=2
   WHERE program_day_id=d_vendredi AND name='Plank';

  UPDATE exercises
     SET name='Extensions overhead barre EZ',
         notes='EXÉCUTION : Assis sur le banc, dossier le plus VERTICAL possible (~85-90°, PAS 30° comme le développé incliné — sinon les bras ne peuvent pas vraiment passer au-dessus de la tête et tu perds le bénéfice principal). Tenir la barre EZ bras tendus au-dessus du crâne, prise pronation sur les courbes intérieures. COUDES POINTÉS VERS LE PLAFOND, fixes : ils ne bougent pas, ne s''écartent pas vers l''extérieur. Descendre la barre derrière la nuque en pliant uniquement les coudes. Remonter en extension contrôlée, pas de verrouillage brutal en haut. CIBLE : longue portion du triceps en position étirée maximale (épaule en flexion 180° + coude fléchi = double étirement de la longue portion qui croise les 2 articulations).'
   WHERE program_day_id=d_vendredi AND name='Extensions triceps barre EZ';

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_vendredi AND name='Barre au front') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id)
    VALUES (d_vendredi, 'Barre au front', 8, 3, '10-12', false,
      'EXÉCUTION : Allongé sur le banc PLAT (0°). Tenir la barre EZ bras tendus, légèrement INCLINÉS VERS LA TÊTE (pas strictement perpendiculaires au sol — ça maintient la tension sur le triceps en haut et réduit le levier sur le coude). Coudes fixes, pointés vers le plafond, ne pas les écarter latéralement. Descendre la barre vers le HAUT du front : s''arrêter ~5cm AVANT de toucher le front (préserver les coudes, pas besoin de full ROM). Remonter en extension contrôlée sans verrouillage brutal. CIBLE : longue portion du triceps en position mi-longueur (complément de l''overhead qui couvre l''étirement max). ATTENTION COUDES : exo très exigeant pour les tendons. Charge MODÉRÉE, jamais forcer si douleur tendineuse. Si le coude souffre après 2-3 séances, on ré-évalue.',
      'main', bar_ez);
  END IF;
END $$;
```

---

## 33. Migration 031 — Lundi : simplification dos (alignement objectifs)

> Suite à la clarification des objectifs (cf. CLAUDE.md mis à jour : bras = seul muscle visé en hypertrophie, le reste = entretien santé/fonction), le bloc dos lundi (10 sets directs sur 3 exos) était sur-dimensionné. Il y avait aussi des problèmes spécifiques :
>
> - **Rowing barre** : amplitude limitée par le stockage abdominal du user (la barre touche le ventre avant rétraction scapulaire complète) → faux travail. Problème morphologique connu chez les profils 1m97/136kg+ avec abdo prononcé.
> - **Rowing haltère unilatéral** : pas senti par le user, redondant avec rowing barre.
> - **Pulldown élastique** : conflit avec préférence user (pas d'élastique pour la muscu, réservé à la rehab).
>
> **Solution** : drop des 3 exos dos, remplacement par UN SEUL exo bien fait pour le profil :
>
> - **Chest-supported row haltère 4×8-12 unilatéral** : poitrine appuyée sur banc incliné 30°, élimine totalement le problème du bide, dos protégé (zéro stress lombaire), zéro momentum possible (mind-muscle ++), unilatéral utilisant son seul haltère. C'est l'exo standard recommandé pour les profils "haut + lourd + abdo" (Nippard, Israetel, Cavaliere).
>
> **Bilan** :
> - Lundi main : 5 exos → **3 exos** (1 row + 2 curls), gain ~15-20 min sur la séance
> - Volume dos direct : 10 sets → **4 sets** (alignement "minimum efficace pour santé/posture/biceps indirect")
> - Volume biceps : inchangé (3 EZ + 3 hammer = 6 directs + ~3-4 indirects via le row)
>
> **⚠️ Note** : cette migration supprime des exos qui ont des `set_logs` historiques (rowing barre, rowing haltère unilatéral). Il faut donc supprimer les logs avant l'exo (FK constraint), ce qui détruit l'historique. Même pattern qu'utilisé par les migrations 010, 011, 030.

```sql
DO $$
DECLARE d_lundi UUID; bar_haltere UUID;
BEGIN
  SELECT pd.id INTO d_lundi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT id INTO bar_haltere FROM bars WHERE name='Haltère';

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
     WHERE program_day_id=d_lundi
       AND name IN ('Rowing barre (barres de sécurité)', 'Rowing haltère unilatéral', 'Pulldown élastique')
   );

  DELETE FROM exercises
   WHERE program_day_id=d_lundi
     AND name IN ('Rowing barre (barres de sécurité)', 'Rowing haltère unilatéral', 'Pulldown élastique');

  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id=d_lundi AND name='Chest-supported row haltère') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, bar_id, is_per_side)
    VALUES (d_lundi, 'Chest-supported row haltère', 5, 4, '8-12', false,
      'SETUP : Banc inclinable réglé à ~30° (dossier vers le haut). Haltère posé au sol à côté/sous l''extrémité haute du banc. Te positionner FACE CONTRE le banc : poitrine + ventre appuyés sur le dossier. Pieds au sol stables. Front sur le bord haut du banc, regard légèrement vers le haut.

EXÉCUTION : Une main attrape l''haltère, bras pendant librement = étirement complet du dos en bas. Autre main tient le bord du banc pour stabiliser. TIRER l''haltère vers la HANCHE (pas vers la poitrine) en pliant le coude ET en RÉTRACTANT l''omoplate. Pause brève en haut, sentir la contraction milieu du dos. DESCENTE LENTE 3-4s jusqu''à étirement complet. Zéro momentum, buste immobile.

POINTS CLÉS :
- COUDE PROCHE DU CORPS (pas écarté) → grand dorsal + rhomboïdes
- INITIER avec l''omoplate, le bras suit
- ÉTIREMENT COMPLET en bas — essentiel
- 3s descente excentrique
- Si tu sens biceps et pas dos = trop lourd ou mauvaise initiation

UNILATÉRAL : tous les sets d''un côté puis l''autre, ou alterner. PREMIÈRE SÉANCE : charge légère, mater des vidéos ("dumbbell chest-supported row" / "incline dumbbell row 30 degrees" — Nippard ou Cavaliere).

ATTENTION BIDE : c''est exactement pour ça qu''on remplace le rowing barre — ici le banc te sépare du sol, plus aucune limitation d''amplitude.',
      'main', bar_haltere, true);
  END IF;

  UPDATE exercises SET order_index=6
   WHERE program_day_id=d_lundi AND name='Curl barre EZ (supination)';

  UPDATE exercises SET order_index=7
   WHERE program_day_id=d_lundi AND name='Curl haltères hammer';
END $$;
```

---

## 34. Migration 032 — Trim final aligné objectifs + ajout marche tapis samedi

> Audit final post-clarification objectifs (cf. CLAUDE.md). Drop des exos marginaux pour les objectifs réels du user (bras hypertrophie + santé/fonction pour le reste), ajout d'un cardio NEAT samedi.
>
> **DROPS (5 exos)** — tous marginaux pour les objectifs réels :
> - **Vendredi : Élévations latérales haltère** : pure esthétique (delt latéral / V-taper). Profil user = naturellement large (1m97/136kg, carrure imposante) → ajouter largeur d'épaule serait esthétiquement contre-productif. Aucun bénéfice santé/fonction.
> - **Mercredi : Fentes marchées haltères** : redondance partielle avec goblet squat. Densité osseuse + insuline + NEAT couverts par goblet + SLDL + mollets. Friction adhérence (setup chiant) pour gain marginal.
> - **Samedi : Respiration diaphragmatique** : utile mais cosmétique côté programme.
> - **Samedi : 90/90 hip switch** : redondance avec Pigeon modifié.
> - **Lundi + Vendredi : Pendulaires de Codman** : rehab passif, user ne le sent pas. Stretch doorway (gardé) couvre l'étirement épaule G ; les 2 actifs (rotations externes + face pulls) restent intacts.
>
> **ADD :**
> - **Samedi cardio : Marche tapis** 35 min (cible max 50) : NEAT structuré, zéro interférence muscu, soutenable en déficit. Préférée à la marche dehors car loggable → adhérence.
>
> **Bilan :** ~20 min/sem de muscu en moins (hors cardio samedi), 5 exos en moins, +35 min de cardio Z1-Z2 (marche tapis). Aucune perte sur les priorités réelles.
>
> **⚠️ Note** : cette migration supprime des exos qui ont des `set_logs` historiques. Suppression des logs préalable (FK constraint), même pattern qu'utilisé par les migrations 010, 011, 030, 031.

```sql
DO $$
DECLARE
  d_lundi UUID; d_mercredi UUID; d_vendredi UUID; d_samedi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT pd.id INTO d_samedi   FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=6;

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises WHERE
       (program_day_id = d_vendredi AND name = 'Élévations latérales haltères')
       OR (program_day_id = d_mercredi AND name = 'Fentes marchées haltères')
       OR (program_day_id = d_samedi AND name IN ('Respiration diaphragmatique', '90/90 hip switch'))
       OR (program_day_id IN (d_lundi, d_vendredi) AND name = 'Pendulaires de Codman')
   );

  DELETE FROM exercises
   WHERE program_day_id = d_vendredi AND name = 'Élévations latérales haltères';
  DELETE FROM exercises
   WHERE program_day_id = d_mercredi AND name = 'Fentes marchées haltères';
  DELETE FROM exercises
   WHERE program_day_id = d_samedi AND name IN ('Respiration diaphragmatique', '90/90 hip switch');
  DELETE FROM exercises
   WHERE program_day_id IN (d_lundi, d_vendredi) AND name = 'Pendulaires de Codman';
END $$;

DO $$
DECLARE d_samedi UUID;
BEGIN
  SELECT pd.id INTO d_samedi FROM program_days pd JOIN programs p ON p.id=pd.program_id
  WHERE p.is_active=true AND pd.day_of_week=6;

  IF NOT EXISTS (SELECT 1 FROM cardio_blocks WHERE program_day_id=d_samedi AND name='Marche tapis') THEN
    INSERT INTO cardio_blocks (program_day_id, name, duration_minutes, duration_target_max_minutes, progression_step_minutes, order_index, notes)
    VALUES (d_samedi, 'Marche tapis', 35, 50, 2, 1,
      'Récup active + NEAT structuré pour la perte de gras (priorité #1). Plat ou très légère pente (3% max). Zone 1-2 (FC ~110-120, conversation facile). Zéro stress muscu, zéro interférence avec les séances de la semaine, soutenable en déficit. Préférée à la marche dehors car loggable = adhérence supérieure.');
  END IF;
END $$;
```

---

## 35. Migration 033 — Raccourcir notes Chest-supported row

> L'exo est en place depuis 031 et le user le connaît : on retire le tutoriel détaillé (setup verbeux, "première séance", "attention bide") et on garde uniquement les cues qui font sentir le DOS plutôt que le biceps (cible muscle, initiation omoplate avant bras, coude vers la hanche, debug "je sens le biceps").

```sql
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  UPDATE exercises
     SET notes = 'Cible : grand dorsal + milieu du dos.

Banc 30°, face contre le dossier. Tirer le COUDE vers la HANCHE en initiant par l''omoplate (omoplate AVANT bras). Descente lente 3s, étirement complet en bas.

Si tu sens le biceps = allège et pense "omoplate d''abord".'
   WHERE program_day_id = d_lundi
     AND name = 'Chest-supported row haltère';
END $$;
```

## 36. Migration 034 — Suppression du cardio "marche" redondant avec la marche bureau

> Le user ajoute une marche quotidienne devant l'ordi (~1h30-2h/jour) comme moteur principal de la perte de gras (priorité #1). À 136 kg ≈ 250-350 kcal/h, soit plus que tout le cardio structuré de la semaine, sans friction ni pic de faim. Le cardio "marche" en steady-state devient donc redondant et nuit à l'adhérence (séances rallongées, faim post-cardio). On vire les 3 tapis post-muscu (lundi/mercredi/vendredi) + la marche tapis du samedi. On garde la boxe (mardi, plaisir + intensité) et le vélo (jeudi, plaisir + Zone 4 = stimulus cœur/longévité). Logs cardio supprimés en cascade.

```sql
DO $$
DECLARE
  d_lundi    UUID;
  d_mercredi UUID;
  d_vendredi UUID;
  d_samedi   UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_mercredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=3;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;
  SELECT pd.id INTO d_samedi   FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=6;

  DELETE FROM cardio_blocks WHERE program_day_id = d_lundi    AND name = 'Tapis incliné';
  DELETE FROM cardio_blocks WHERE program_day_id = d_mercredi AND name = 'Tapis 3%';
  DELETE FROM cardio_blocks WHERE program_day_id = d_vendredi AND name = 'Tapis incliné';
  DELETE FROM cardio_blocks WHERE program_day_id = d_samedi   AND name = 'Marche tapis';
END $$;
```

---

## 37. Migration 035 — Rehab épaule → dose d'entretien (prehab)

> L'épaule gauche va nettement mieux (rarement sentie). Le protocole rehab a fait son travail : on passe de dose thérapeutique à dose d'entretien plutôt que de supprimer le bloc (récidive classique chez profil 136 kg + poussée + douleurs récurrentes ; objectifs #2 santé/posture et #3 éviter blessures prioritaires sur l'hypertrophie). Rotations externes et face pulls passent de 3×15 → 2×15 (lundi + vendredi). Le stretch doorway (2×30s) reste tel quel : utile pour la posture indépendamment de la douleur, et programmé plutôt que "à la demande" car le user ne tient pas les habitudes non-loggables. Aucun set_log supprimé (seul `sets_target` change).

```sql
DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id=pd.program_id WHERE p.is_active=true AND pd.day_of_week=5;

  UPDATE exercises
     SET sets_target = 2
   WHERE program_day_id IN (d_lundi, d_vendredi)
     AND name IN ('Rotations externes élastique', 'Face pulls élastique');
END $$;
```

---

## 38. Migration 036 — Raccourcir notes triceps vendredi

> Le user a assimilé l'exécution des 2 exos triceps (overhead 22 kg testé, sensations triceps nettes, aucune douleur épaule/coude) : on retire le tutoriel détaillé et on garde l'essentiel du quotidien — l'**angle du banc** (le cue le plus facile à oublier et qui change tout) + 1-2 cues clés. Pour la barre au front on conserve la mise en garde coudes (sécurité tendineuse). Aucun set_log touché (seul `notes` change).

```sql
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  UPDATE exercises
     SET notes = 'Dossier VERTICAL (~85-90°). Barre derrière la nuque, coudes pointés au plafond et fixes (ne pas les écarter). Cible : longue portion étirée.'
   WHERE program_day_id = d_vendredi
     AND name = 'Extensions overhead barre EZ';

  UPDATE exercises
     SET notes = 'Banc PLAT (0°). Bras légèrement inclinés vers la tête, coudes fixes pointés au plafond. Descendre vers le front, s''arrêter ~5cm avant.

Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse.'
   WHERE program_day_id = d_vendredi
     AND name = 'Barre au front';
END $$;
```

---

## 39. Migration 037 — Suppression du système XP / niveaux

> La gamification XP + ladder de niveaux (Recrue → Légende) est cosmétique et sans valeur pour un usage solo : pas de classement ni d'enjeu, seuils arbitraires, "gamable" par le user qui code lui-même l'app. On la retire entièrement. On **garde le streak** (🔥) : seul mécanisme appuyé par la science du comportement (aversion à la perte) et aligné sur la contrainte n°1 du user = l'adhérence. Côté app : `LevelBar` devient `StreakBar` (streak seul), plus d'XP dans l'overlay de célébration / Stats / Settings / History / Program. Colonnes `streak_*` conservées.

```sql
ALTER TABLE program_days DROP COLUMN IF EXISTS xp_reward;
ALTER TABLE user_state   DROP COLUMN IF EXISTS xp_total;
ALTER TABLE user_state   DROP COLUMN IF EXISTS level;
```

---

## 40. Migration 038 — Inclinaison banc + cran (JOROTO MD80) + notes condensées

> Pour chaque exo sur banc, on ajoute l'inclinaison idéale **et le cran correspondant sur le banc du user (JOROTO MD80)** pour la fluidité. Le MD80 a 6 positions de dossier ; angle mesuré assise↔dossier sur la fiche produit → inclinaison réelle = `180° - angle fiche`. Crans numérotés du plat vers le vertical : **cran 1 = plat (0°)**, cran 2 = ~25° (1er au-dessus du plat), cran 3 = ~45°, cran 4 = ~55°, cran 5 = ~75°, **cran 6 = vertical (~90°)** (la 7e position 210° = décliné via l'assise, non utilisée). Mapping : Barre au front → cran 1, Chest-supported row + Développé incliné → cran 2 (~25°, le + proche de 30°), Extensions overhead → cran 6. Chaque note garde un repère physique sans équivoque (plat / 1er cran au-dessus du plat / le plus redressé) en plus du numéro. On en profite pour condenser les 2 grandes descriptions restantes (Goblet squat, Pallof press). Aucun set_log touché (seul `notes` change).

```sql
-- LUNDI — Chest-supported row haltère
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  UPDATE exercises
     SET notes = 'Banc cran 2 (~25-30°, 1er cran au-dessus du plat), face contre le dossier.

Tirer le COUDE vers la HANCHE, omoplate AVANT le bras. Descente lente 3s, étirement complet en bas.

Si tu sens le biceps → allège + "omoplate d''abord". Cible : grand dorsal + milieu du dos.'
   WHERE program_day_id = d_lundi
     AND name = 'Chest-supported row haltère';
END $$;

-- MERCREDI — Goblet squat (note condensée)
DO $$
DECLARE
  d_mercredi UUID;
BEGIN
  SELECT pd.id INTO d_mercredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 3;

  UPDATE exercises
     SET notes = 'Haltère vertical contre la poitrine, torse droit, genoux dans l''axe des pieds. Descente jusqu''à parallèle (cuisses //sol), plus bas uniquement si pas de butt wink. Charge axiale = densité osseuse.'
   WHERE program_day_id = d_mercredi
     AND name = 'Goblet squat';
END $$;

-- VENDREDI — Développé incliné, Extensions overhead, Barre au front, Pallof
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  UPDATE exercises
     SET notes = 'Banc cran 2 (~25-30°, 1er cran au-dessus du plat). Prise neutre (paumes face à face) = épaule safe. Coudes ~45° du corps, descente contrôlée, pas de verrouillage brutal en haut.'
   WHERE program_day_id = d_vendredi
     AND name = 'Développé haltères neutre (incliné 30°)';

  UPDATE exercises
     SET notes = 'Banc VERTICAL, cran 6 (~90°, le plus redressé). Barre derrière la nuque, coudes pointés au plafond et FIXES (ne pas les écarter). Cible : longue portion étirée.'
   WHERE program_day_id = d_vendredi
     AND name = 'Extensions overhead barre EZ';

  UPDATE exercises
     SET notes = 'Banc PLAT, cran 1 (0°). Bras légèrement inclinés vers la tête, coudes FIXES pointés au plafond. Descendre vers le front, stop ~5cm avant.

Coudes sensibles : charge modérée, jamais forcer si douleur tendineuse.'
   WHERE program_day_id = d_vendredi
     AND name = 'Barre au front';

  UPDATE exercises
     SET notes = 'Élastique ancré sur le côté à hauteur poitrine. Debout de profil, pousser droit devant et RÉSISTER à la rotation, retour lent. Anti-rotation → stabilité lombaire.'
   WHERE program_day_id = d_vendredi
     AND name = 'Pallof press élastique';
END $$;
```

---

## 41. Migration 039 — Épaule G : drop développé incliné + recentrage prehab chef long du biceps

> Douleur antérieure épaule G récurrente sur la 1ère série du **développé haltères incliné**, localisée au tendon du **chef long du biceps** (coulisse bicipitale) ; pas de douleur sur les curls → spécifique à la position basse (coude derrière le corps). Le pec n'est pas une cible de croissance (santé/densité osseuse only) et les triceps sont déjà couverts en direct → on **drop le développé sans le remplacer** (allège aussi le vendredi déjà dense). Côté **prehab** (lundi + vendredi), recentrage chef long à coût net ~nul : on remplace le **Stretch doorway** (étire l'avant de l'épaule = peut agacer le chef long irritable) par une **Rotation interne élastique** 2×15 (subscapulaire, stabilise le tendon dans sa coulisse), et on ajoute une **Isométrie biceps 3×30s TEMPORAIRE** (protocole tendon Keith Baar : charge sans douleur, antalgique + capacité ; à retirer une fois l'épaule calme). Rotations externes + Face pulls gardés. Prehab à faire en **circuit warm-up** (enchaîné, sans repos).
>
> **⚠️ Note** : supprime des exos avec `set_logs` historiques (développé, doorway) → suppression des logs avant l'exo (FK constraint), détruit l'historique. Même pattern que 010, 011, 030, 031, 032.

```sql
-- VENDREDI — drop développé haltères incliné (sans remplacement)
DO $$
DECLARE
  d_vendredi UUID;
BEGIN
  SELECT pd.id INTO d_vendredi
    FROM program_days pd JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 5;

  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id = d_vendredi
        AND name = 'Développé haltères neutre (incliné 30°)'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_vendredi
     AND name = 'Développé haltères neutre (incliné 30°)';
END $$;

-- LUNDI + VENDREDI — prehab : doorway → rotation interne + isométrie biceps
DO $$
DECLARE
  d_lundi    UUID;
  d_vendredi UUID;
  day_ids    UUID[];
  d_id       UUID;
BEGIN
  SELECT pd.id INTO d_lundi    FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 1;
  SELECT pd.id INTO d_vendredi FROM program_days pd JOIN programs p ON p.id = pd.program_id WHERE p.is_active = true AND pd.day_of_week = 5;
  day_ids := ARRAY[d_lundi, d_vendredi];

  -- DROP "Stretch doorway" (set_logs d'abord — FK)
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises WHERE program_day_id = ANY(day_ids) AND name = 'Stretch doorway'
   );
  DELETE FROM exercises
   WHERE program_day_id = ANY(day_ids) AND name = 'Stretch doorway';

  -- ADD rotation interne + isométrie biceps sur les 2 jours (idempotent)
  FOREACH d_id IN ARRAY day_ids LOOP
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_id AND name = 'Rotation interne élastique') THEN
      INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
      VALUES (d_id, 'Rotation interne élastique', 4, 2, '15', true,
        'Élastique ancré sur le côté à hauteur du coude. Coude COLLÉ au corps, avant-bras qui part de l''extérieur vers le nombril (rotation interne), lent et contrôlé. Cible : subscapulaire = stabilise le chef long du biceps dans sa coulisse. Complément de la rotation externe (équilibre la coiffe).',
        'rehab');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_id AND name = 'Isométrie biceps (temporaire)') THEN
      INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section)
      VALUES (d_id, 'Isométrie biceps (temporaire)', 5, 3, '30s', true,
        'PROTOCOLE TENDON (chef long du biceps). Position = MILIEU D''UN CURL tenu STATIQUE : coude collé au corps à ~90° (avant-bras // sol), paume vers le haut (supinée). Tu ne montes ni ne descends, tu RÉSISTES immobile ~30s. CHARGE = ton poids de curl pour un set dur de 8-12 reps : ça doit devenir vraiment dur sur les 10 dernières s (RPE 7-8) mais tenable sans douleur > 3/10. Trop facile à 30s = trop léger ; progresse au fil des semaines tant que c''est indolore. Supination tire sur l''épaule ? → prise neutre (hammer). TEMPORAIRE, à retirer une fois l''épaule calme. Pas tous les jours.',
        'rehab');
    END IF;
  END LOOP;
END $$;
```

---

## 42. Migration 040 — Lundi : Chest-supported row → Inverted row

> Le user ne peut faire correctement **aucune** des variantes de tirage testées (1m97/136kg) : rowing barre = amplitude bloquée par le ventre ; chest-supported row = position face au banc qui écrase l'entrejambe ; rowing haltère unilatéral = pas senti. Or c'est le **seul tirage horizontal de la semaine** (lundi = unique jour pull) → on ne supprime pas sans remplacer : le dos n'est pas une cible hypertrophie mais le tirage couvre 3 priorités réelles (posture/anti-blessure, santé épaule G via rétraction scapulaire, biceps indirect). Remplacement par **Inverted row** (poids de corps, barre droite sur les barres de sécurité) : corps suspendu sous la barre, seules les chaussures touchent le sol → plus de contact ventre/banc/entrejambe et pas d'appui au sol du garage (cf. floor press refusé). Gainage rigide = anti-extension (bon pour les lombaires). Charge réglée par l'angle (barre haute = facile, adapté à 136kg) et s'allège avec la perte de gras. **Prise supination** = biceps indirect maximisé, épaule en flexion (n'agace pas le chef long du biceps). Garde order_index 5, 4×8-12, muscle_group 'back' ; bodyweight + bilatéral (≠ unilatéral avant).
>
> **⚠️ Note** : supprime un exo avec `set_logs` historiques (chest-supported row) → suppression des logs avant l'exo (FK constraint), détruit l'historique. Même pattern que 010, 011, 030, 031, 032, 039.

```sql
DO $$
DECLARE
  d_lundi UUID;
BEGIN
  SELECT pd.id INTO d_lundi
    FROM program_days pd
    JOIN programs p ON p.id = pd.program_id
   WHERE p.is_active = true AND pd.day_of_week = 1;

  -- Drop set_logs du chest-supported row (FK) puis l'exo
  DELETE FROM set_logs
   WHERE exercise_id IN (
     SELECT id FROM exercises
      WHERE program_day_id = d_lundi
        AND name = 'Chest-supported row haltère'
   );

  DELETE FROM exercises
   WHERE program_day_id = d_lundi
     AND name = 'Chest-supported row haltère';

  -- Insert de l'inverted row (idempotent)
  IF NOT EXISTS (SELECT 1 FROM exercises WHERE program_day_id = d_lundi AND name = 'Inverted row (barres de sécurité)') THEN
    INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section, muscle_group, is_per_side)
    VALUES (
      d_lundi,
      'Inverted row (barres de sécurité)',
      5, 4, '8-12', true,
      'Cible : milieu du dos + grand dorsal. Biceps indirect.

SETUP : barre droite posée sur les barres de sécurité, hauteur hanche / bas de poitrine. Te glisser dessous, prise SUPINATION (paumes vers toi, largeur épaules), corps gainé droit de la tête aux talons, talons au sol. Tu es suspendu : seules tes chaussures touchent le sol.

EXÉCUTION : tirer le STERNUM vers la barre en serrant les omoplates (omoplate d''abord). Pause brève en haut, descente contrôlée jusqu''aux bras tendus. Corps rigide tout du long = gainage anti-extension (comme un plank, bon pour les lombaires).

CHARGE : plus la barre est HAUTE = plus facile (torse redressé). Commence haut. Régression : genoux pliés, pieds à plat. Progression : baisse la barre d''un cran quand 8-12 deviennent faciles — et ça s''allège tout seul à mesure que tu perds du gras.',
      'main', 'back', false
    );
  END IF;
END $$;
```
