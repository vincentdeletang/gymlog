<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  durationSec: { type: Number, required: true },
  exerciseName: String,
  setNumber: Number,
  accent: { type: String, default: '#3b82f6' },
})
const emit = defineEmits(['done', 'dismiss'])

const { playTick10, playComplete, vibrate } = useAudio()

const remaining = ref(props.durationSec)
const total = ref(props.durationSec)
const finished = ref(false)
let endAt = 0
let raf = null
const fired = new Set()

function tick() {
  const now = Date.now()
  const ms = Math.max(0, endAt - now)
  remaining.value = Math.ceil(ms / 1000)

  // Halfway tick (only if duration ≥ 60s)
  if (total.value >= 60) {
    const half = Math.floor(total.value / 2)
    if (!fired.has('half') && total.value - remaining.value >= half) {
      fired.add('half')
      playTick10()
      vibrate([30])
    }
  }

  // Last 3 ticks
  for (let i = 3; i >= 1; i--) {
    if (!fired.has(`c${i}`) && remaining.value === i) {
      fired.add(`c${i}`)
      playTick10()
      vibrate([40])
    }
  }

  if (ms <= 0 && !finished.value) {
    finished.value = true
    playComplete()
    vibrate([120, 60, 120])
    return
  }
  raf = requestAnimationFrame(tick)
}

function start(seconds) {
  total.value = seconds
  remaining.value = seconds
  endAt = Date.now() + seconds * 1000
  finished.value = false
  fired.clear()
  if (raf) cancelAnimationFrame(raf)
  raf = requestAnimationFrame(tick)
}

function add(seconds) {
  endAt += seconds * 1000
  if (finished.value && endAt > Date.now()) {
    finished.value = false
    fired.clear()
    raf = requestAnimationFrame(tick)
  }
}

function sub(seconds) {
  endAt = Math.max(Date.now(), endAt - seconds * 1000)
}

function dismiss() {
  if (raf) cancelAnimationFrame(raf)
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
  start(props.durationSec)
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibility)
  if (raf) cancelAnimationFrame(raf)
})

watch(() => props.durationSec, (n) => start(n))

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
      <div class="bar-info">
        <div class="bar-label">
          <span v-if="!finished">Repos</span>
          <span v-else>✓ Repos terminé</span>
        </div>
        <div class="bar-sub" v-if="exerciseName">
          {{ exerciseName }} · S{{ setNumber }}
        </div>
      </div>

      <div class="bar-time">{{ display }}</div>

      <div class="bar-actions">
        <button class="btn-adj" @click="sub(15)" :disabled="finished" aria-label="−15s">−15</button>
        <button class="btn-adj" @click="add(30)" aria-label="+30s">+30</button>
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
  gap: 10px;
  padding: 10px 14px;
  min-height: 56px;
}

.bar-info {
  flex: 1;
  min-width: 0;
}

.bar-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.rest-bar.done .bar-label { color: #10b981; }

.bar-sub {
  font-size: 11px;
  color: #6b7280;
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.bar-time {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 26px;
  font-weight: 800;
  color: #f9fafb;
  letter-spacing: 0.5px;
  font-variant-numeric: tabular-nums;
  min-width: 56px;
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
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.3px;
  padding: 6px 8px;
  border-radius: 8px;
  cursor: pointer;
  min-width: 38px;
  transition: background 0.1s;
}

.btn-adj:active:not(:disabled) { background: #374151; }
.btn-adj:disabled { opacity: 0.4; cursor: not-allowed; }

.btn-close {
  background: transparent;
  border: 1px solid #1f2937;
  color: #6b7280;
  font-size: 14px;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:active { background: #1f2937; color: #e5e7eb; }
</style>
