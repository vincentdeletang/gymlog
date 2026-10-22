<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  durationSec: { type: Number, default: 0 },
  endAt: { type: Number, default: 0 },     // absolute ms timestamp; restores a running timer across reloads
  totalSec: { type: Number, default: 0 },  // full duration (for the progress bar); falls back to durationSec
  exerciseName: String,
  setNumber: Number,
  accent: { type: String, default: '#3b82f6' },
})
const emit = defineEmits(['done', 'dismiss', 'change'])

const { scheduleSequence, vibrate } = useAudio()

const remaining = ref(props.durationSec)
const total = ref(props.durationSec)
const finished = ref(false)
let endAt = 0
let raf = null
const fired = new Set()
let cues = null

// Les sons sont posés d'un bloc sur l'horloge audio (cf. ExerciseTimer) : le
// requestAnimationFrame ci-dessous s'arrête dès que l'écran est caché, et les bips
// arrivaient en retard ou groupés. Le JS n'affiche et ne vibre que.
function scheduleCues() {
  if (cues) { cues.cancel(); cues = null }
  const rem = (endAt - Date.now()) / 1000
  if (rem <= 0) return
  const events = []
  if (total.value >= 60 && !fired.has('half')) {
    const halfFromNow = Math.floor(total.value / 2) - (total.value - rem)
    if (halfFromNow > 0) events.push({ at: halfFromNow, kind: 'tick' })
  }
  for (let i = 3; i >= 1; i--) if (rem - i > 0) events.push({ at: rem - i, kind: 'tick' })
  events.push({ at: rem, kind: 'complete' })
  cues = scheduleSequence(events)
}

function tick() {
  const now = Date.now()
  const ms = Math.max(0, endAt - now)
  remaining.value = Math.ceil(ms / 1000)

  // Halfway tick (only if duration ≥ 60s)
  if (total.value >= 60) {
    const half = Math.floor(total.value / 2)
    if (!fired.has('half') && total.value - remaining.value >= half) {
      fired.add('half')
      vibrate([30])
    }
  }

  // Last 3 ticks
  for (let i = 3; i >= 1; i--) {
    if (!fired.has(`c${i}`) && remaining.value === i) {
      fired.add(`c${i}`)
      vibrate([40])
    }
  }

  if (ms <= 0 && !finished.value) {
    finished.value = true
    vibrate([120, 60, 120])
    return
  }
  raf = requestAnimationFrame(tick)
}

function init(totalDuration, endAtMs) {
  total.value = totalDuration
  endAt = endAtMs
  finished.value = false
  fired.clear()
  const remNow = Math.ceil(Math.max(0, endAt - Date.now()) / 1000)
  remaining.value = remNow
  // Prime past cues so a restored timer doesn't replay every beep at once
  if (totalDuration >= 60 && totalDuration - remNow >= Math.floor(totalDuration / 2)) fired.add('half')
  for (let i = 3; i >= 1; i--) if (remNow < i) fired.add(`c${i}`)
  if (endAt <= Date.now()) finished.value = true
  scheduleCues()
  if (raf) cancelAnimationFrame(raf)
  raf = requestAnimationFrame(tick)
}

function start(seconds) {
  init(seconds, Date.now() + seconds * 1000)
}

function add(seconds) {
  endAt += seconds * 1000
  if (finished.value && endAt > Date.now()) {
    finished.value = false
    fired.clear()
    raf = requestAnimationFrame(tick)
  }
  scheduleCues()
  emit('change', endAt)
}

function sub(seconds) {
  endAt = Math.max(Date.now(), endAt - seconds * 1000)
  scheduleCues()
  emit('change', endAt)
}

function dismiss() {
  if (raf) cancelAnimationFrame(raf)
  if (cues) { cues.cancel(); cues = null }
  emit('dismiss')
}

function onVisibility() {
  if (document.visibilityState === 'visible' && !finished.value) {
    if (raf) cancelAnimationFrame(raf)
    raf = requestAnimationFrame(tick)
  }
}

onMounted(() => {
  document.addEventListener('visibilitychange', onVisibility)
  if (props.endAt) init(props.totalSec || props.durationSec, props.endAt)
  else start(props.durationSec)
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibility)
  if (raf) cancelAnimationFrame(raf)
  if (cues) { cues.cancel(); cues = null }
})

const display = computed(() => {
  const s = Math.max(0, remaining.value)
  const m = Math.floor(s / 60)
  const ss = String(s % 60).padStart(2, '0')
  return m > 0 ? `${m}:${ss}` : `${s}s`
})

const progress = computed(() => {
  if (total.value <= 0) return 0
  return Math.min(1, (total.value - remaining.value) / total.value)
})
</script>

<template>
  <div class="rest-bar" :class="{ done: finished }" :style="{ '--accent': accent }">
    <div class="bar-fill" :style="{ width: progress * 100 + '%' }" />
    <div class="bar-content">
      <div class="bar-label">
        <span v-if="!finished">Repos</span>
        <span v-else>✓ Prêt</span>
      </div>

      <div class="bar-time">{{ display }}</div>

      <div class="bar-actions">
        <button class="btn-adj" @click="sub(15)" :disabled="finished">−15</button>
        <button class="btn-adj" @click="add(30)">+30</button>
        <button class="btn-close" @click="dismiss" aria-label="Fermer">✕</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.rest-bar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: calc(64px + env(safe-area-inset-bottom));
  background: #0f1623;
  border-top: 1px solid #1f2937;
  z-index: 50;
  overflow: hidden;
  animation: slide-up 0.2s ease-out;
}

.rest-bar.done {
  background: rgba(16, 185, 129, 0.12);
  border-top-color: rgba(16, 185, 129, 0.3);
}

@keyframes slide-up {
  from { transform: translateY(100%); }
  to   { transform: translateY(0); }
}

.bar-fill {
  position: absolute;
  inset: 0;
  background: linear-gradient(90deg, var(--accent) 0%, color-mix(in srgb, var(--accent) 60%, transparent) 100%);
  opacity: 0.18;
  transition: width 1s linear;
  pointer-events: none;
}

.rest-bar.done .bar-fill {
  background: rgba(16, 185, 129, 0.25);
  opacity: 1;
}

.bar-content {
  position: relative;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  min-height: 64px;
}

.bar-label {
  flex: 1;
  min-width: 0;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1.5px;
  text-transform: uppercase;
}

.rest-bar.done .bar-label { color: #10b981; }

.bar-time {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 40px;
  font-weight: 800;
  color: #f9fafb;
  line-height: 1;
  letter-spacing: 0.5px;
  font-variant-numeric: tabular-nums;
  min-width: 84px;
  text-align: right;
}

.rest-bar.done .bar-time { color: #10b981; }

.bar-actions {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

.btn-adj {
  background: #1f2937;
  border: 1px solid #374151;
  color: #e5e7eb;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 0.3px;
  padding: 0 6px;
  border-radius: 10px;
  cursor: pointer;
  min-width: 46px;
  min-height: 46px;
  transition: background 0.1s;
}

.btn-adj:active:not(:disabled) { background: #374151; }
.btn-adj:disabled { opacity: 0.4; cursor: not-allowed; }

.btn-close {
  background: transparent;
  border: 1px solid #374151;
  color: #9ca3af;
  font-size: 16px;
  width: 46px;
  height: 46px;
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:active { background: #1f2937; color: #e5e7eb; }
</style>
