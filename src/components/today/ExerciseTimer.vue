<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  exercise: Object,
  setNumber: Number,
  targetSeconds: Number,
  targetMax: Number,
  isRange: Boolean,
})
const emit = defineEmits(['stop', 'cancel'])

const {
  playPrepTick, playGo, playTick10, playTickHalf, playTickFinal,
  playComplete, vibrate,
} = useAudio()

const phase = ref('prep') // 'prep' | 'run' | 'post'
const prepCount = ref(3)
const elapsedMs = ref(0)

let startRunTime = 0
let rafId = null
let prepTimer = null
let tickTimer = null
const fired = new Set()
let wakeLock = null

const SECTION_COLOR = {
  rehab:    '#f59e0b',
  main:     '#3b82f6',
  cardio:   '#10b981',
  cooldown: '#8b5cf6',
  mobility: '#06b6d4',
}
const accent = computed(() => SECTION_COLOR[props.exercise?.section] ?? '#3b82f6')

const elapsedSec = computed(() => Math.floor(elapsedMs.value / 1000))

const remainingSec = computed(() =>
  Math.max(0, props.targetSeconds - elapsedSec.value)
)

const overtimeSec = computed(() =>
  Math.max(0, elapsedSec.value - props.targetSeconds)
)

const progress = computed(() => {
  if (phase.value === 'prep') return 0
  if (phase.value === 'post') return 1
  return Math.min(elapsedMs.value / (props.targetSeconds * 1000), 1)
})

const displayTime = computed(() => {
  if (phase.value === 'prep') return String(Math.max(prepCount.value, 0))
  const s = phase.value === 'post' ? overtimeSec.value : remainingSec.value
  const m = Math.floor(s / 60)
  const ss = String(s % 60).padStart(2, '0')
  return `${m}:${ss}`
})

const ringStyle = computed(() => ({
  background: `conic-gradient(${accent.value} ${progress.value * 360}deg, #1f2937 0deg)`,
}))

const formattedTarget = computed(() =>
  props.isRange
    ? `${props.targetSeconds}-${props.targetMax}s`
    : `${props.targetSeconds}s`
)

function fireOnce(key, fn) {
  if (fired.has(key)) return
  fired.add(key)
  fn()
}

function checkMilestones() {
  const sec = elapsedSec.value
  const target = props.targetSeconds
  const halfwayAt = Math.floor(target / 2)
  const hasTicks = target >= 45
  const tickInterval = target >= 90 ? 15 : 10

  if (phase.value === 'run') {
    if (halfwayAt > 0 && halfwayAt <= target - 5 && sec >= halfwayAt) {
      fireOnce('halfway', () => { playTickHalf(); vibrate([90]) })
    }
    if (hasTicks) {
      for (let t = tickInterval; t < target - 5; t += tickInterval) {
        if (t === halfwayAt) continue
        if (sec >= t) fireOnce(`tick_${t}`, () => { playTick10(); vibrate([30]) })
      }
    }
    for (let i = 5; i >= 1; i--) {
      const t = target - i
      if (t > 0 && sec >= t) {
        fireOnce(`count_${i}`, () => { playTickFinal(); vibrate([40]) })
      }
    }
    if (sec >= target) {
      fireOnce('target', () => {
        playComplete()
        vibrate([120, 60, 120, 60, 200])
      })
      if (props.isRange) {
        phase.value = 'post'
      } else {
        doStop()
        return
      }
    }
  } else if (phase.value === 'post') {
    for (let t = 10; t <= 600; t += 10) {
      if (sec >= target + t) {
        fireOnce(`post_${t}`, () => { playTick10(); vibrate([30]) })
      }
    }
  }
}

function loop() {
  if (phase.value !== 'run' && phase.value !== 'post') return
  elapsedMs.value = Date.now() - startRunTime
  rafId = requestAnimationFrame(loop)
}

function startRun() {
  phase.value = 'run'
  startRunTime = Date.now()
  elapsedMs.value = 0
  fired.clear()
  playGo()
  vibrate([80])
  requestWakeLock()
  loop()
  tickTimer = setInterval(checkMilestones, 200)
}

function startPrep() {
  prepCount.value = 3
  playPrepTick()
  vibrate([50])
  prepTimer = setInterval(() => {
    prepCount.value--
    if (prepCount.value > 0) {
      playPrepTick()
      vibrate([50])
    } else {
      clearInterval(prepTimer); prepTimer = null
      startRun()
    }
  }, 1000)
}

async function requestWakeLock() {
  try {
    wakeLock = await navigator.wakeLock?.request('screen')
  } catch {}
}
function releaseWakeLock() {
  try { wakeLock?.release?.() } catch {}
  wakeLock = null
}

function onVisibility() {
  if (document.visibilityState !== 'visible') return
  if (phase.value === 'run' || phase.value === 'post') {
    elapsedMs.value = Date.now() - startRunTime
    checkMilestones()
    requestWakeLock()
  }
}

function teardown() {
  if (rafId) { cancelAnimationFrame(rafId); rafId = null }
  if (prepTimer) { clearInterval(prepTimer); prepTimer = null }
  if (tickTimer) { clearInterval(tickTimer); tickTimer = null }
  releaseWakeLock()
}

function doStop() {
  teardown()
  const seconds = Math.max(1, elapsedSec.value)
  emit('stop', { seconds })
}

function doCancel() {
  teardown()
  emit('cancel')
}

onMounted(() => {
  document.addEventListener('visibilitychange', onVisibility)
  startPrep()
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibility)
  teardown()
})
</script>

<template>
  <div class="timer-overlay" @click.self="doCancel">
    <div class="timer-card">
      <div class="timer-header">
        <div class="ex-name">{{ exercise.name }}</div>
        <div class="ex-sub">Série {{ setNumber }} · cible {{ formattedTarget }}</div>
      </div>

      <div class="ring-wrap" :style="{ '--accent': accent }">
        <div class="ring" :style="ringStyle">
          <div class="ring-inner">
            <div v-if="phase === 'prep'" class="prep-label">PRÊT</div>
            <div class="big-time" :class="phase">{{ displayTime }}</div>
            <div v-if="phase === 'post'" class="overtime-label">BONUS</div>
          </div>
        </div>
      </div>

      <div class="timer-actions">
        <button
          v-if="phase !== 'prep'"
          class="btn-stop"
          :style="{ background: accent }"
          @click="doStop"
        >
          ARRÊTER ✓
        </button>
        <button class="btn-cancel" @click="doCancel">
          ✕ Annuler
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.timer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 14, 23, 0.97);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  backdrop-filter: blur(6px);
}

.timer-card {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 28px;
}

.timer-header {
  text-align: center;
}

.ex-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 24px;
  font-weight: 800;
  color: #f9fafb;
  letter-spacing: 0.5px;
}

.ex-sub {
  font-size: 13px;
  color: #9ca3af;
  margin-top: 4px;
}

.ring-wrap {
  position: relative;
  width: 280px;
  height: 280px;
}

.ring {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  transition: background 0.3s linear;
}

.ring-inner {
  position: absolute;
  inset: 16px;
  background: #0a0e17;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.prep-label, .overtime-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 3px;
  text-transform: uppercase;
}

.big-time {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 76px;
  font-weight: 800;
  color: #f9fafb;
  line-height: 1;
  letter-spacing: 1px;
  font-variant-numeric: tabular-nums;
}

.big-time.prep {
  font-size: 110px;
  color: var(--accent);
}

.big-time.post {
  color: var(--accent);
}

.timer-actions {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.btn-stop {
  width: 100%;
  min-height: 56px;
  color: #0a0e17;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 2px;
  border: none;
  border-radius: 14px;
  cursor: pointer;
  transition: transform 0.15s;
}

.btn-stop:active {
  transform: scale(0.98);
}

.btn-cancel {
  width: 100%;
  min-height: 44px;
  background: transparent;
  color: #6b7280;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 1px;
  border: 1px solid #1f2937;
  border-radius: 12px;
  cursor: pointer;
}
</style>
