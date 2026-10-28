<script setup>
import { computed, ref, watch, onUnmounted } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { suggestedDuration, durationDelta } from '@/lib/cardioProgression'
import CardioDetailModal from './CardioDetailModal.vue'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  block: Object,
  index: Number,
})

const emit = defineEmits(['timerDone'])

const workoutStore = useWorkoutStore()
const { scheduleSequence, vibrate } = useAudio()
const done = computed(() => workoutStore.isCardioDone(props.block.id))
const log  = computed(() => workoutStore.getCardioLog(props.block.id))
const detailOpen = ref(false)

const suggestion = computed(() =>
  suggestedDuration(workoutStore.getPreviousCardioLogs(props.block.id), props.block)
)

const targetMin = computed(() => suggestion.value?.duration ?? props.block.duration_minutes)

const loggedMin = computed(() =>
  log.value?.duration_seconds ? Math.round(log.value.duration_seconds / 60) : null
)

const delta = computed(() => durationDelta(log.value?.duration_seconds, targetMin.value))

// Un tap logue la durée cible : c'est le cas de 9 séances sur 10. L'autre durée
// passe par la modal.
function toggleDone() {
  if (done.value) workoutStore.unmarkCardioDone(props.block.id)
  else workoutStore.markCardioDone(props.block.id, { duration_seconds: targetMin.value * 60 })
}

function onDetailSave(details) {
  workoutStore.markCardioDone(props.block.id, details)
  detailOpen.value = false
}

// ── Chrono de zone 2 (28/10/2026) ──────────────────────────────────────────────────────
// Lancé en montant sur le tapis : bips sur les 3 dernières secondes, puis il logue la durée
// et l'écran de séance clôt la séance (timerDone). Avant : un bouton « Fait » pressé, ou
// oublié (2 zones 2 loguées sur 7 séances depuis le 19/10, dont une 5 h après).
// L'heure de fin vit dans localStorage : le chrono survit au rechargement de la page.
const TIMER_KEY = 'gymlog.cardioTimer'
const running = ref(null) // { sessionId, blockId, startAt, endAt }
const now = ref(Date.now())
let loop = null
let cues = null

function persist(t) {
  try { t ? localStorage.setItem(TIMER_KEY, JSON.stringify(t)) : localStorage.removeItem(TIMER_KEY) } catch {}
}

function scheduleCues() {
  cues?.cancel()
  const rem = (running.value.endAt - Date.now()) / 1000
  const ev = []
  for (let i = 3; i >= 1; i--) if (rem - i > 0) ev.push({ at: rem - i, kind: 'tick' })
  if (rem > 0) ev.push({ at: rem, kind: 'complete' })
  cues = scheduleSequence(ev)
}

function startLoop() {
  clearInterval(loop)
  loop = setInterval(() => {
    now.value = Date.now()
    if (running.value && now.value >= running.value.endAt) finish(true)
  }, 250)
}

function clearTimer() {
  clearInterval(loop); loop = null
  cues?.cancel(); cues = null
  running.value = null
  persist(null)
}

function startZone2() {
  const sessionId = workoutStore.currentSession?.id
  if (!sessionId) return
  const t0 = Date.now()
  running.value = { sessionId, blockId: props.block.id, startAt: t0, endAt: t0 + targetMin.value * 60000 }
  now.value = t0
  persist(running.value)
  scheduleCues()
  startLoop()
  vibrate([80])
}

// full = le chrono est allé au bout ; sinon arrêt à la main, on logue les minutes faites.
function finish(full) {
  const t = running.value
  if (!t) return
  const secs = full ? Math.round((t.endAt - t.startAt) / 1000) : Math.round((Date.now() - t.startAt) / 60000) * 60
  clearTimer()
  if (secs < 60) return
  workoutStore.markCardioDone(props.block.id, { duration_seconds: secs })
  if (full) {
    vibrate([200, 80, 200])
    emit('timerDone')
  }
}

const remainingLabel = computed(() => {
  if (!running.value) return ''
  const s = Math.max(0, Math.ceil((running.value.endAt - now.value) / 1000))
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`
})

// Restauration après rechargement : la séance doit être chargée pour vérifier que le chrono
// est bien celui de cette séance.
watch(() => workoutStore.currentSession?.id, (sid) => {
  if (!sid || running.value) return
  let t = null
  try { t = JSON.parse(localStorage.getItem(TIMER_KEY) || 'null') } catch {}
  if (!t || t.blockId !== props.block.id) return
  if (t.sessionId !== sid) { persist(null); return }
  running.value = t
  if (Date.now() >= t.endAt) { finish(true); return }
  scheduleCues()
  startLoop()
}, { immediate: true })

onUnmounted(() => {
  clearInterval(loop)
  cues?.cancel()
})
</script>

<template>
  <div class="cardio-block" :class="{ done }">
    <div class="block-header">
      <span class="block-index">{{ index + 1 }}</span>
      <div class="block-text">
        <div class="block-name">{{ block.name }}</div>
        <div class="block-target">
          <span class="target-min">{{ targetMin }} min</span>
          <span v-if="suggestion?.increased" class="cardio-suggestion increased">
            ↑ +{{ block.progression_step_minutes ?? 2 }} min
          </span>
          <span v-else-if="suggestion?.atMax && !suggestion?.increased" class="cardio-suggestion atmax">
            🎯 max
          </span>
          <span v-if="done && loggedMin != null && delta" class="block-actual" :class="{ over: delta > 0, under: delta < 0 }">
            · fait {{ loggedMin }} min
          </span>
        </div>
      </div>
    </div>

    <div v-if="running" class="block-actions">
      <div class="z2-time">{{ remainingLabel }}</div>
      <button class="edit-btn" @click="finish(false)">Arrêter</button>
      <button class="edit-btn" @click="clearTimer">✕</button>
    </div>

    <button v-else-if="!done" class="z2-start" @click="startZone2">
      ▶ Lancer {{ targetMin }} min
    </button>

    <div v-if="!running" class="block-actions">
      <button class="done-btn" :class="{ active: done }" @click="toggleDone">
        <template v-if="done">✓ {{ loggedMin ?? targetMin }} min</template>
        <template v-else>Fait · {{ targetMin }} min</template>
      </button>
      <button class="edit-btn" @click="detailOpen = true">
        {{ done ? 'Modifier' : 'Autre durée' }}
      </button>
    </div>

    <div v-if="block.notes" class="block-notes">💡 {{ block.notes }}</div>

    <CardioDetailModal
      v-if="detailOpen"
      :block="block"
      :existing-log="log"
      @close="detailOpen = false"
      @save="onDetailSave"
    />
  </div>
</template>

<style scoped>
.cardio-block {
  background: #111827;
  border: 1px solid #1f2937;
  border-left: 3px solid #f59e0b;
  border-radius: 12px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: border-color 0.2s;
}

.cardio-block.done {
  border-left-color: #10b981;
}

.block-header {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.block-index {
  width: 28px;
  height: 28px;
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
  font-family: 'Barlow Condensed', sans-serif;
  font-weight: 800;
  font-size: 16px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.block-text { min-width: 0; }

.block-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 19px;
  font-weight: 700;
  color: #f9fafb;
  line-height: 1.15;
}

.block-target {
  font-size: 13px;
  color: #9ca3af;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 2px;
}

.target-min {
  font-weight: 600;
}

.cardio-suggestion {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.5px;
  padding: 1px 6px;
  border-radius: 5px;
}

.cardio-suggestion.increased {
  color: #10b981;
  background: rgba(16, 185, 129, 0.12);
}

.cardio-suggestion.atmax {
  color: #f59e0b;
  background: rgba(245, 158, 11, 0.12);
}

.block-actual {
  color: #10b981;
  font-weight: 600;
}

.block-actual.under {
  color: #f59e0b;
}

.block-actions {
  display: flex;
  gap: 8px;
}

.z2-start {
  width: 100%;
  min-height: 56px;
  background: #10b981;
  color: #0a0e17;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 1px;
  border: none;
  border-radius: 12px;
  cursor: pointer;
}

.z2-start:active { transform: scale(0.98); }

.z2-time {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 52px;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 40px;
  font-weight: 800;
  color: #10b981;
  font-variant-numeric: tabular-nums;
}

.done-btn {
  flex: 1;
  min-height: 52px;
  padding: 0 14px;
  background: #1f2937;
  color: #e5e7eb;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  border: 2px solid #374151;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.15s;
}

.done-btn.active {
  background: rgba(16, 185, 129, 0.15);
  border-color: #10b981;
  color: #10b981;
}

.done-btn:active { transform: scale(0.97); }

.edit-btn {
  min-height: 52px;
  padding: 0 14px;
  background: transparent;
  border: 1px solid #374151;
  color: #9ca3af;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px;
  font-weight: 600;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.15s;
}

.edit-btn:active { background: #1f2937; color: #f9fafb; }

.block-notes {
  font-size: 13px;
  color: #9ca3af;
  line-height: 1.45;
}
</style>
