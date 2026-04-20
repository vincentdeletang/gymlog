<script setup>
import { ref, computed, onMounted } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'

const workoutStore = useWorkoutStore()

const sessions = ref([])
const selectedSession = ref(null)
const sessionDetail = ref([])
const loadingDetail = ref(false)

onMounted(async () => {
  sessions.value = await workoutStore.fetchHistory(40)
})

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
  sessionDetail.value = await workoutStore.fetchSessionDetail(session.id)
  loadingDetail.value = false
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return d.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' })
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
</script>

<template>
  <div class="history-view">
    <div class="view-header">
      <h1>Historique</h1>
    </div>

    <div v-if="!selectedSession">
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
      <button class="back-btn" @click="selectedSession = null">← Retour</button>

      <div class="detail-header">
        <h2>{{ selectedSession.program_days?.name }}</h2>
        <div class="detail-meta">
          {{ formatDate(selectedSession.session_date) }}
          <span :class="selectedSession.completed ? 'chip-done' : 'chip-abandoned'">
            {{ selectedSession.completed ? 'Terminée' : 'Abandonnée' }}
          </span>
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
          <div class="detail-section-label">{{ section.toUpperCase() }}</div>
          <div
            v-for="log in logs"
            :key="log.id"
            class="log-row"
          >
            <span class="log-name">{{ log.exercises?.name }}</span>
            <div class="log-data">
              <span v-if="log.weight_kg" class="log-weight">{{ log.weight_kg }}kg</span>
              <span class="log-reps">{{ log.reps_done }} reps</span>
              <span class="log-rir" v-if="log.rir != null">RIR {{ log.rir }}</span>
              <span class="log-set">S{{ log.set_number }}</span>
            </div>
          </div>
          <div v-if="!logs.length" class="empty-section">—</div>
        </div>

        <div v-if="!sessionDetail.length" class="empty-state">
          Aucun set enregistré pour cette séance.
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

.back-btn {
  background: transparent;
  border: none;
  color: #3b82f6;
  font-size: 15px;
  font-weight: 600;
  padding: 12px 0;
  cursor: pointer;
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

.empty-section { color: #4b5563; font-size: 13px; padding: 4px 12px; }
</style>
