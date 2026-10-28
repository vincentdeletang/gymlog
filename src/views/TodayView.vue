<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ExerciseRow from '@/components/today/ExerciseRow.vue'
import SetLogModal from '@/components/today/SetLogModal.vue'
import CardioBlock from '@/components/today/CardioBlock.vue'
import BoxingTimer from '@/components/today/BoxingTimer.vue'
import CelebrationOverlay from '@/components/today/CelebrationOverlay.vue'
import ExerciseTimer from '@/components/today/ExerciseTimer.vue'
import TimerInputModal from '@/components/today/TimerInputModal.vue'
import RestTimerBar from '@/components/today/RestTimerBar.vue'
import PRFlash from '@/components/today/PRFlash.vue'
import { useProgramStore } from '@/stores/useProgramStore'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { useAudio } from '@/composables/useAudio'
import { parseTimeTarget } from '@/lib/parseTarget'
import { partnerAfter, nextAfterRest, canAutoOpen, prepItems } from '@/lib/sessionFlow'
import { getAvailablePlates } from '@/lib/plateCalc'
import { useWakeLock } from '@/composables/useWakeLock'
import { todayISO, dayOfWeekFromISO, formatLongDate, formatShortDate } from '@/lib/formatDate'

const route = useRoute()
const router = useRouter()
const programStore = useProgramStore()
const workoutStore = useWorkoutStore()
const { playSuccess } = useAudio()

const loading = ref(true)
const celebrating = ref(false)
const sessionStats = ref(null)

// Modal state
const modalOpen = ref(false)
const modalExercise = ref(null)
const modalSetNumber = ref(null)

// Timer countdown overlay state
const timerOpen = ref(false)
const timerExercise = ref(null)
const timerSetNumber = ref(null)
const timerTarget = ref(null) // { min, max, isRange }

// Timer input modal state (catch-up / edit mode for timed exos)
const timerInputOpen = ref(false)
const timerInputExercise = ref(null)
const timerInputSetNumber = ref(null)
const timerInputTarget = ref(null)

// Rest timer between sets — non-blocking bottom bar
const REST_BY_SECTION = { main: 120, rehab: 30, cooldown: 45, mobility: 0, cardio: 0 }
const SECTION_ACCENT = { main: '#3b82f6', rehab: '#f59e0b', cooldown: '#8b5cf6', mobility: '#06b6d4', cardio: '#10b981' }
const restTimer = ref(null) // { duration, total, endAt, exerciseName, setNumber, accent, key }
let restKey = 0

// Persist the rest timer so it survives the background reload (cf. App.vue).
// Only the end timestamp matters: the bar recomputes remaining time from it.
const REST_STORAGE_KEY = 'gymlog.restTimer'
const REST_DONE_GRACE_MS = 120000 // still show "done" if we return shortly after it ended
function persistRest(t) {
  try {
    if (t) localStorage.setItem(REST_STORAGE_KEY, JSON.stringify(t))
    else localStorage.removeItem(REST_STORAGE_KEY)
  } catch {}
}

function startRestTimer(exercise, setNumber, next = null) {
  if (inCatchUpMode.value) return
  const seconds = REST_BY_SECTION[exercise.section] ?? 0
  if (!seconds) return
  restKey++
  restTimer.value = {
    duration: seconds,
    total: seconds,
    endAt: Date.now() + seconds * 1000,
    exerciseName: exercise.name,
    setNumber,
    accent: SECTION_ACCENT[exercise.section] ?? '#3b82f6',
    key: restKey,
    // La série à ouvrir quand le repos finit (persistée : survit au rechargement).
    next: next ? { exerciseId: next.exercise.id, setNumber: next.setNumber } : null,
  }
  persistRest(restTimer.value)
}

// ── Enchaînement (28/10/2026) ───────────────────────────────────────────────────────────
// Après une série fraîche : si l'exo est en paire (superset_group) et que le partenaire n'a
// pas fait ce tour, sa série s'ouvre tout de suite, sans repos. Sinon le repos part, et à sa
// fin la série suivante s'ouvre seule, pré-remplie : il ne reste qu'à valider.
async function afterFreshLog(exercise, setNumber) {
  if (inCatchUpMode.value) return
  const day = programStore.activeExercises
  const partner = partnerAfter(exercise, setNumber, day, workoutStore.isSetLogged)
  if (partner) {
    dismissRestTimer()
    if (canAutoOpen(partner)) {
      await nextTick()
      openSetModal({ exercise: partner, setNumber })
    }
    return
  }
  startRestTimer(exercise, setNumber, nextAfterRest(exercise, setNumber, day, workoutStore.isSetLogged))
}

function onRestDone() {
  const nx = restTimer.value?.next
  if (!nx || modalOpen.value || timerOpen.value || timerInputOpen.value) return
  const ex = programStore.activeExercises.find(e => e.id === nx.exerciseId)
  if (!ex || workoutStore.isSetLogged(ex.id, nx.setNumber) || !canAutoOpen(ex)) return
  dismissRestTimer()
  openSetModal({ exercise: ex, setNumber: nx.setNumber })
}
function dismissRestTimer() { restTimer.value = null; persistRest(null) }
function onRestChange(newEndAt) {
  if (!restTimer.value) return
  restTimer.value.endAt = newEndAt
  persistRest(restTimer.value)
}
function restoreRestTimer() {
  if (inCatchUpMode.value) return
  let saved
  try { saved = JSON.parse(localStorage.getItem(REST_STORAGE_KEY) || 'null') } catch { saved = null }
  if (!saved?.endAt) return
  if (Date.now() > saved.endAt + REST_DONE_GRACE_MS) { persistRest(null); return }
  restKey = Math.max(restKey, saved.key || 0)
  restTimer.value = saved
}

// PR flash state
const prFlash = ref(null) // { exerciseName, prevBest, newE1RM, deltaKg }
function dismissPR() { prFlash.value = null }

const targetDate = computed(() => route.params.date || todayISO())
const inCatchUpMode = computed(() => targetDate.value !== todayISO())

const todayDay = computed(() => {
  const days = ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi']
  return days[dayOfWeekFromISO(targetDate.value)]
})

const dayType = computed(() => programStore.activeProgramDay?.type ?? 'rest')
const isRestDay = computed(() => dayType.value === 'rest')
const isStrength = computed(() => dayType.value === 'strength')
const isCardio = computed(() => dayType.value === 'cardio')

const rehabExercises    = computed(() => programStore.exercisesBySection.rehab)
const mainExercises     = computed(() => programStore.exercisesBySection.main)
const cooldownExercises = computed(() => programStore.exercisesBySection.cooldown)
const mobilityExercises = computed(() => programStore.exercisesBySection.mobility)
const cardioBlocks      = computed(() => programStore.activeCardioBlocks)

const sessionComplete = computed(() => workoutStore.currentSession?.completed ?? false)

const canFinish = computed(() =>
  !sessionComplete.value && !!workoutStore.currentSession
)

const setsProgress = computed(() => {
  const allExercises = [...rehabExercises.value, ...mainExercises.value, ...cooldownExercises.value, ...mobilityExercises.value]
  const total = allExercises.reduce((sum, ex) => sum + ex.sets_target, 0)
  const done  = allExercises.reduce((sum, ex) =>
    sum + Array.from({ length: ex.sets_target }, (_, i) => i + 1)
          .filter(s => workoutStore.isSetLogged(ex.id, s)).length, 0)
  return { done, total }
})

async function loadActiveSession() {
  loading.value = true
  restTimer.value = null
  programStore.setActiveDate(targetDate.value)
  await programStore.fetchActiveProgram()
  if (programStore.activeProgramDay && (!isRestDay.value || programStore.activeExercises.length > 0)) {
    await workoutStore.startOrResumeSession(programStore.activeProgramDay.id, targetDate.value)
  }
  loading.value = false
}

onMounted(async () => {
  await loadActiveSession()
  restoreRestTimer()
})

watch(() => route.params.date, (next, prev) => {
  if (next === prev) return
  loadActiveSession()
})

async function openSetModal({ exercise, setNumber }) {
  const isLogged = workoutStore.isSetLogged(exercise.id, setNumber)
  const isTapToLog = ['rehab', 'cooldown', 'mobility'].includes(exercise.section)
  const timeTarget = parseTimeTarget(exercise.reps_target)

  // Tap-to-log sections without time target: tap toggles log/unlog
  if (isTapToLog && !timeTarget) {
    if (isLogged) {
      await workoutStore.deleteSetLog(exercise.id, setNumber)
    } else {
      await workoutStore.logSet({ exerciseId: exercise.id, setNumber, weightKg: null, repsDone: null, rir: null })
      playSuccess()
      afterFreshLog(exercise, setNumber)
    }
    return
  }

  // Timed exos: countdown timer for fresh logging today, input modal for edit or catch-up
  if (timeTarget) {
    if (isLogged || inCatchUpMode.value) {
      timerInputExercise.value = exercise
      timerInputSetNumber.value = setNumber
      timerInputTarget.value = timeTarget
      timerInputOpen.value = true
    } else {
      timerExercise.value = exercise
      timerSetNumber.value = setNumber
      timerTarget.value = timeTarget
      timerOpen.value = true
    }
    return
  }

  // Main weighted exos: full modal (handles both new and edit via existingLog prop)
  modalExercise.value = exercise
  modalSetNumber.value = setNumber
  modalOpen.value = true
}

async function onTimerStop({ seconds }) {
  const ex = timerExercise.value
  const sn = timerSetNumber.value
  await workoutStore.logSet({
    exerciseId: ex.id,
    setNumber: sn,
    weightKg: null,
    repsDone: seconds,
    rir: null,
  })
  timerOpen.value = false
  afterFreshLog(ex, sn)
}

function onTimerCancel() {
  timerOpen.value = false
}

async function onTimerInputSave({ seconds }) {
  const ex = timerInputExercise.value
  const sn = timerInputSetNumber.value
  const wasLogged = workoutStore.isSetLogged(ex.id, sn)
  await workoutStore.logSet({
    exerciseId: ex.id,
    setNumber: sn,
    weightKg: null,
    repsDone: seconds,
    rir: null,
  })
  playSuccess()
  timerInputOpen.value = false
  if (!wasLogged) startRestTimer(ex, sn)
}

async function onTimerInputDelete() {
  await workoutStore.deleteSetLog(timerInputExercise.value.id, timerInputSetNumber.value)
  timerInputOpen.value = false
}

// Pre-fill from the most recent logged set of same exercise in current session
const modalSessionPrevSet = computed(() => {
  if (!modalExercise.value || !modalSetNumber.value) return null
  // Look for set N-1, or if that's not logged yet, find the last logged set
  const exId = modalExercise.value.id
  for (let s = modalSetNumber.value - 1; s >= 1; s--) {
    const log = workoutStore.getSetLog(exId, s)
    if (log) return log
  }
  return null
})

async function saveSet({ weightKg, repsDone, rir }) {
  const ex = modalExercise.value
  const setNumber = modalSetNumber.value
  const wasLogged = workoutStore.isSetLogged(ex.id, setNumber)
  await workoutStore.logSet({
    exerciseId: ex.id,
    setNumber: modalSetNumber.value,
    weightKg,
    repsDone,
    rir,
  })
  playSuccess()
  modalOpen.value = false
  if (!wasLogged) {
    if (!inCatchUpMode.value && !ex.is_bodyweight) {
      const pr = workoutStore.checkAndRecordPR(ex.id, weightKg, repsDone)
      if (pr) prFlash.value = { exerciseName: ex.name, ...pr }
    }
    afterFreshLog(ex, setNumber)
  }
}

async function deleteSet() {
  await workoutStore.deleteSetLog(modalExercise.value.id, modalSetNumber.value)
  modalOpen.value = false
}

async function finishSession() {
  const exercisesById = Object.fromEntries(
    programStore.activeExercises.map(e => [e.id, e])
  )
  const stats = workoutStore.computeSessionStats(exercisesById)
  const ok = await workoutStore.completeSession()
  if (ok) {
    sessionStats.value = stats
    celebrating.value = true
  }
}

// La zone 2 chronométrée qui va au bout clôt la séance.
function onZone2Done() {
  if (canFinish.value && !inCatchUpMode.value) finishSession()
}

// Écran allumé du chargement de la séance jusqu'à sa clôture.
useWakeLock(computed(() =>
  !loading.value && !!workoutStore.currentSession && !sessionComplete.value && !inCatchUpMode.value && !isRestDay.value
))

// Ce qu'il faut installer avant de commencer, charges du jour comprises.
const prepList = computed(() => {
  if (loading.value || sessionComplete.value || inCatchUpMode.value || isRestDay.value) return []
  return prepItems(programStore.activeExercises, workoutStore.getPreviousSet, getAvailablePlates())
})

function exitCatchUp() {
  router.push('/today')
}

const sessionNotes = ref('')
watch(() => workoutStore.currentSession?.id, () => {
  sessionNotes.value = workoutStore.currentSession?.notes ?? ''
})
async function saveSessionNotes() {
  const trimmed = sessionNotes.value.trim()
  const current = workoutStore.currentSession?.notes ?? ''
  if (trimmed === current) return
  await workoutStore.updateSessionNotes(trimmed || null)
}

// Accordion state
const open = ref({ rehab: true, main: true, cooldown: true, mobility: true, cardio: true })
function toggle(section) { open.value[section] = !open.value[section] }

function isSectionDone(exercises) {
  if (!exercises.length) return false
  return exercises.every(ex =>
    Array.from({ length: ex.sets_target }, (_, i) => i + 1)
      .every(s => workoutStore.isSetLogged(ex.id, s))
  )
}

const rehabDone    = computed(() => isSectionDone(rehabExercises.value))
const mainDone     = computed(() => isSectionDone(mainExercises.value))
const cooldownDone = computed(() => isSectionDone(cooldownExercises.value))
const mobilityDone = computed(() => isSectionDone(mobilityExercises.value))

watch(rehabDone,    done => { if (done) open.value.rehab    = false })
watch(mainDone,     done => { if (done) open.value.main     = false })
watch(cooldownDone, done => { if (done) open.value.cooldown = false })
watch(mobilityDone, done => { if (done) open.value.mobility = false })
</script>

<template>
  <div class="today-view">
    <!-- Header -->
    <div class="today-header">
      <div class="day-title">
        <span class="day-name">{{ todayDay }}</span>
        <span
          v-if="programStore.activeProgramDay"
          class="day-type-badge"
          :class="dayType"
        >
          {{ dayType === 'strength' ? '💪 Muscu' : dayType === 'cardio' ? '🏃 Cardio' : '😴 Repos' }}
        </span>
      </div>
      <div class="session-name" v-if="programStore.activeProgramDay">
        {{ programStore.activeProgramDay.name }}
      </div>
    </div>

    <!-- À préparer -->
    <div v-if="prepList.length" class="prep-zone">
      <span class="prep-title">À PRÉPARER</span>
      <ul class="prep-list">
        <li v-for="item in prepList" :key="item">{{ item }}</li>
      </ul>
    </div>

    <!-- Catch-up banner -->
    <div v-if="inCatchUpMode" class="catchup-banner">
      <span>🎯 Mode rattrapage — séance du {{ formatLongDate(targetDate) }}</span>
      <button class="catchup-back" @click="exitCatchUp">Aujourd'hui →</button>
    </div>

    <!-- Rest day (masqué pendant le chargement : sans programme chargé, dayType vaut 'rest'
         et « Jour de repos » flashait à chaque ouverture) -->
    <div v-if="isRestDay && !loading" class="rest-day">
      <div class="rest-icon">{{ mobilityExercises.length ? '🌿' : '😴' }}</div>
      <h2>{{ mobilityExercises.length ? 'Récupération active' : 'Jour de repos' }}</h2>
      <p>Récupération = progression. Profites-en !</p>
    </div>

    <!-- Mobility section (rest day) -->
    <div v-if="isRestDay && mobilityExercises.length" class="session-content">
      <div class="section">
        <button class="section-header" @click="toggle('mobility')">
          <div class="section-left">
            <span class="section-label mobility">🌿 MOBILITÉ</span>
            <span class="section-sub">Récupération active</span>
            <span v-if="mobilityDone" class="section-check">✓</span>
          </div>
          <span class="section-chevron" :class="{ open: open.mobility }">›</span>
        </button>
        <div v-show="open.mobility" class="section-body">
          <ExerciseRow
            v-for="ex in mobilityExercises"
            :key="ex.id"
            :exercise="ex"
            @openSet="openSetModal"
          />
        </div>
      </div>
    </div>

    <!-- Strength day -->
    <div v-else-if="isStrength" class="session-content">

      <!-- REHAB section -->
      <div v-if="rehabExercises.length" class="section">
        <button class="section-header" @click="toggle('rehab')">
          <div class="section-left">
            <span class="section-label rehab">🔧 PRÉVENTION</span>
            <span class="section-sub">Avant séance</span>
            <span v-if="rehabDone" class="section-check">✓</span>
          </div>
          <span class="section-chevron" :class="{ open: open.rehab }">›</span>
        </button>
        <div v-show="open.rehab" class="section-body">
          <ExerciseRow
            v-for="ex in rehabExercises"
            :key="ex.id"
            :exercise="ex"
            @openSet="openSetModal"
          />
        </div>
      </div>

      <!-- MAIN section -->
      <div v-if="mainExercises.length" class="section">
        <button class="section-header" @click="toggle('main')">
          <div class="section-left">
            <span class="section-label main">⚡ MUSCU</span>
            <span v-if="mainDone" class="section-check">✓</span>
          </div>
          <span class="section-chevron" :class="{ open: open.main }">›</span>
        </button>
        <div v-show="open.main" class="section-body">
          <ExerciseRow
            v-for="ex in mainExercises"
            :key="ex.id"
            :exercise="ex"
            @openSet="openSetModal"
          />
        </div>
      </div>

      <!-- COOLDOWN section -->
      <div v-if="cooldownExercises.length" class="section">
        <button class="section-header" @click="toggle('cooldown')">
          <div class="section-left">
            <span class="section-label cooldown">🧘 RÉCUP</span>
            <span class="section-sub">Après séance</span>
            <span v-if="cooldownDone" class="section-check">✓</span>
          </div>
          <span class="section-chevron" :class="{ open: open.cooldown }">›</span>
        </button>
        <div v-show="open.cooldown" class="section-body">
          <ExerciseRow
            v-for="ex in cooldownExercises"
            :key="ex.id"
            :exercise="ex"
            @openSet="openSetModal"
          />
        </div>
      </div>

      <!-- Cardio fin -->
      <div v-if="cardioBlocks.length" class="section">
        <button class="section-header" @click="toggle('cardio')">
          <div class="section-left">
            <span class="section-label cardio">🏃 CARDIO</span>
          </div>
          <span class="section-chevron" :class="{ open: open.cardio }">›</span>
        </button>
        <div v-show="open.cardio" class="section-body">
          <template v-for="(block, i) in cardioBlocks" :key="block.id">
            <BoxingTimer v-if="block.name === 'Sac de boxe'" :block="block" :index="i" @done="workoutStore.markCardioDone(block.id)" />
            <CardioBlock v-else :block="block" :index="i" @timer-done="onZone2Done" />
          </template>
        </div>
      </div>
    </div>

    <!-- Cardio day -->
    <div v-else-if="isCardio" class="session-content">
      <div class="section">
        <button class="section-header" @click="toggle('cardio')">
          <div class="section-left">
            <span class="section-label cardio">🏃 CARDIO</span>
          </div>
          <span class="section-chevron" :class="{ open: open.cardio }">›</span>
        </button>
        <div v-show="open.cardio" class="section-body">
          <template v-for="(block, i) in cardioBlocks" :key="block.id">
            <BoxingTimer v-if="block.name === 'Sac de boxe'" :block="block" :index="i" @done="workoutStore.markCardioDone(block.id)" />
            <CardioBlock v-else :block="block" :index="i" @timer-done="onZone2Done" />
          </template>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading">
      <div class="spinner" />
      <p>Chargement...</p>
    </div>

    <!-- Session notes (always visible if there's an active session) -->
    <div v-if="!loading && !!workoutStore.currentSession && !isRestDay" class="notes-zone">
      <details class="notes-details" :open="!!workoutStore.currentSession?.notes">
        <summary class="notes-summary">
          📝 Notes de séance
          <span v-if="workoutStore.currentSession?.notes" class="notes-dot" />
        </summary>
        <textarea
          v-model="sessionNotes"
          @blur="saveSessionNotes"
          placeholder="Sommeil, énergie, sensations, ce qui a marché ou pas…"
          class="notes-textarea"
          rows="3"
        />
      </details>
    </div>

    <!-- Finish button -->
    <div v-if="!loading && !!workoutStore.currentSession" class="finish-zone">
      <div v-if="sessionComplete" class="already-done">
        ✓ Séance terminée
      </div>
      <button
        v-else
        class="finish-btn"
        :disabled="!canFinish"
        @click="finishSession"
      >
        <template v-if="inCatchUpMode">TERMINER LA SÉANCE DU {{ formatShortDate(targetDate).toUpperCase() }}</template>
        <template v-else-if="isRestDay">TERMINER LA RÉCUP</template>
        <template v-else>TERMINER</template>
        <span v-if="!isCardio" class="finish-sub">
          {{ setsProgress.done }}/{{ setsProgress.total }} séries
        </span>
      </button>
    </div>

    <!-- Spacer for bottom nav (extra room when rest timer bar is visible) -->
    <div :style="{ height: restTimer ? '160px' : '80px' }" />

    <!-- Set log modal -->
    <SetLogModal
      v-if="modalOpen"
      :exercise="modalExercise"
      :set-number="modalSetNumber"
      :existing-log="workoutStore.getSetLog(modalExercise?.id, modalSetNumber)"
      :session-prev-set="modalSessionPrevSet"
      :previous-log="workoutStore.getPreviousSet(modalExercise?.id, modalSetNumber)"
      @close="modalOpen = false"
      @save="saveSet"
      @delete="deleteSet"
    />

    <!-- Exercise timer overlay -->
    <ExerciseTimer
      v-if="timerOpen"
      :exercise="timerExercise"
      :set-number="timerSetNumber"
      :target-seconds="timerTarget.min"
      :target-max="timerTarget.max"
      :is-range="timerTarget.isRange"
      :per-side="!!timerExercise?.is_per_side"
      @stop="onTimerStop"
      @cancel="onTimerCancel"
    />

    <!-- Timer input modal (catch-up mode + edit mode for timed exos) -->
    <TimerInputModal
      v-if="timerInputOpen"
      :exercise="timerInputExercise"
      :set-number="timerInputSetNumber"
      :target-seconds="timerInputTarget?.min"
      :target-max="timerInputTarget?.max"
      :is-range="timerInputTarget?.isRange"
      :existing-log="workoutStore.getSetLog(timerInputExercise?.id, timerInputSetNumber)"
      @close="timerInputOpen = false"
      @save="onTimerInputSave"
      @delete="onTimerInputDelete"
    />

    <!-- Celebration overlay -->
    <CelebrationOverlay
      v-if="celebrating"
      :stats="sessionStats"
      @close="celebrating = false"
    />

    <!-- Rest timer between sets -->
    <RestTimerBar
      v-if="restTimer"
      :key="restTimer.key"
      :duration-sec="restTimer.duration"
      :total-sec="restTimer.total"
      :end-at="restTimer.endAt"
      :exercise-name="restTimer.exerciseName"
      :set-number="restTimer.setNumber"
      :accent="restTimer.accent"
      @change="onRestChange"
      @done="onRestDone"
      @dismiss="dismissRestTimer"
    />

    <!-- PR flash -->
    <PRFlash
      v-if="prFlash"
      :exerciseName="prFlash.exerciseName"
      :prevBest="prFlash.prevBest"
      :newE1RM="prFlash.newE1RM"
      :deltaKg="prFlash.deltaKg"
      @close="dismissPR"
    />
  </div>
</template>

<style scoped>
.today-view {
  padding-bottom: 80px;
  min-height: 100vh;
}

.today-header {
  padding: 8px 16px 12px;
}

.day-title {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 2px;
  min-height: 34px;
}

.day-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 28px;
  font-weight: 800;
  color: #f9fafb;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.day-type-badge {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 20px;
  letter-spacing: 0.5px;
}

.day-type-badge.strength { background: rgba(59,130,246,0.15); color: #60a5fa; }
.day-type-badge.cardio   { background: rgba(245,158,11,0.15); color: #fbbf24; }
.day-type-badge.rest     { background: rgba(107,114,128,0.15); color: #9ca3af; }

.session-name {
  font-size: 14px;
  color: #9ca3af;
  min-height: 21px;
}


.prep-zone {
  margin: 0 16px 12px;
  padding: 10px 14px;
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 10px;
}

.prep-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 2px;
  color: #9ca3af;
}

.prep-list {
  margin: 4px 0 0;
  padding-left: 18px;
  font-size: 14px;
  line-height: 1.5;
  color: #e5e7eb;
}

.catchup-banner {
  margin: 0 16px 12px;
  background: rgba(245,158,11,0.12);
  border: 1px solid rgba(245,158,11,0.35);
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  color: #fbbf24;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.catchup-banner span {
  flex: 1;
}

.catchup-back {
  background: transparent;
  border: 1px solid rgba(245,158,11,0.5);
  color: #fbbf24;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.5px;
  padding: 4px 10px;
  border-radius: 6px;
  cursor: pointer;
  white-space: nowrap;
}

.catchup-back:active {
  background: rgba(245,158,11,0.15);
}

.rest-day {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 24px;
  gap: 12px;
  text-align: center;
}

.rest-icon { font-size: 56px; }

.rest-day h2 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 28px;
  font-weight: 700;
  color: #f9fafb;
  margin: 0;
}

.rest-day p {
  color: #9ca3af;
  font-size: 15px;
  margin: 0;
}

.rest-cardio {
  width: 100%;
  max-width: 480px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  text-align: left;
  margin-top: 8px;
}

.session-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 0 16px;
}

.section {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 12px;
  min-height: 48px;
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 10px;
  cursor: pointer;
  width: 100%;
  text-align: left;
  transition: background 0.15s;
  margin-bottom: 0;
}

.section-header:active { background: #1a2235; }

.section-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.section-chevron {
  font-size: 20px;
  color: #4b5563;
  transform: rotate(90deg);
  transition: transform 0.2s ease;
  line-height: 1;
}

.section-chevron.open {
  transform: rotate(270deg);
}

.section-check {
  font-size: 13px;
  font-weight: 800;
  color: #10b981;
  background: rgba(16,185,129,0.12);
  padding: 1px 7px;
  border-radius: 10px;
}

.section-body {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 8px;
}

.section-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 1.5px;
  text-transform: uppercase;
}

.section-label.rehab    { color: #f59e0b; }
.section-label.main     { color: #3b82f6; }
.section-label.cardio   { color: #10b981; }
.section-label.cooldown { color: #8b5cf6; }
.section-label.mobility { color: #06b6d4; }

.section-sub {
  font-size: 13px;
  color: #9ca3af;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px;
  gap: 12px;
  color: #9ca3af;
  min-height: 60vh;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #1f2937;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.notes-zone {
  padding: 4px 16px 0;
}

.notes-details {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 10px;
  overflow: hidden;
}

.notes-summary {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 0.5px;
  padding: 10px 12px;
  cursor: pointer;
  list-style: none;
  display: flex;
  align-items: center;
  gap: 8px;
}

.notes-summary::-webkit-details-marker { display: none; }
.notes-summary::marker { content: ''; }

.notes-dot {
  width: 6px;
  height: 6px;
  background: #3b82f6;
  border-radius: 50%;
  display: inline-block;
}

.notes-textarea {
  width: 100%;
  background: #0a0e17;
  border: none;
  border-top: 1px solid #1f2937;
  color: #f9fafb;
  font-size: 14px;
  font-family: inherit;
  padding: 10px 12px;
  outline: none;
  resize: vertical;
  box-sizing: border-box;
}

.finish-zone {
  padding: 16px;
}

.finish-btn {
  width: 100%;
  min-height: 56px;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  color: white;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 2px;
  border: none;
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
}

.finish-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
  background: #374151;
}

.finish-btn:not(:disabled):active {
  transform: scale(0.98);
}

.finish-sub {
  font-size: 14px;
  opacity: 0.85;
  font-weight: 600;
}

.already-done {
  text-align: center;
  color: #10b981;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  padding: 12px;
  background: rgba(16,185,129,0.08);
  border-radius: 12px;
}
</style>
