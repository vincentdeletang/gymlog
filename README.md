# GymLog

PWA de suivi d'entraînement personnel — Vue 3 + Vite + Supabase + GitHub Pages.

## Setup Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Dans **SQL Editor**, exécuter dans l'ordre :
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/seed/seed_program.sql`
3. Récupérer dans **Project Settings → API** :
   - `Project URL` → `VITE_SUPABASE_URL`
   - `anon public key` → `VITE_SUPABASE_ANON_KEY`
4. Aller dans **Authentication → Settings** :
   - Activer "Magic Links" (actif par défaut)
   - Mettre la durée de session à **1 an** (365 days) dans "JWT Expiry"
   - Ajouter l'URL de redirect : `https://<username>.github.io/gymlog/`

## Setup local

```bash
cp .env.example .env
# Remplir VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY

npm install
npm run dev
```

## Deploy GitHub Pages

1. Sur GitHub, aller dans **Settings → Pages → Source** : choisir **GitHub Actions**
2. Dans **Settings → Secrets → Actions**, ajouter :
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
3. Push sur `main` → déploiement automatique via `.github/workflows/deploy.yml`
4. L'app sera disponible sur `https://<username>.github.io/gymlog/`

> Si ton repo s'appelle autrement que `gymlog`, modifier `base` dans `vite.config.js`.

## Changer de programme

1. Mettre `is_active = false` sur le programme actuel dans Supabase (table `programs`)
2. Insérer un nouveau programme et ses jours/exercices
3. L'app charge automatiquement le programme avec `is_active = true`
4. L'historique reste lié à l'ancien programme (via `program_day_id`)

## Icônes PWA

Remplacer les placeholders dans `public/icons/` par de vraies images PNG :
- `icon-192.png` — 192×192px
- `icon-512.png` — 512×512px

Outil recommandé : [Maskable.app](https://maskable.app/)

## Structure du projet

```
src/
├── components/
│   ├── today/      — ExerciseRow, SetButton, SetLogModal, CardioBlock, CelebrationOverlay
│   ├── stats/      — WeekCalendar, ProgressChart, StatCard
│   └── shared/     — BottomNav, LevelBar
├── views/          — TodayView, HistoryView, StatsView, ProgramView, SettingsView, AuthView
├── stores/         — useUserStore, useProgramStore, useWorkoutStore (Pinia)
├── composables/    — useTimer, useAudio, useConfetti
├── lib/            — supabase.js, offlineQueue.js (IndexedDB)
└── router/         — Vue Router hash mode
supabase/
├── migrations/     — 001_initial_schema.sql
└── seed/           — seed_program.sql
```

## Fonctionnalités

- **Auth Magic Link** — connexion sans mot de passe, session 1 an
- **Vue Aujourd'hui** — programme du jour, sections REHAB/MAIN/CARDIO, log série par série
- **Bottom sheet modal** — poids, reps, RIR (0–4+) avec code couleur, hint "dernière fois"
- **Gamification** — XP, niveaux (Recrue → Légende), streak, célébration confetti
- **Historique** — liste par semaine, détail par séance
- **Progression** — calendrier semaine, graphiques Chart.js, stats globales
- **Offline-first** — IndexedDB queue, sync auto au retour de connexion
- **PWA** — installable, service worker, manifest
