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

## 3. Migration 003 — Table `bars` + `bar_id` sur `exercises`

> **C'est ça que tu dois lancer maintenant** si la BDD est déjà initialisée.

```sql
CREATE TABLE IF NOT EXISTS bars (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT NOT NULL,
  weight_kg DECIMAL(5,2) NOT NULL
);

-- Nettoie la migration 002 si elle a été appliquée par erreur
ALTER TABLE exercises DROP COLUMN IF EXISTS bar_weight_kg;

ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS bar_id UUID REFERENCES bars(id) ON DELETE SET NULL;

-- RLS pour bars (lecture publique comme les autres tables de programme)
ALTER TABLE bars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read bars"
  ON bars FOR SELECT TO authenticated USING (true);
```

---

## 4. Seed — Barres & auto-assignation

> À lancer juste après la migration 003.

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

## 5. Migration 004 — Nouveau programme Mercredi

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

## 6. Migration 005 — Suspension barre fixe (fin de séance muscu)

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

## 7. Migration 006 — Section cooldown

> Ajoute `'cooldown'` comme type de section valide et bascule les suspensions de `rehab` → `cooldown`.

```sql
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_section_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_section_check
  CHECK (section IN ('main', 'rehab', 'cardio', 'cooldown'));

UPDATE exercises SET section = 'cooldown' WHERE name = 'Suspension barre fixe';
```

---

## 8. Migration 007 — Mise à jour programmes + section mobility

### 8a. Contrainte mobility (à lancer en premier, séparément)

```sql
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_section_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_section_check
  CHECK (section IN ('main', 'rehab', 'cardio', 'cooldown', 'mobility'));
```

### 8b. Mise à jour des programmes (007_fix — utiliser celle-ci, pas 007)

> Utilise des UPDATE au lieu de DELETE pour préserver l'historique des set_logs.

```sql
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
  INSERT INTO exercises (program_day_id, name, order_index, sets_target, reps_target, is_bodyweight, notes, section) VALUES
    (d_samedi, 'Open book',                  1, 2, '10/côté',        true, 'Allongé sur le côté, genoux à 90°, ouvrir le bras du dessus vers l''arrière en suivant du regard — clé épaule', 'mobility'),
    (d_samedi, '90/90 hip switch',            2, 1, '10 transitions',  true, 'Assis au sol, jambes à 90° des deux côtés, basculer lentement. Mains au sol si raide.',                        'mobility'),
    (d_samedi, 'Pigeon modifié (sur le dos)', 3, 2, '60s/côté',       true, 'Allongé sur le dos, cheville sur le genou opposé, tirer la cuisse vers la poitrine.',                          'mobility'),
    (d_samedi, 'Respiration diaphragmatique', 4, 1, '10 cycles',      true, 'Allongé sur le ventre, front sur les mains — expirer ventre, pas poitrine. Active la récupération.',           'mobility');
END $$;
```

---

## 9. Migration 008 — Dead bug mercredi + suppression Reverse crunches

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

## 10. Migration 009 — Plank début de bloc lundi + Kickbacks 4→3 séries vendredi

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

## 11. Migration 010 — Goblet squat mercredi + fentes 4→3 + suppression mollets

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

## 12. Migration 011 — Curl barre EZ avant Rowing haltère (lundi) + suppression Dead bug (vendredi)

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

## 13. Migration 012 — Plank lundi→vendredi + suppression Élévations latérales

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

## 14. Migration 013 — Suppression Music Boxing (Mardi)

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
