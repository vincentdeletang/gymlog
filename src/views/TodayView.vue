<script setup>
import { ref, computed, onMounted } from 'vue'
import LevelBar from '@/components/shared/LevelBar.vue'
import ExerciseRow from '@/components/today/ExerciseRow.vue'
import SetLogModal from '@/components/today/SetLogModal.vue'
import CardioBlock from '@/components/today/CardioBlock.vue'
import CelebrationOverlay from '@/components/today/CelebrationOverlay.vue'
import { useProgramStore } from '@/stores/useProgramStore'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { useUserStore } from '@/stores/useUserStore'
import { useAudio } from '@/composables/useAudio'

const programStore = useProgramStore()
const workoutStore = useWorkoutStore()
const userStore = useUserStore()
const { playSuccess } = useAudio()

const loading = ref(true)
const celebrating = ref(false)
const xpEarned = ref(0)
const earnedStreak = ref(0)

// Modal state
const modalOpen = ref(false)
const modalExercise = ref(null)
const modalSetNumber = ref(null)

const todayDay = computed(() => {
  const days = ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi']
  return days[new Date().getDay()]
})

const dayType = computed(() => programStore.todayProgramDay?.type ?? 'rest')
const isRestDay = computed(() => dayType.value === 'rest')
const isStrength = computed(() => dayType.value === 'strength')
const isCardio = computed(() => dayType.value === 'cardio')

const rehabExercises = computed(() => programStore.exercisesBySection.rehab)
const mainExercises = computed(() => programStore.exercisesBySection.main)
const cardioBlocks = computed(() => programStore.todayCardioBlocks)

const sessionComplete = computed(() => workoutStore.currentSession?.completed ?? false)

const canFinish = computed(() =>
  !sessionComplete.value && !!workoutStore.currentSession
)

const setsProgress = computed(() => {
  const allExercises = [...rehabExercises.value, ...mainExercises.value]
  const total = allExercises.reduce((sum, ex) => sum + ex.sets_target, 0)
  const done  = allExercises.reduce((sum, ex) =>
    sum + Array.from({ length: ex.sets_target }, (_, i) => i + 1)
          .filter(s => workoutStore.isSetLogged(ex.id, s)).length, 0)
  return { done, total }
})

onMounted(async () => {
  await programStore.fetchActiveProgram()
  if (programStore.todayProgramDay && !isRestDay.value) {
    await workoutStore.startOrResumeSession(programStore.todayProgramDay.id)
  }
  loading.value = false
})

async function openSetModal({ exercise, setNumber }) {
  // Rehab = tap to toggle, no modal needed
  if (exercise.section === 'rehab') {
    const already = workoutStore.isSetLogged(exercise.id, setNumber)
    if (!already) {
      await workoutStore.logSet({ exerciseId: exercise.id, setNumber, weightKg: null, repsDone: null, rir: null })
      playSuccess()
    }
    return
  }
  modalExercise.value = exercise
  modalSetNumber.value = setNumber
  modalOpen.value = true
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
  await workoutStore.logSet({
    exerciseId: modalExercise.value.id,
    setNumber: modalSetNumber.value,
    weightKg,
    repsDone,
    rir,
  })
  playSuccess()
  modalOpen.value = false
}

async function finishSession() {
  const xp = programStore.todayProgramDay?.xp_reward ?? 0
  const ok = await workoutStore.completeSession(xp)
  if (ok) {
    xpEarned.value = xp
    earnedStreak.value = userStore.streak
    celebrating.value = true
  }
}

const WARNING_STREAK = 7
const streakWarning = computed(() => userStore.streak >= WARNING_STREAK)
</script>

<template>
  <div class="today-view">
    <LevelBar />

    <!-- Header -->
    <div class="today-header">
      <div class="day-title">
        <span class="day-name">{{ todayDay }}</span>
        <span
          v-if="programStore.todayProgramDay"
          class="day-type-badge"
          :class="dayType"
        >
          {{ dayType === 'strength' ? '💪 Muscu' : dayType === 'cardio' ? '🏃 Cardio' : '😴 Repos' }}
        </span>
      </div>
      <div class="session-name" v-if="programStore.todayProgramDay">
        {{ programStore.todayProgramDay.name }}
      </div>
    </div>

    <!-- Streak warning -->
    <div v-if="streakWarning" class="warning-banner">
      ⚠️ {{ userStore.streak }} jours sans repos — pense à récupérer !
    </div>

    <!-- Rest day -->
    <div v-if="isRestDay" class="rest-day">
      <div class="rest-icon">😴</div>
      <h2>Jour de repos</h2>
      <p>Récupération = progression. Profites-en !</p>
      <div v-if="cardioBlocks.length" class="rest-cardio">
        <p class="section-label">Optionnel :</p>
        <CardioBlock
          v-for="(block, i) in cardioBlocks"
          :key="block.id"
          :block="block"
          :index="i"
        />
      </div>
    </div>

    <!-- Strength day -->
    <div v-else-if="isStrength" class="session-content">
      <!-- REHAB section -->
      <div v-if="rehabExercises.length" class="section">
        <div class="section-header">
          <span class="section-label rehab">🔧 REHAB</span>
          <span class="section-sub">Avant séance</span>
        </div>
        <ExerciseRow
          v-for="ex in rehabExercises"
          :key="ex.id"
          :exercise="ex"
          @openSet="openSetModal"
        />
      </div>

      <!-- MAIN section -->
      <div v-if="mainExercises.length" class="section">
        <div class="section-header">
          <span class="section-label main">⚡ MAIN</span>
        </div>
        <ExerciseRow
          v-for="ex in mainExercises"
          :key="ex.id"
          :exercise="ex"
          @openSet="openSetModal"
        />
      </div>

      <!-- Cardio fin -->
      <div v-if="cardioBlocks.length" class="section">
        <div class="section-header">
          <span class="section-label cardio">🏃 CARDIO FIN</span>
        </div>
        <CardioBlock
          v-for="(block, i) in cardioBlocks"
          :key="block.id"
          :block="block"
          :index="i"
        />
      </div>
    </div>

    <!-- Cardio day -->
    <div v-else-if="isCardio" class="session-content">
      <div class="section">
        <div class="section-header">
          <span class="section-label cardio">🏃 CARDIO</span>
        </div>
        <CardioBlock
          v-for="(block, i) in cardioBlocks"
          :key="block.id"
          :block="block"
          :index="i"
        />
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading">
      <div class="spinner" />
      <p>Chargement...</p>
    </div>

    <!-- Finish button -->
    <div v-if="!isRestDay && !loading" class="finish-zone">
      <div v-if="sessionComplete" class="already-done">
        ✓ Séance terminée
      </div>
      <button
        v-else
        class="finish-btn"
        :disabled="!canFinish"
        @click="finishSession"
      >
        TERMINER
        <span class="xp-preview">
          {{ setsProgress.done }}/{{ setsProgress.total }} séries
          · +{{ programStore.todayProgramDay?.xp_reward ?? 0 }} XP
        </span>
      </button>
    </div>

    <!-- Spacer for bottom nav -->
    <div style="height: 80px" />

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
    />

    <!-- Celebration overlay -->
    <CelebrationOverlay
      v-if="celebrating"
      :xp-earned="xpEarned"
      :streak-count="earnedStreak"
      @close="celebrating = false"
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
}

.warning-banner {
  margin: 0 16px 12px;
  background: rgba(245,158,11,0.1);
  border: 1px solid rgba(245,158,11,0.3);
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 13px;
  color: #fbbf24;
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
  gap: 8px;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
}

.section-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 1.5px;
  text-transform: uppercase;
}

.section-label.rehab  { color: #f59e0b; }
.section-label.main   { color: #3b82f6; }
.section-label.cardio { color: #10b981; }

.section-sub {
  font-size: 12px;
  color: #6b7280;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px;
  gap: 12px;
  color: #9ca3af;
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

.xp-preview {
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
