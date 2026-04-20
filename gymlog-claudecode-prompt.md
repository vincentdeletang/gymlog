# GymLog — Prompt Claude Code

## Contexte

Je suis développeur Laravel/Vue.js senior. Je veux construire une **Progressive Web App (PWA) de suivi d'entraînement perso**, déployée sur GitHub Pages, avec persistance des données sur Supabase.

L'app est utilisée principalement sur **mobile pendant l'entraînement** — l'UX doit être ultra simple, rapide, zéro friction. PC = consultation stats uniquement.

---

## Stack technique

- **Frontend** : Vue 3 + Vite + Vue Router (pas de Nuxt, pas de SSR)
- **CSS** : Tailwind CSS
- **BDD** : Supabase (PostgreSQL) via `@supabase/supabase-js`
- **Auth** : Supabase Magic Link (email uniquement — pas de mot de passe, lien reçu par email, session persistée en localStorage)
- **Déploiement** : GitHub Pages (static build) + PWA via `vite-plugin-pwa`
- **Graphiques** : Chart.js ou Recharts (au choix, le plus adapté au mobile)
- **Offline** : Service Worker pour fonctionnement hors-ligne avec sync au retour de connexion

---

## Architecture de la BDD (Supabase)

### Table `programs`
```sql
id uuid primary key
name text -- ex: "Programme V1 - Avril 2026"
description text
is_active boolean default true
created_at timestamptz
```

### Table `program_days`
```sql
id uuid primary key
program_id uuid references programs(id)
day_of_week int -- 0=Dimanche, 1=Lundi ... 6=Samedi
name text -- ex: "Upper Pull + Biceps"
type text -- 'strength' | 'cardio' | 'rest'
xp_reward int -- XP gagné si séance complétée
notes text -- instructions générales du jour
```

### Table `exercises`
```sql
id uuid primary key
program_day_id uuid references program_days(id)
name text
order_index int
sets_target int
reps_target text -- ex: "10-12", "30s", "10/jambe"
is_bodyweight boolean default false -- si true : pas de champ poids
notes text
section text -- 'main' | 'rehab' | 'cardio'
```

### Table `cardio_blocks`
```sql
id uuid primary key
program_day_id uuid references program_days(id)
name text -- ex: "Corde à sauter"
duration_minutes int
order_index int
notes text
```

### Table `workout_sessions`
```sql
id uuid primary key
user_id uuid references auth.users(id) -- Supabase auth user
program_day_id uuid references program_days(id)
session_date date
completed boolean default false
completed_at timestamptz
cardio_duration_seconds int -- timer cardio loggé
notes text
created_at timestamptz
```

### Table `set_logs`
```sql
id uuid primary key
session_id uuid references workout_sessions(id)
exercise_id uuid references exercises(id)
set_number int
weight_kg decimal -- null si bodyweight
reps_done int
rir int -- 0 à 5
logged_at timestamptz
```

### Table `user_state`
```sql
id uuid primary key
user_id uuid unique references auth.users(id)
xp_total int default 0
streak_current int default 0
streak_best int default 0
last_session_date date
level int default 1
created_at timestamptz
```

**Sécurité Supabase** : activer RLS sur toutes les tables. Policy : `user_id = auth.uid()` — chaque utilisateur ne voit et ne modifie que ses propres données.

---

## Programme initial à seed en BDD

Le programme couvre 7 jours (Lundi=1 → Dimanche=0) :

**Lundi — Upper Pull + Biceps** (type: strength, xp: 200)
- Section REHAB (avant séance, is_bodyweight: true) :
  - Rotations externes élastique — 3×15 — "Coude collé, rotation lente vers l'extérieur"
  - Face pulls élastique — 3×15 — "Tirer vers le visage en ouvrant les bras"
  - Pendulaires de Codman — 2×30s — "Bras relâché, petits cercles, décompression passive"
  - Stretch doorway — 2×30s — "Jamais forcer"
- Section MAIN :
  - Rowing haltère unilatéral — 4×10-12 — "Dos neutre, amplitude complète"
  - Curl barre EZ (supination) — 4×10-12 — "Coudes fixes, pas de balancement"
  - Curl haltères hammer — 3×10-12 — "Prise neutre, mouvement lent, squeeze en haut"
  - Curl haltère concentré — 3×12-15 — "Finisher biceps, contraction max"
  - Plank — 3×30-60s — is_bodyweight: true
- Cardio fin : Corde à sauter, 20 min, "Séries 2-3 min / 30s récup"

**Mardi — Cardio Boxe** (type: cardio, xp: 150)
- Cardio blocks :
  - Music Boxing — 15 min — "Échauffement, montée progressive"
  - Sac de boxe — 25 min — "Rounds 3 min / 1 min récup"

**Mercredi — Lower Body** (type: strength, xp: 200)
- Section MAIN :
  - Fentes marchées haltères — 4×10/jambe
  - Split squat bulgare — 3×10/jambe
  - Hip thrust (barre sur banc) — 3×12-15 — "Squeeze fessiers 2s en haut"
  - Mollets debout (barre) — 4×15-20 — "Monter sur disque pour amplitude"
  - Reverse crunches — 3×15-20 — is_bodyweight: true
- Cardio fin : Tapis 3%, 30 min, "FC cible 110-130 bpm"

**Jeudi — Cardio Vélo** (type: cardio, xp: 120)
- Cardio blocks :
  - Zone 2 (FC 120-140) — 50 min — "Rythme conversation, assistance électrique dans les côtes"
  - Zone 4 (FC 160-175) — 10 min — "Sprint plat ou côte"

**Vendredi — Upper Push + Triceps** (type: strength, xp: 200)
- Section REHAB (avant séance, is_bodyweight: true) :
  - Mêmes 4 exercices que lundi
- Section MAIN :
  - Développé haltères neutre (incliné 30°) — 4×10-12 — "Prise neutre = safe épaule"
  - Élévations latérales haltères — 3×12-15 — "Jamais au-dessus de l'horizontale"
  - Extensions triceps barre EZ — 4×10-12 — "Coudes fixes pointés plafond"
  - Kickbacks haltères — 4×12-15 — "Finisher triceps, serrer en extension"
  - Crunchs — 3×15-20 — is_bodyweight: true
- Cardio fin : Corde à sauter ou Tapis, 25 min

**Samedi — Récupération active** (type: rest, xp: 50)
- Cardio block : Marche / mobilité — 30 min — "Optionnel, écoute ton corps"

**Dimanche — Repos complet** (type: rest, xp: 0)

---

## Features à développer

### 1. Vue "Aujourd'hui" (écran principal, mobile-first)
- Affiche automatiquement le programme du jour selon le jour de la semaine
- Si jour de strength : liste les exercices par section (REHAB → MAIN → CARDIO)
- Pour chaque exercice : boutons S1, S2, S3... par série
- Tap sur une série non loggée → bottom sheet modal avec :
  - Champ poids (kg) — **masqué si `is_bodyweight: true`**
  - Champ reps réalisés
  - Sélecteur RIR (0 à 4+) avec code couleur : 0=rouge (à bloc), 1=orange, 2=vert (optimal ✓), 3=vert (safe), 4+=gris (léger)
  - Affiche le poids/reps de la dernière fois pour cet exercice+série (aide mémoire)
  - Bouton Valider → son de feedback + animation sur le bouton de série
- Tap sur une série déjà loggée → même modal pré-rempli (correction possible)
- Si jour de cardio : timer par bloc (Start/Pause/Reset), bouton "Bloc terminé ✓"
- Bouton "TERMINER LA SÉANCE" en bas : déclenche célébration (confetti + animation) + attribution XP + mise à jour streak

### 2. Gamification
- **XP** : gagné à chaque séance complétée (montant défini par `xp_reward` dans `program_days`)
- **Niveaux** : Recrue (0) → Rookie (500) → Guerrier (1200) → Champion (2500) → Élite (4500) → Légende (8000) XP
- **Streak** : jours consécutifs d'entraînement (tolérance 1 jour de repos)
- **Célébration** : overlay plein écran avec confetti, message aléatoire motivant, XP gagné affiché
- Barre de progression niveau visible en haut de l'écran principal

### 3. Vue "Historique"
- Liste des séances par semaine (Cette semaine / Semaine dernière / Il y a N semaines)
- Tap sur une séance → détail de tous les sets loggés
- Indicateur visuel : vert = complétée, gris = abandonnée

### 4. Vue "Progression" (Stats)
- **Calendrier hebdomadaire** : 7 cases, couleur selon type/statut du jour
- **Graphiques Chart.js** :
  - Évolution du poids utilisé par exercice (courbe sur 8 semaines)
  - Volume total hebdomadaire (barres)
  - Répartition des séances par type (muscu/cardio/repos) en donut
- **Stats globales** : total séances, total séries, meilleur streak, XP total
- **Suivi RIR moyen** par exercice sur les 4 dernières séances (signal d'alerte si RIR moyen < 1 = risque surentraînement/blessure)

### 5. Vue "Programme"
- Affiche le programme actif complet (tous les jours)
- Bouton "Créer un nouveau programme" → formulaire pour définir les jours/exercices
- Possibilité de désactiver l'actuel et en activer un nouveau (l'historique reste lié à l'ancien)

### 6. PWA & Offline
- `vite-plugin-pwa` avec manifest : icône, couleur, `display: standalone`
- Service Worker : cache les assets + les données Supabase en IndexedDB pour consultation offline
- Sync automatique des sets loggés offline quand la connexion revient
- Banner "installer l'app" sur mobile

### 7. Export
- Bouton dans les réglages : export de tout l'historique en JSON
- Format compatible pour réimport (backup de sécurité)

---

## UX / Design

**Thème** : dark, inspiré jeux vidéo / dashboard fitness premium
- Background : `#0a0e17`
- Surface cards : `#111827`
- Accent bleu : `#3b82f6`
- Accent vert (succès/complet) : `#10b981`
- Accent orange (cardio/timer) : `#f59e0b`
- Font display : Barlow Condensed (Google Fonts) — titres, labels, chiffres
- Font body : Barlow — texte courant

**Mobile-first impératif** :
- Bottom navigation bar (4 onglets : Aujourd'hui / Historique / Progression / Réglages)
- Bottom sheet modals (jamais de popups centrés)
- Boutons min 44px de hauteur
- Pas de hover-only interactions
- Tap feedback immédiat sur chaque action

---

## Structure du projet

```
gymlog/
├── public/
│   ├── icons/ (PWA icons)
│   └── manifest.json
├── src/
│   ├── components/
│   │   ├── today/
│   │   │   ├── ExerciseRow.vue
│   │   │   ├── SetButton.vue
│   │   │   ├── SetLogModal.vue
│   │   │   ├── CardioBlock.vue
│   │   │   └── CelebrationOverlay.vue
│   │   ├── stats/
│   │   │   ├── WeekCalendar.vue
│   │   │   ├── ProgressChart.vue
│   │   │   └── StatCard.vue
│   │   └── shared/
│   │       ├── LevelBar.vue
│   │       └── BottomNav.vue
│   ├── views/
│   │   ├── TodayView.vue
│   │   ├── HistoryView.vue
│   │   ├── StatsView.vue
│   │   ├── ProgramView.vue
│   │   └── SettingsView.vue
│   ├── stores/
│   │   ├── useWorkoutStore.js   -- séances, sets, sync Supabase
│   │   ├── useUserStore.js      -- XP, streak, niveau, session magic link
│   │   └── useProgramStore.js   -- programme actif, exercices
│   ├── lib/
│   │   ├── supabase.js          -- client Supabase initialisé
│   │   └── offlineQueue.js      -- queue IndexedDB pour sync offline
│   ├── composables/
│   │   ├── useTimer.js
│   │   ├── useAudio.js          -- son de feedback série
│   │   └── useConfetti.js
│   ├── router/index.js
│   ├── App.vue
│   └── main.js
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql
│   └── seed/
│       └── seed_program.sql     -- seed du programme V1
├── .env.example
├── vite.config.js
└── README.md (instructions deploy GitHub Pages + setup Supabase)
```

---

## Variables d'environnement

```env
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

---

## Points d'attention pour Claude Code

1. **Commencer par** : schema SQL + seed du programme, puis le store Supabase, puis les composants dans cet ordre
2. **Auth Magic Link** : au premier lancement, afficher un écran simple "Entre ton email pour accéder à tes données". L'utilisateur reçoit un lien, clique dessus, et la session est persistée en localStorage — il ne se reconnecte plus sauf si la session expire (configurable Supabase, mettre à 1 an). Sur PC, même flow = mêmes données que le téléphone. `supabase.auth.onAuthStateChange()` pour réagir à la connexion. Toutes les requêtes Supabase filtrées par `auth.uid()` via RLS.
3. **Offline-first** : les sets loggés pendant l'entraînement doivent s'écrire en IndexedDB immédiatement, puis sync Supabase en arrière-plan. Jamais bloquer l'UI sur une requête réseau
4. **La section REHAB** (exercices élastiques / poids de corps) ne doit jamais afficher de champ poids — `is_bodyweight: true` dans le seed
5. **RIR 2 par défaut** présélectionné dans le modal — c'est la recommandation science (Refalo 2024)
6. **GitHub Pages** : configurer `vite.config.js` avec `base: '/gymlog/'` (ou le nom du repo) et le workflow GitHub Actions pour auto-deploy sur push main
7. **README** doit documenter : setup Supabase (créer projet, run migrations, récupérer keys), setup GitHub Pages, et comment changer de programme

---

## Contexte scientifique intégré dans l'app (pour les tooltips / messages)

- RIR 2-3 = optimal hypertrophie + protection articulaire (Refalo et al. 2024, Schoenfeld 2018)
- Volume optimal résistance : ~60 min/semaine (méta-analyse PMC 2023)
- Si RIR moyen < 1 sur 3 séances consécutives → warning UI "Pense à une semaine de décharge"
- Si streak > 6 jours sans repos → warning "Un jour de repos améliore les adaptations musculaires"
