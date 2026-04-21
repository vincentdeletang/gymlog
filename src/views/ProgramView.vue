<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useProgramStore } from '@/stores/useProgramStore'

const programStore = useProgramStore()

onMounted(() => {
  if (!programStore.activeProgram) programStore.fetchActiveProgram()
})

const DAYS_SHORT = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
const DAYS_FULL  = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
const todayDow   = new Date().getDay()

const sortedDays = computed(() =>
  [...programStore.programDays].sort((a, b) => {
    const order = [1, 2, 3, 4, 5, 6, 0]
    return order.indexOf(a.day_of_week) - order.indexOf(b.day_of_week)
  })
)

const selectedDayId = ref(null)

watch(sortedDays, days => {
  if (days.length && !selectedDayId.value) {
    const today = days.find(d => d.day_of_week === todayDow)
    selectedDayId.value = today?.id ?? days[0]?.id ?? null
  }
}, { immediate: true })

const selectedDay = computed(() =>
  programStore.programDays.find(d => d.id === selectedDayId.value) ?? null
)

const selectedExercises = computed(() =>
  selectedDay.value ? programStore.getExercisesForDay(selectedDay.value.id) : []
)

const selectedCardio = computed(() =>
  selectedDay.value ? programStore.getCardioBlocksForDay(selectedDay.value.id) : []
)

const sections = computed(() => {
  const exs = selectedExercises.value
  return [
    { key: 'rehab',    label: '🔧 PRÉVENTION', sub: 'Avant séance', color: '#f59e0b', items: exs.filter(e => e.section === 'rehab') },
    { key: 'main',     label: '⚡ MUSCU',       sub: null,           color: '#3b82f6', items: exs.filter(e => e.section === 'main') },
    { key: 'cooldown', label: '🧘 RÉCUP',       sub: 'Après séance', color: '#8b5cf6', items: exs.filter(e => e.section === 'cooldown') },
    { key: 'mobility', label: '🌿 MOBILITÉ',   sub: null,           color: '#06b6d4', items: exs.filter(e => e.section === 'mobility') },
  ].filter(s => s.items.length > 0)
})

const weeklyStats = computed(() => ({
  trainingDays:  programStore.programDays.filter(d => d.type !== 'rest').length,
  totalSets:     programStore.exercises.reduce((s, e) => s + e.sets_target, 0),
  totalCardioMin: programStore.cardioBlocks.reduce((s, b) => s + b.duration_minutes, 0),
  totalXP:       programStore.programDays.reduce((s, d) => s + (d.xp_reward ?? 0), 0),
}))

const maxDayVolume = computed(() =>
  Math.max(...programStore.programDays.map(d =>
    programStore.getExercisesForDay(d.id).reduce((s, e) => s + e.sets_target, 0)
  ), 1)
)

function dayVolumePct(dayId) {
  const vol = programStore.getExercisesForDay(dayId).reduce((s, e) => s + e.sets_target, 0)
  return Math.round((vol / maxDayVolume.value) * 100)
}

const TYPE_COLOR = { strength: '#3b82f6', cardio: '#f59e0b', rest: '#374151' }
const TYPE_ICON  = { strength: '💪', cardio: '🏃', rest: '😴' }
</script>

<template>
  <div class="program-view">

    <div class="view-header">
      <h1>Programme</h1>
      <div v-if="programStore.activeProgram" class="prog-name">
        {{ programStore.activeProgram.name }}
      </div>
    </div>

    <div v-if="programStore.loading" class="loading">
      <div class="spinner" />
    </div>

    <template v-else-if="programStore.activeProgram">

      <!-- Weekly stats -->
      <div class="stats-row">
        <div class="stat">
          <span class="stat-val">{{ weeklyStats.trainingDays }}</span>
          <span class="stat-lbl">jours</span>
        </div>
        <div class="stat-div" />
        <div class="stat">
          <span class="stat-val">{{ weeklyStats.totalSets }}</span>
          <span class="stat-lbl">séries</span>
        </div>
        <div class="stat-div" />
        <div class="stat">
          <span class="stat-val">{{ weeklyStats.totalCardioMin }}</span>
          <span class="stat-lbl">min cardio</span>
        </div>
        <div class="stat-div" />
        <div class="stat">
          <span class="stat-val">{{ weeklyStats.totalXP }}</span>
          <span class="stat-lbl">XP / sem</span>
        </div>
      </div>

      <!-- Week strip -->
      <div class="week-strip">
        <button
          v-for="day in sortedDays"
          :key="day.id"
          class="day-pill"
          :class="{
            'pill-today':    day.day_of_week === todayDow,
            'pill-selected': day.id === selectedDayId,
            [`pill-${day.type}`]: true,
          }"
          @click="selectedDayId = day.id"
        >
          <span class="pill-abbr">{{ DAYS_SHORT[day.day_of_week] }}</span>
          <span class="pill-icon">{{ TYPE_ICON[day.type] }}</span>
          <div class="pill-vol">
            <div
              class="pill-vol-fill"
              :style="{
                width: day.type === 'strength' ? dayVolumePct(day.id) + '%'
                     : day.type === 'cardio'   ? '60%'
                     :                           '0%',
                background: TYPE_COLOR[day.type],
              }"
            />
          </div>
        </button>
      </div>

      <!-- Day detail -->
      <Transition name="day-fade" mode="out-in">
        <div v-if="selectedDay" :key="selectedDayId" class="day-detail">

          <!-- Day header -->
          <div class="detail-head" :style="{ '--type-color': TYPE_COLOR[selectedDay.type] }">
            <div class="detail-left">
              <div class="detail-dayname">{{ DAYS_FULL[selectedDay.day_of_week] }}</div>
              <div class="detail-session">{{ selectedDay.name }}</div>
            </div>
            <div class="detail-right">
              <span class="type-badge" :style="{ color: TYPE_COLOR[selectedDay.type], borderColor: TYPE_COLOR[selectedDay.type] + '40' }">
                {{ TYPE_ICON[selectedDay.type] }} {{ selectedDay.type === 'strength' ? 'Muscu' : selectedDay.type === 'cardio' ? 'Cardio' : 'Repos' }}
              </span>
              <span v-if="selectedDay.xp_reward" class="xp-tag">+{{ selectedDay.xp_reward }} XP</span>
            </div>
          </div>

          <!-- Rest complet -->
          <div v-if="selectedDay.type === 'rest' && !sections.length && !selectedCardio.length" class="rest-msg">
            <span class="rest-icon">😴</span>
            <span>Repos complet — récupération = progression</span>
          </div>

          <!-- Exercise sections -->
          <div v-for="section in sections" :key="section.key" class="section-block">
            <div class="section-head" :style="{ color: section.color }">
              {{ section.label }}
              <span v-if="section.sub" class="section-sub">· {{ section.sub }}</span>
            </div>
            <div class="ex-list">
              <div v-for="ex in section.items" :key="ex.id" class="ex-row">
                <div class="ex-line">
                  <span class="ex-name">{{ ex.name }}</span>
                  <span class="ex-sets">{{ ex.sets_target }}×{{ ex.reps_target }}</span>
                </div>
                <div v-if="ex.notes" class="ex-notes">{{ ex.notes }}</div>
              </div>
            </div>
          </div>

          <!-- Cardio blocks -->
          <div v-if="selectedCardio.length" class="section-block">
            <div class="section-head" style="color: #10b981">🏃 CARDIO</div>
            <div class="ex-list">
              <div v-for="cb in selectedCardio" :key="cb.id" class="ex-row">
                <div class="ex-line">
                  <span class="ex-name">{{ cb.name }}</span>
                  <span class="ex-sets cardio-dur">{{ cb.duration_minutes }} min</span>
                </div>
                <div v-if="cb.notes" class="ex-notes">{{ cb.notes }}</div>
              </div>
            </div>
          </div>

        </div>
      </Transition>

    </template>

    <div v-else class="empty-state">Aucun programme actif.</div>

    <div style="height: 80px" />
  </div>
</template>

<style scoped>
.program-view {
  padding-bottom: 80px;
  min-height: 100vh;
}

/* ── Header ─────────────────────────────── */
.view-header {
  padding: 8px 16px 12px;
}

.view-header h1 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 28px;
  font-weight: 800;
  color: #f9fafb;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.prog-name {
  font-size: 13px;
  color: #6b7280;
  margin-top: 2px;
}

/* ── Loading / empty ────────────────────── */
.loading {
  display: flex;
  justify-content: center;
  padding: 48px;
}

.spinner {
  width: 28px; height: 28px;
  border: 3px solid #1f2937;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.empty-state {
  text-align: center;
  padding: 48px;
  color: #6b7280;
  font-size: 14px;
}

/* ── Weekly stats ───────────────────────── */
.stats-row {
  display: flex;
  align-items: center;
  justify-content: space-around;
  margin: 0 16px 14px;
  padding: 12px 0;
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 12px;
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.stat-val {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 800;
  color: #f9fafb;
  line-height: 1;
}

.stat-lbl {
  font-size: 10px;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-div {
  width: 1px;
  height: 28px;
  background: #1f2937;
}

/* ── Week strip ─────────────────────────── */
.week-strip {
  display: flex;
  gap: 4px;
  padding: 0 16px;
  margin-bottom: 14px;
}

.day-pill {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px 4px 0;
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.15s;
  position: relative;
  overflow: hidden;
  min-width: 0;
}

.day-pill:active { transform: scale(0.95); }

.pill-today {
  border-color: rgba(245,158,11,0.5);
  box-shadow: 0 0 0 1px rgba(245,158,11,0.2);
}

.pill-selected.pill-strength { background: rgba(59,130,246,0.12); border-color: rgba(59,130,246,0.4); }
.pill-selected.pill-cardio   { background: rgba(245,158,11,0.12); border-color: rgba(245,158,11,0.4); }
.pill-selected.pill-rest     { background: rgba(55,65,81,0.3);    border-color: #374151; }

.pill-abbr {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.pill-selected .pill-abbr { color: #f9fafb; }
.pill-today    .pill-abbr { color: #f59e0b; }

.pill-icon {
  font-size: 16px;
  line-height: 1;
}

.pill-vol {
  width: 100%;
  height: 3px;
  background: #1f2937;
  border-radius: 0 0 8px 8px;
  overflow: hidden;
}

.pill-vol-fill {
  height: 100%;
  border-radius: inherit;
  transition: width 0.4s ease, opacity 0.3s;
  opacity: 0.5;
}

.pill-selected .pill-vol-fill { opacity: 1; }

/* ── Day detail ─────────────────────────── */
.day-detail {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 0 16px;
}

.detail-head {
  background: #111827;
  border: 1px solid #1f2937;
  border-left: 3px solid var(--type-color);
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.detail-dayname {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 800;
  color: #f9fafb;
  text-transform: uppercase;
  letter-spacing: 1px;
  line-height: 1;
}

.detail-session {
  font-size: 12px;
  color: #6b7280;
  margin-top: 3px;
}

.detail-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  flex-shrink: 0;
}

.type-badge {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 700;
  border: 1px solid;
  padding: 2px 8px;
  border-radius: 20px;
  letter-spacing: 0.5px;
}

.xp-tag {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 700;
  color: #f59e0b;
}

.rest-msg {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 24px 16px;
  color: #6b7280;
  font-size: 14px;
}

.rest-icon { font-size: 28px; }

/* ── Sections ───────────────────────────── */
.section-block {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 12px;
  overflow: hidden;
}

.section-head {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  padding: 8px 14px 6px;
  border-bottom: 1px solid #1f2937;
  display: flex;
  align-items: center;
  gap: 6px;
}

.section-sub {
  font-weight: 500;
  color: #4b5563;
  letter-spacing: 0;
  text-transform: none;
  font-size: 11px;
}

.ex-list {
  display: flex;
  flex-direction: column;
}

.ex-row {
  padding: 9px 14px;
  border-bottom: 1px solid #1a2234;
}

.ex-row:last-child { border-bottom: none; }

.ex-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.ex-name {
  font-size: 13px;
  color: #e5e7eb;
  flex: 1;
  min-width: 0;
}

.ex-sets {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  flex-shrink: 0;
}

.cardio-dur { color: #f59e0b; }

.ex-notes {
  font-size: 11px;
  color: #4b5563;
  line-height: 1.4;
  margin-top: 3px;
}

/* ── Transition ─────────────────────────── */
.day-fade-enter-active { transition: opacity 0.18s, transform 0.18s; }
.day-fade-leave-active { transition: opacity 0.12s; }
.day-fade-enter-from  { opacity: 0; transform: translateY(6px); }
.day-fade-leave-to    { opacity: 0; }
</style>
