<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { todayISO, formatLongDate } from '@/lib/formatDate'

const router = useRouter()
const workoutStore = useWorkoutStore()

const sessions = ref([])
const selectedSession = ref(null)
const sessionDetail = ref([])
const sessionCardio = ref([])
const loadingDetail = ref(false)
const missedDate = ref('')

onMounted(async () => {
  sessions.value = await workoutStore.fetchHistory(40)
})

function onMissedDateChange(value) {
  if (!value) return
  router.push(`/today/${value}`)
}

function editSession() {
  if (!selectedSession.value?.session_date) return
  router.push(`/today/${selectedSession.value.session_date}`)
}

const grouped = computed(() => {
  const now = new Date()
  const groups = []

  const getWeekLabel = (dateStr) => {
    const d = new Date(dateStr)
    const diffDays = Math.floor((now - d) / (1000 * 60 * 60 * 24))
    const diffWeeks = Math.floor(diffDays / 7)

    const mondayOfD = new Date(d)
    mondayOfD.setDate(d.getDate() - ((d.getDay() + 6) % 7))

    const mondayOfNow = new Date(now)
    mondayOfNow.setDate(now.getDate() - ((now.getDay() + 6) % 7))

    const weekDiff = Math.round((mondayOfNow - mondayOfD) / (7 * 24 * 60 * 60 * 1000))

    if (weekDiff === 0) return 'Cette semaine'
    if (weekDiff === 1) return 'Semaine dernière'
    return `Il y a ${weekDiff} semaines`
  }

  const groupMap = new Map()
  for (const s of sessions.value) {
    const label = getWeekLabel(s.session_date)
    if (!groupMap.has(label)) groupMap.set(label, [])
    groupMap.get(label).push(s)
  }

  for (const [label, items] of groupMap) {
    groups.push({ label, items })
  }
  return groups
})

async function openDetail(session) {
  selectedSession.value = session
  loadingDetail.value = true
  const [detail, cardio] = await Promise.all([
    workoutStore.fetchSessionDetail(session.id),
    workoutStore.fetchSessionCardio(session),
  ])
  sessionDetail.value = detail
  sessionCardio.value = cardio
  loadingDetail.value = false
}

function displayWeight(log) {
  if (!log.weight_kg) return null
  return log.weight_kg + (log.exercises?.bars?.weight_kg ?? 0)
}

function formatDate(dateStr) {
  return formatLongDate(dateStr)
}

const TYPE_ICON = { strength: '💪', cardio: '🏃', rest: '😴' }

const groupedDetail = computed(() => {
  const sections = {}
  for (const log of sessionDetail.value) {
    const section = log.exercises?.section ?? 'main'
    if (!sections[section]) sections[section] = []
    sections[section].push(log)
  }
  return sections
})

// Aggregate stats over the loaded detail (main-section weighted work + RIR + duration).
const detailStats = computed(() => {
  const logs = sessionDetail.value
  if (!logs.length) return null
  let tonnage = 0, rirSum = 0, rirCount = 0, firstAt = null, lastAt = null
  for (const log of logs) {
    const isMain = (log.exercises?.section ?? 'main') === 'main'
    const tare = log.exercises?.bars?.weight_kg ?? 0
    if (isMain && log.weight_kg != null && log.reps_done != null) {
      tonnage += (log.weight_kg + tare) * log.reps_done
    }
    if (isMain && log.rir != null) {
      rirSum += log.rir
      rirCount++
    }
    if (log.logged_at) {
      const t = new Date(log.logged_at).getTime()
      if (firstAt == null || t < firstAt) firstAt = t
      if (lastAt  == null || t > lastAt)  lastAt = t
    }
  }
  return {
    setsDone: logs.length,
    tonnage: Math.round(tonnage),
    avgRir: rirCount > 0 ? Math.round((rirSum / rirCount) * 10) / 10 : null,
    durationSec: firstAt && lastAt ? Math.round((lastAt - firstAt) / 1000) : null,
  }
})

function durationLabel(s) {
  if (!s) return null
  const m = Math.floor(s / 60)
  return m < 60 ? `${m} min` : `${Math.floor(m / 60)}h${String(m % 60).padStart(2, '0')}`
}

const SECTION_LABELS = {
  rehab: 'PRÉVENTION',
  main: 'MUSCU',
  cooldown: 'RÉCUP',
  mobility: 'MOBILITÉ',
  cardio: 'CARDIO',
}
</script>

<template>
  <div class="history-view">
    <div class="view-header">
      <h1>Historique</h1>
    </div>

    <div v-if="!selectedSession">
      <div class="add-missed-zone">
        <label class="add-missed-label">📆 Logger une séance passée</label>
        <input
          type="date"
          :max="todayISO()"
          v-model="missedDate"
          @change="onMissedDateChange(missedDate)"
          class="add-missed-input"
        />
      </div>

      <div v-for="group in grouped" :key="group.label" class="week-group">
        <div class="week-label">{{ group.label }}</div>
        <div
          v-for="session in group.items"
          :key="session.id"
          class="session-item"
          @click="openDetail(session)"
        >
          <div class="session-left">
            <span class="session-icon">{{ TYPE_ICON[session.program_days?.type] ?? '📋' }}</span>
            <div class="session-info">
              <div class="session-name">{{ session.program_days?.name ?? 'Séance' }}</div>
              <div class="session-date">{{ formatDate(session.session_date) }}</div>
            </div>
          </div>
          <div class="session-status">
            <span v-if="session.completed" class="badge complete">✓</span>
            <span v-else class="badge abandoned">–</span>
            <span v-if="session.program_days?.xp_reward" class="xp-label">
              +{{ session.program_days.xp_reward }} XP
            </span>
          </div>
        </div>
      </div>

      <div v-if="!sessions.length" class="empty-state">
        <div class="empty-icon">📋</div>
        <p>Aucune séance encore.</p>
        <p>Lance ta première séance depuis "Aujourd'hui" !</p>
      </div>
    </div>

    <!-- Session detail -->
    <div v-else class="session-detail">
      <div class="detail-toolbar">
        <button class="back-btn" @click="selectedSession = null">← Retour</button>
        <button class="edit-session-btn" @click="editSession">✏️ Modifier</button>
      </div>

      <div class="detail-header">
        <h2>{{ selectedSession.program_days?.name }}</h2>
        <div class="detail-meta">
          {{ formatDate(selectedSession.session_date) }}
          <span :class="selectedSession.completed ? 'chip-done' : 'chip-abandoned'">
            {{ selectedSession.completed ? 'Terminée' : 'Abandonnée' }}
          </span>
        </div>

        <div v-if="detailStats" class="detail-stats">
          <div v-if="detailStats.tonnage > 0" class="ds-cell">
            <span class="ds-val">{{ detailStats.tonnage.toLocaleString('fr-FR') }}</span>
            <span class="ds-lbl">kg</span>
          </div>
          <div class="ds-cell">
            <span class="ds-val">{{ detailStats.setsDone }}</span>
            <span class="ds-lbl">séries</span>
          </div>
          <div v-if="detailStats.avgRir != null" class="ds-cell">
            <span class="ds-val">{{ detailStats.avgRir }}</span>
            <span class="ds-lbl">RIR moy.</span>
          </div>
          <div v-if="detailStats.durationSec" class="ds-cell">
            <span class="ds-val">{{ durationLabel(detailStats.durationSec) }}</span>
            <span class="ds-lbl">durée</span>
          </div>
        </div>

        <div v-if="selectedSession.notes" class="detail-notes">
          📝 {{ selectedSession.notes }}
        </div>
      </div>

      <div v-if="loadingDetail" class="loading">
        <div class="spinner" />
      </div>

      <div v-else>
        <div
          v-for="(logs, section) in groupedDetail"
          :key="section"
          class="detail-section"
        >
          <div class="detail-section-label">{{ SECTION_LABELS[section] ?? section.toUpperCase() }}</div>
          <div
            v-for="log in logs"
            :key="log.id"
            class="log-row"
          >
            <span class="log-name">{{ log.exercises?.name }}</span>
            <div class="log-data">
              <span v-if="log.weight_kg" class="log-weight">{{ displayWeight(log) }}kg</span>
              <span class="log-reps">{{ log.reps_done }} reps</span>
              <span class="log-rir" v-if="log.rir != null">RIR {{ log.rir }}</span>
              <span class="log-set">S{{ log.set_number }}</span>
            </div>
          </div>
          <div v-if="!logs.length" class="empty-section">—</div>
        </div>

        <div
          v-if="sessionCardio.length"
          class="detail-section"
        >
          <div class="detail-section-label">CARDIO</div>
          <div
            v-for="block in sessionCardio"
            :key="block.id"
            class="log-row cardio-row"
            :class="{ done: block.completed }"
          >
            <span class="log-name">{{ block.name }}</span>
            <div class="log-data">
              <span v-if="block.duration_seconds" class="cardio-duration">
                {{ Math.round(block.duration_seconds / 60) }} min
                <span class="cardio-target">/ {{ block.duration_minutes }}</span>
              </span>
              <span v-else class="cardio-duration cardio-target">{{ block.duration_minutes }} min</span>
              <span v-if="block.avg_hr" class="cardio-hr">{{ block.avg_hr }} bpm</span>
              <span :class="block.completed ? 'cardio-check' : 'cardio-miss'">
                {{ block.completed ? '✓ Fait' : '– Non loggé' }}
              </span>
            </div>
          </div>
        </div>

        <div v-if="!sessionDetail.length && !sessionCardio.length" class="empty-state">
          Aucune activité enregistrée pour cette séance.
        </div>
      </div>
    </div>

    <div style="height: 80px" />
  </div>
</template>

<style scoped>
.history-view { padding: 0 0 80px; }

.view-header {
  padding: 16px 16px 8px;
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

.add-missed-zone {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 10px 16px 14px;
  border-bottom: 1px solid #111827;
  margin-bottom: 8px;
}

.add-missed-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 0.5px;
}

.add-missed-input {
  background: #1f2937;
  border: 1px solid #374151;
  border-radius: 8px;
  color: #f9fafb;
  font-size: 13px;
  font-weight: 600;
  padding: 6px 10px;
  outline: none;
  cursor: pointer;
  font-family: inherit;
}

.add-missed-input:focus { border-color: #3b82f6; }

.week-group { margin-bottom: 16px; }

.week-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #6b7280;
  letter-spacing: 1px;
  text-transform: uppercase;
  padding: 4px 16px 8px;
}

.session-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid #111827;
  cursor: pointer;
  transition: background 0.1s;
}

.session-item:active { background: #111827; }

.session-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.session-icon { font-size: 22px; }

.session-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 700;
  color: #f9fafb;
}

.session-date {
  font-size: 12px;
  color: #9ca3af;
  text-transform: capitalize;
}

.session-status {
  display: flex;
  align-items: center;
  gap: 8px;
}

.badge {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
}

.badge.complete  { background: rgba(16,185,129,0.15); color: #10b981; }
.badge.abandoned { background: rgba(107,114,128,0.15); color: #9ca3af; }

.xp-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  color: #f59e0b;
  font-weight: 700;
}

.empty-state {
  text-align: center;
  padding: 48px 24px;
  color: #6b7280;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.empty-icon { font-size: 40px; }

/* Detail */
.session-detail { padding: 0 16px; }

.detail-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.back-btn {
  background: transparent;
  border: none;
  color: #3b82f6;
  font-size: 15px;
  font-weight: 600;
  padding: 12px 0;
  cursor: pointer;
}

.edit-session-btn {
  background: rgba(59,130,246,0.1);
  border: 1px solid rgba(59,130,246,0.3);
  border-radius: 8px;
  color: #60a5fa;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.5px;
  padding: 6px 12px;
  cursor: pointer;
  transition: background 0.15s;
}

.edit-session-btn:active {
  background: rgba(59,130,246,0.2);
}

.detail-header {
  margin-bottom: 16px;
}

.detail-header h2 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 700;
  color: #f9fafb;
  margin: 0 0 4px;
}

.detail-meta {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: #9ca3af;
  text-transform: capitalize;
}

.chip-done    { background: rgba(16,185,129,0.1); color: #10b981; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 700; }
.chip-abandoned { background: rgba(107,114,128,0.1); color: #9ca3af; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 700; }

.detail-stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  margin-top: 10px;
}

.ds-cell {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 8px;
  padding: 6px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1px;
  min-width: 0;
}

.ds-val {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 800;
  color: #f9fafb;
  line-height: 1;
  letter-spacing: 0.3px;
}

.ds-lbl {
  font-size: 10px;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.4px;
  font-weight: 600;
}

.detail-notes {
  margin-top: 10px;
  background: rgba(59,130,246,0.05);
  border: 1px solid rgba(59,130,246,0.15);
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #cbd5e1;
  line-height: 1.5;
  white-space: pre-wrap;
}

.loading {
  display: flex;
  justify-content: center;
  padding: 24px;
}

.spinner {
  width: 28px;
  height: 28px;
  border: 3px solid #1f2937;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.detail-section { margin-bottom: 16px; }

.detail-section-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 11px;
  font-weight: 800;
  color: #6b7280;
  letter-spacing: 1.5px;
  margin-bottom: 6px;
}

.log-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  background: #111827;
  border-radius: 8px;
  margin-bottom: 4px;
}

.log-name {
  font-size: 14px;
  color: #f9fafb;
  font-weight: 600;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-right: 8px;
}

.log-data {
  display: flex;
  gap: 6px;
  align-items: center;
  flex-shrink: 0;
}

.log-weight { font-family: 'Barlow Condensed', sans-serif; font-size: 15px; font-weight: 700; color: #60a5fa; }
.log-reps   { font-family: 'Barlow Condensed', sans-serif; font-size: 15px; font-weight: 700; color: #f9fafb; }
.log-rir    { font-size: 11px; color: #9ca3af; }
.log-set    { font-size: 11px; color: #6b7280; background: #1f2937; padding: 2px 6px; border-radius: 4px; }

.cardio-row.done { border-left: 3px solid #10b981; }
.cardio-duration { font-family: 'Barlow Condensed', sans-serif; font-size: 14px; font-weight: 700; color: #f59e0b; }
.cardio-target { color: #6b7280; font-weight: 500; font-size: 12px; }
.cardio-hr { font-family: 'Barlow Condensed', sans-serif; font-size: 13px; font-weight: 700; color: #ef4444; background: rgba(239,68,68,0.1); padding: 1px 6px; border-radius: 6px; }
.cardio-check { font-size: 12px; font-weight: 700; color: #10b981; background: rgba(16,185,129,0.1); padding: 2px 8px; border-radius: 10px; }
.cardio-miss  { font-size: 12px; font-weight: 700; color: #6b7280; background: rgba(107,114,128,0.1); padding: 2px 8px; border-radius: 10px; }

.empty-section { color: #4b5563; font-size: 13px; padding: 4px 12px; }
</style>
