<script setup>
import { ref, computed, onUnmounted } from 'vue'

const props = defineProps({ block: Object, index: Number })
const emit = defineEmits(['done'])

const ROUNDS = [
  {
    name: 'Échauffement',
    duration: 180,
    color: '#f97316',
    instruction: 'Rotations articulaires (poignets, coudes, épaules, hanches, genoux, chevilles). Shadow léger, garde haute, petits déplacements latéraux.',
    tip: 'Prends ton temps, réveille chaque articulation.',
  },
  {
    name: 'Round 1',
    duration: 180,
    color: '#ef4444',
    instruction: "Petits coups enchaînés, pas fort. Rythme léger, reste relâché. Entre chaque série : remonte ta garde et fais 1-2 pas latéraux.",
    tip: "Si t'es pas à l'aise → ralentis. La technique d'abord, la vitesse viendra.",
  },
  {
    name: 'Round 2',
    duration: 180,
    color: '#ef4444',
    instruction: "Petits coups suivis de 2 à 4 coups forts sans s'arrêter. Après chaque série explosive : slip gauche ou droite + remonte en garde.",
    tip: "Expire sur chaque coup fort. Esquive même si y'a personne — ça crée le réflexe.",
  },
  {
    name: 'Round 3',
    duration: 180,
    color: '#ef4444',
    instruction: "JAB → bouge, JAB + CROCHET avant → bouge, JAB + CROCHET + CROSS arrière → SLIP + garde. Répète le pattern, esquive après chaque combo.",
    tip: "Lent c'est OK. Décompose chaque coup. Rotation des hanches > vitesse des bras.",
  },
  {
    name: 'Round 4',
    duration: 180,
    color: '#ef4444',
    instruction: "JAB → CROCHET → CROSS → FRAME main avant. Après le frame : roll sous le contre imaginaire → reviens en garde → recule d'un pas.",
    tip: "Le frame c'est un contrôle, pas une poussée. Main ouverte, bras tendu, replace-toi direct.",
  },
  {
    name: 'Round 5',
    duration: 180,
    color: '#ef4444',
    instruction: "JAB → CROCHET → CROSS → FRAME → JAB arrière. Après la combo : slip extérieur + 2 pas latéraux + garde haute.",
    tip: "Pousse le rythme SI la technique tient. Sinon, ralentis et fais propre.",
  },
  {
    name: 'Round 6',
    duration: 180,
    color: '#ef4444',
    instruction: "JAB → CROCHET → CROSS → FRAME → JAB arrière → UPPERCUT avant. Après l'uppercut : roll + cross de sortie + replace en garde.",
    tip: "L'uppercut part des jambes. Fléchis puis explose vers le haut. Garde l'autre main collée.",
  },
  {
    name: 'Round 7',
    duration: 180,
    color: '#dc2626',
    instruction: "Combo complète : JAB → CROCHET → CROSS → FRAME → JAB arrière → UPPERCUT avant → CROCHET avant. Après la combo : slip + roll + sors en reculant avec la garde.",
    tip: "Dernière round. Si t'es mort, fais la combo au ralenti mais propre. Lâche rien sur la technique.",
  },
]

const REST_DURATION = 60
const RADIUS = 80
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

const phase = ref('idle')
const roundIndex = ref(0)
const timeLeft = ref(0)
const extraRest = ref(0)
const totalSeconds = ref(0)
const paused = ref(false)
const warning = ref(false)
let tickInterval = null

const currentRound = computed(() => ROUNDS[roundIndex.value])
const nextRound = computed(() => ROUNDS[roundIndex.value + 1] ?? null)
const restTotal = computed(() => REST_DURATION + extraRest.value)
const phaseDuration = computed(() =>
  phase.value === 'work' ? currentRound.value.duration : restTotal.value
)
const isLastRound = computed(() => roundIndex.value === ROUNDS.length - 1)

const dashOffset = computed(() => {
  if (phase.value === 'idle' || phase.value === 'done') return 0
  return CIRCUMFERENCE * (1 - timeLeft.value / phaseDuration.value)
})

const phaseColor = computed(() =>
  phase.value === 'rest' ? '#3b82f6' : (currentRound.value?.color ?? '#ef4444')
)

function fmt(s) {
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`
}

let audioCtx = null
function getCtx() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)()
  return audioCtx
}
function beep(freq, dur, delay = 0) {
  const c = getCtx()
  const osc = c.createOscillator()
  const g = c.createGain()
  osc.connect(g)
  g.connect(c.destination)
  osc.frequency.value = freq
  osc.type = 'sine'
  const t = c.currentTime + delay
  g.gain.setValueAtTime(0.4, t)
  g.gain.exponentialRampToValueAtTime(0.001, t + dur)
  osc.start(t)
  osc.stop(t + dur + 0.01)
}
function bipStart()   { beep(880, 0.18) }
function bipEnd()     { beep(880, 0.15); beep(660, 0.25, 0.22) }
function bipWarning() { beep(660, 0.1); beep(660, 0.1, 0.16); beep(1100, 0.22, 0.34) }

let wakeLock = null
async function acquireWakeLock() {
  if ('wakeLock' in navigator) {
    try { wakeLock = await navigator.wakeLock.request('screen') } catch {}
  }
}
function releaseWakeLock() {
  if (wakeLock) { wakeLock.release(); wakeLock = null }
}

function startTick() {
  if (tickInterval) return
  tickInterval = setInterval(() => {
    totalSeconds.value++
    timeLeft.value = Math.max(0, timeLeft.value - 1)
    if (phase.value === 'work' && timeLeft.value === 3) {
      bipWarning()
      warning.value = true
    }
    if (timeLeft.value === 0) {
      warning.value = false
      advancePhase()
    }
  }, 1000)
}
function stopTick() {
  clearInterval(tickInterval)
  tickInterval = null
}

function advancePhase() {
  if (phase.value === 'work') {
    bipEnd()
    if (isLastRound.value) {
      stopTick()
      releaseWakeLock()
      phase.value = 'done'
      emit('done', totalSeconds.value)
      return
    }
    phase.value = 'rest'
    extraRest.value = 0
    timeLeft.value = REST_DURATION
  } else {
    roundIndex.value++
    phase.value = 'work'
    timeLeft.value = currentRound.value.duration
    bipStart()
  }
}

function startWorkout() {
  roundIndex.value = 0
  phase.value = 'work'
  timeLeft.value = ROUNDS[0].duration
  totalSeconds.value = 0
  paused.value = false
  warning.value = false
  acquireWakeLock()
  startTick()
  bipStart()
}

function togglePause() {
  if (paused.value) {
    paused.value = false
    startTick()
  } else {
    paused.value = true
    stopTick()
  }
}

function skipToRest() {
  if (phase.value !== 'work') return
  warning.value = false
  bipEnd()
  if (isLastRound.value) {
    stopTick()
    releaseWakeLock()
    phase.value = 'done'
    emit('done', totalSeconds.value)
    return
  }
  phase.value = 'rest'
  extraRest.value = 0
  timeLeft.value = REST_DURATION
}

function addRestTime() {
  if (phase.value !== 'rest') return
  extraRest.value += 60
  timeLeft.value += 60
}

onUnmounted(() => {
  stopTick()
  releaseWakeLock()
})
</script>

<template>
  <div
    class="boxing-timer"
    :class="{
      'phase-work': phase === 'work',
      'phase-rest': phase === 'rest',
      'is-warning': warning && !paused,
    }"
  >

    <!-- ── IDLE ── -->
    <template v-if="phase === 'idle'">
      <div class="idle-header">
        <span class="idle-num">{{ index + 1 }}</span>
        <div>
          <div class="idle-title">{{ block.name }}</div>
          <div class="idle-meta">{{ ROUNDS.length }} rounds · 3 min · 1 min repos</div>
        </div>
      </div>

      <div class="round-list">
        <div v-for="(r, i) in ROUNDS" :key="i" class="round-row">
          <span class="round-bar" :style="{ background: r.color }" />
          <div class="round-row-body">
            <span class="round-row-name">{{ r.name }}</span>
            <span class="round-row-tip">{{ r.tip }}</span>
          </div>
        </div>
      </div>

      <button class="btn-start" @click="startWorkout">
        <span>▶</span>
        <span>DÉMARRER</span>
      </button>
    </template>

    <!-- ── ACTIVE (work / rest) ── -->
    <template v-else-if="phase === 'work' || phase === 'rest'">

      <div class="dots-row">
        <span
          v-for="(r, i) in ROUNDS"
          :key="i"
          class="dot"
          :class="{
            'dot-done': i < roundIndex,
            'dot-active': i === roundIndex,
            'dot-upcoming': i > roundIndex,
          }"
          :style="i === roundIndex ? { background: phaseColor } : {}"
        />
      </div>

      <div class="phase-heading">
        <span class="phase-name" :style="{ color: phaseColor }">
          {{ phase === 'work' ? currentRound.name.toUpperCase() : 'REPOS' }}
        </span>
        <span class="phase-counter">{{ roundIndex + 1 }}&thinsp;/&thinsp;{{ ROUNDS.length }}</span>
      </div>

      <div class="ring-wrap">
        <svg viewBox="0 0 200 200" class="ring-svg" aria-hidden="true">
          <defs>
            <filter id="arc-glow" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="4" result="blur" />
              <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
            </filter>
          </defs>
          <circle class="ring-track" cx="100" cy="100" :r="RADIUS" />
          <circle
            class="ring-arc"
            cx="100" cy="100"
            :r="RADIUS"
            :stroke="phaseColor"
            :stroke-dasharray="CIRCUMFERENCE"
            :stroke-dashoffset="dashOffset"
            transform="rotate(-90 100 100)"
            filter="url(#arc-glow)"
          />
        </svg>
        <div class="ring-inner">
          <div class="ring-time" :class="{ 'time-warning': warning && !paused }">
            {{ fmt(timeLeft) }}
          </div>
          <div class="ring-label" :style="{ color: phaseColor }">
            {{ phase === 'work' ? 'WORK' : 'REST' }}
          </div>
        </div>
      </div>

      <div v-if="phase === 'work'" class="card instr-card" :style="{ '--accent': currentRound.color }">
        <p class="instr-text">{{ currentRound.instruction }}</p>
        <div class="card-tip">
          <span>💡</span>
          <span>{{ currentRound.tip }}</span>
        </div>
      </div>

      <div v-else class="card rest-card">
        <template v-if="nextRound">
          <div class="next-eyebrow">PROCHAIN</div>
          <div class="next-name" :style="{ color: nextRound.color }">{{ nextRound.name }}</div>
          <p class="next-instr">{{ nextRound.instruction }}</p>
          <div class="card-tip">
            <span>💡</span>
            <span>{{ nextRound.tip }}</span>
          </div>
        </template>
      </div>

      <div class="controls">
        <button class="ctrl ctrl-pause" @click="togglePause">
          {{ paused ? '▶ Reprendre' : '⏸ Pause' }}
        </button>
        <button v-if="phase === 'work'" class="ctrl ctrl-skip" @click="skipToRest">
          Couper le round
        </button>
        <button v-if="phase === 'rest'" class="ctrl ctrl-addrest" @click="addRestTime">
          +1 min repos
        </button>
      </div>

    </template>

    <!-- ── DONE ── -->
    <template v-else-if="phase === 'done'">
      <div class="done-screen">
        <div class="done-icon">🥊</div>
        <div class="done-title">SÉANCE TERMINÉE</div>
        <div class="done-time">{{ fmt(totalSeconds) }}</div>
        <div class="done-sub">{{ ROUNDS.length }} rounds · Bien joué</div>
      </div>
    </template>

  </div>
</template>

<style scoped>
.boxing-timer {
  background: #111827;
  border: 1px solid #1f2937;
  border-left: 3px solid var(--phase-color, #f59e0b);
  border-radius: 12px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: border-left-color 0.3s;
}
.boxing-timer.phase-work { --phase-color: #ef4444; }
.boxing-timer.phase-rest { --phase-color: #3b82f6; }
.boxing-timer.is-warning { animation: warn-pulse 0.9s ease-in-out infinite; }

@keyframes warn-pulse {
  0%, 100% { border-left-color: #ef4444; }
  50%       { border-left-color: rgba(239,68,68,0.3); }
}

/* ── IDLE ──────────────────────────────────── */
.idle-header {
  display: flex;
  align-items: center;
  gap: 10px;
}
.idle-num {
  width: 28px; height: 28px;
  background: rgba(245,158,11,0.15);
  color: #f59e0b;
  font-family: 'Barlow Condensed', sans-serif;
  font-weight: 800; font-size: 16px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.idle-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px; font-weight: 700; color: #f9fafb;
}
.idle-meta { font-size: 12px; color: #9ca3af; }

.round-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
  max-height: 240px;
  overflow-y: auto;
}
.round-list::-webkit-scrollbar { width: 3px; }
.round-list::-webkit-scrollbar-track { background: transparent; }
.round-list::-webkit-scrollbar-thumb { background: #374151; border-radius: 2px; }

.round-row {
  display: flex;
  align-items: flex-start;
  gap: 9px;
  padding: 7px 10px;
  background: #0f172a;
  border-radius: 8px;
}
.round-bar {
  width: 3px; height: 16px;
  border-radius: 2px;
  flex-shrink: 0;
  margin-top: 2px;
}
.round-row-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.round-row-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px; font-weight: 700; color: #f9fafb;
  letter-spacing: 0.5px;
}
.round-row-tip { font-size: 11px; color: #6b7280; line-height: 1.4; }

.btn-start {
  display: flex; align-items: center; justify-content: center; gap: 10px;
  width: 100%; height: 44px;
  background: #f59e0b;
  color: #0a0e17;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px; font-weight: 800; letter-spacing: 2px;
  border: none; border-radius: 10px; cursor: pointer;
  transition: transform 0.12s, background 0.15s;
}
.btn-start:active { transform: scale(0.97); background: #d97706; }

/* ── ACTIVE ────────────────────────────────── */
.dots-row {
  display: flex; gap: 5px; justify-content: center; align-items: center;
}
.dot {
  height: 6px; border-radius: 3px;
  transition: all 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.dot-done     { width: 6px; background: #374151; }
.dot-active   { width: 20px; }
.dot-upcoming { width: 6px; background: #1f2937; }

.phase-heading {
  display: flex; align-items: baseline; justify-content: center; gap: 10px;
}
.phase-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 24px; font-weight: 800; letter-spacing: 3px;
  line-height: 1;
  transition: color 0.3s;
}
.phase-counter {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px; font-weight: 600; color: #4b5563;
}

.ring-wrap {
  position: relative;
  width: 210px; height: 210px;
  margin: 0 auto;
}
.ring-svg { width: 100%; height: 100%; overflow: visible; }
.ring-track {
  fill: none;
  stroke: #1f2937;
  stroke-width: 10;
}
.ring-arc {
  fill: none;
  stroke-width: 10;
  stroke-linecap: round;
  transition: stroke-dashoffset 0.95s linear, stroke 0.3s ease;
}
.ring-inner {
  position: absolute; top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  display: flex; flex-direction: column; align-items: center; gap: 2px;
}
.ring-time {
  font-family: 'Courier New', Courier, monospace;
  font-size: 48px; font-weight: 700; color: #f9fafb;
  letter-spacing: -2px; line-height: 1;
  transition: color 0.2s;
}
.ring-time.time-warning {
  color: #ef4444;
  animation: digit-flash 0.6s ease-in-out infinite;
}
@keyframes digit-flash {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.4; }
}
.ring-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 10px; font-weight: 700; letter-spacing: 3px;
  transition: color 0.3s;
}

.card {
  border-radius: 8px;
  padding: 10px 12px;
  display: flex; flex-direction: column; gap: 8px;
}
.instr-card {
  background: #0f172a;
  border: 1px solid #1f2937;
  border-left: 3px solid var(--accent);
}
.instr-text {
  font-size: 12px; color: #d1d5db; line-height: 1.55; margin: 0;
}
.card-tip {
  display: flex; align-items: flex-start; gap: 6px;
  font-size: 12px; color: #6b7280; line-height: 1.4;
  border-top: 1px solid #1f2937; padding-top: 8px;
}

.rest-card {
  background: rgba(59,130,246,0.05);
  border: 1px solid rgba(59,130,246,0.15);
}
.next-eyebrow {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 10px; font-weight: 700; letter-spacing: 3px; color: #4b5563;
}
.next-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px; font-weight: 800; letter-spacing: 1px; line-height: 1.1;
}
.next-instr { font-size: 12px; color: #9ca3af; line-height: 1.5; margin: 0; }

.controls {
  display: grid; grid-template-columns: 1fr 1fr; gap: 8px;
}
.ctrl {
  height: 44px; border-radius: 10px; border: none;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px; font-weight: 700;
  cursor: pointer; transition: transform 0.1s;
}
.ctrl:active { transform: scale(0.96); }
.ctrl-pause   { background: #1f2937; color: #9ca3af; font-size: 16px; }
.ctrl-skip    { background: rgba(239,68,68,0.12); color: #ef4444; }
.ctrl-addrest { background: rgba(59,130,246,0.12); color: #60a5fa; }

/* ── DONE ──────────────────────────────────── */
.done-screen {
  display: flex; flex-direction: column; align-items: center; gap: 8px;
  padding: 24px 0 12px;
}
.done-icon  { font-size: 52px; line-height: 1; }
.done-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 28px; font-weight: 800; letter-spacing: 3px; color: #f9fafb;
}
.done-time {
  font-family: 'Courier New', Courier, monospace;
  font-size: 40px; font-weight: 700; color: #f59e0b; letter-spacing: -1px;
}
.done-sub { font-size: 13px; color: #6b7280; }
</style>
