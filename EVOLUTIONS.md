# Évolutions — idées en attente

Idées validées, pas prioritaires aujourd'hui. Triées par **effort** croissant.

---

## 0. Audit UI/UX « app pro de 2026 » — reste à faire (audit du 22/10/2026)

### Fait le 22/10 (commits non poussés le soir même)
Captures des vrais écrans (390 et 412 px, DPR 3) + Lighthouse mobile (perf 73, accessibilité 95, bonnes pratiques 100, CLS 0,43). Corrigé : connexion par mot de passe, nom d'exo sur 2 lignes avec la consigne de réserve dessous (`splitTarget`), boutons de série pleine largeur, chrono de repos (temps 40 px, boutons 46 px, sons sur l'horloge audio — l'ancien chantier 0 bis), flash « Jour de repos » au chargement, cardio en un tap à la durée cible, badge sync seulement quand ça coince (+ état « Hors ligne »), notes lisibles, en-tête stable + fonts non bloquantes + theme_color sombre, Settings allégé, restes du template Vite supprimés.

### Fait le 28/10
Écran allumé pendant toute la séance (`useWakeLock`) ; exos enchaînés (`superset_group`, série suivante ouverte seule à la fin du repos, `lib/sessionFlow.js`) ; liste « à préparer » (`setup` + charges du jour) ; zone 2 chronométrée qui logue et clôt la séance. **Pas testés sur téléphone au moment du push.**
Nav en pictos SVG inline (fini les emojis), axe « Séances / semaine » gradué en entiers depuis 0.

### Reste
- **Programme en cache hors ligne** : sans réseau au chargement, `fetchActiveProgram` échoue silencieusement et la séance n'existe pas (les taps ne loguent rien, le badge dit juste « Hors ligne »). Mettre le dernier programme + jour en localStorage et démarrer dessus ; la file `offlineQueue` prend le relais pour les sets. **M.**

### Scope
- Pas de refonte : des coupes et des corrections, l'app doit rester reconnaissable.
- Hors scope assumé : mode clair (couleurs en dur, l'app sert dans un garage le matin).

---

## 1. Comparaison inline « Today vs last X » sur les exos

### Quoi
Sur `TodayView`, sous chaque exo en cours, afficher un delta vs la même séance du programme la fois précédente.

```
Curl barre EZ — 4×10-12      ↑ +2kg vs lundi dernier
                             = 12 reps
```

### Pourquoi
La modal de set montre déjà un hint « Dernière fois » (`previousLog`), mais il faut cliquer pour le voir. Le delta inline donne du contexte avant même de toucher l'écran — utile pour décider mentalement « j'augmente / je maintiens » avant d'attaquer la 1ère série.

### Scope
- **Backend** : aucun changement. `loadPreviousData` charge déjà la séance précédente complète (`previousSets[exerciseId]`).
- **Frontend** : 
  - Calcul du delta pour `set 1` de chaque exo (poids + reps)
  - Display dans `ExerciseRow.vue` (déjà a `suggestion` calculé via `progression.js`)
  - Choix : remplacer la pastille `suggestion` actuelle, ou la compléter ?

### Décisions à prendre
- Quel set comparer ? Set 1 vs set 1 (cohérent), ou meilleur set vs meilleur set ?
- Que faire pour les exos avec range `8-10` reps ? Comparer le mid ?
- Sur tap-to-log (rehab/cooldown), pas pertinent — skip.

### Effort
**S — 1 session.** ~80 lignes Vue + tweaks `useWorkoutStore`.

---

## 2. Notifications push (rappels jour de séance)

### Quoi
Push notification le jour J pour rappeler la séance prévue.

```
🔔 Mardi 18h — Cardio Boxe (25 min)
```

Configurable :
- Heure du rappel (par défaut 18h)
- Activé/désactivé par jour de la semaine
- Désactivable globalement depuis Settings

### Pourquoi
Skip réduit. À ~3-4 séances/semaine sur le long terme, un rappel intelligent te rattrape les jours où la motivation flanche. C'est *le* signal qui distingue les apps qui retiennent vs celles qu'on oublie.

### Scope
**Côté client** :
- Demander permission `Notification.requestPermission()` depuis Settings
- Souscrire au push manager : `serviceWorker.pushManager.subscribe({ applicationServerKey: VAPID_PUBLIC })`
- Persister le `subscription` (endpoint, keys) en BDD

**Côté backend** :
- Migration : table `push_subscriptions (user_id, endpoint, p256dh, auth, schedule_settings jsonb)`
- Edge function Supabase (Deno) qui :
  - Tourne via `pg_cron` toutes les heures
  - Lit les subscriptions actives + heure courante vs schedule
  - Envoie via Web Push (VAPID signed)
- Génération paire VAPID (clés à stocker en secret + côté client)

**Service worker** :
- Listener `push` event → afficher notification
- Listener `notificationclick` → focus la PWA / ouvre `/today`

### Décisions à prendre
- Stocker la clé VAPID privée où ? Supabase secrets vault.
- Sur iOS : push web nécessite iOS 16.4+ et l'app installée en standalone. Caveat à documenter.
- Snooze (« rappelle dans 1h ») : utile mais ajoute complexité. Skip v1.
- Heure unique vs heure par jour : commencer simple (1 horaire global), itérer.

### Effort
**L — 1 à 1,5 jour.** Web Push est bien documenté mais c'est plusieurs morceaux d'infra à brancher.

### Pré-requis
- Configurer VAPID dans Supabase
- Tester le push sur iOS (où c'est le plus capricieux)

---

## 3. Éditeur de programme dans l'app

### Quoi
UI pour gérer son programme directement depuis l'app : ajouter/retirer/réordonner exos, créer/supprimer jours, modifier sets/reps/notes/section/muscle_group/bar_id.

### Pourquoi
**Le plus gros débloqueur**. Aujourd'hui, modifier le programme = écrire une migration SQL et la passer dans Supabase. C'est OK pour un dev mais friction réelle pour itérer. Vu que je modifie mon programme régulièrement (cf. migrations 003, 006, 007, 008, 009, 010, 011, 013), une UI native ferait passer GymLog de « projet perso jetable » à « outil pérenne ».

Bénéfice secondaire : ouvre la voie à de futures features (présets de programmes, A/B comparer 2 programmes sur 6 semaines, suggestions auto basées sur les PRs).

### Scope
Une nouvelle vue `ProgramEditView` (route `/program/edit`).

**MVP** :
- Sélection d'un jour (ou tous)
- Liste des exos du jour, draggable pour réordonner (`@vueuse/core` ou natif HTML5 drag)
- Bouton « + Ajouter exo » → modal avec : name, section, sets_target, reps_target, is_bodyweight, muscle_group, bar_id, notes
- Édition inline ou modal d'édition
- Bouton supprimer (avec confirmation, et garde-fou : « 5 set_logs liés seront aussi supprimés »)

**Extensions possibles** :
- Édition des `program_days` eux-mêmes (nom, type, xp_reward)
- Édition `cardio_blocks`
- Création d'un nouveau programme + bascule du `is_active`
- Templates (« Push », « Pull », « Legs ») prêts à insérer

### Pré-requis BDD
**Aucun nouveau** — le schéma actuel supporte tout. Mais :
- RLS actuel : `exercises` est `select` partagé, `update` ouvert depuis migration 017, **mais pas `insert` ni `delete`**. Faudra une migration RLS pour ouvrir tout aux `authenticated`. Cohérent avec « programme partagé sans `user_id` ». Si on veut un jour multi-utilisateurs, faudra remettre une scope par `user_id`.

### Décisions à prendre
- Édition live (chaque champ envoie une mutation) ou édition par lots (« Enregistrer ») ?
  - Live = pas de bouton enregistrer mais N requêtes
  - Batch = un brouillon local, plus de risque de perte
  - Reco : live avec debounce 500ms, et toast d'erreur si ça échoue
- Suppression d'un exo qui a des `set_logs` historiques : confirmer + cascade, ou soft delete (flag `is_archived`) pour préserver l'historique ?
  - Reco : ne PAS cascader. Bloquer la suppression si des `set_logs` existent, proposer plutôt « archiver » → ajouter `exercises.is_archived bool`. Migration nécessaire.
- Drag & drop tactile : tester sérieusement sur mobile. `vue-draggable-plus` (fork maintenu de Sortable.js) marche bien.

### Effort
**XL — 2-3 sessions de dev.**
- Session 1 : CRUD basique sans drag, mutations Supabase, RLS migration
- Session 2 : drag & drop + édition `program_days`/`cardio_blocks`
- Session 3 : polish (validation, soft delete, tests)

### Risques
- RLS plus permissive = surface d'attaque côté Supabase. Acceptable tant que c'est mono-utilisateur.
- Bug de réordonnancement → corruption de l'ordre. Tester à fond avec replay manuel.
- Régression sur les `set_logs` historiques si on supprime un exo. → **Soft delete obligatoire**.

---

## Rappels programme (décisions prises, à exécuter à date)

_Rien en attente. Le rappel du 23/09 (charge figée du mercredi) est mort : front squat et mollets retirés le 22/10, le SLDL a sa propre règle de sortie (migration 063)._

---

## Notes

- Toutes ces évolutions sont indépendantes : peuvent être attaquées dans n'importe quel ordre.
- L'ordre recommandé reste : **#1 → #3 → #2** (effort croissant + #3 bénéficie d'avoir #1 pour valider que les mutations marchent en read-after-write).
- Si une 4e idée émerge en cours d'usage, l'ajouter ici plutôt que de la laisser dans les commentaires de PR.
