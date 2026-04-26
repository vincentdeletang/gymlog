<script setup>
import { ref, computed, onMounted } from 'vue'
import WeekCalendar from '@/components/stats/WeekCalendar.vue'
import StatCard from '@/components/stats/StatCard.vue'
import ProgressChart from '@/components/stats/ProgressChart.vue'
import BodyweightCard from '@/components/stats/BodyweightCard.vue'
import WeeklyVolumeByMuscle from '@/components/stats/WeeklyVolumeByMuscle.vue'
import DeloadAlert from '@/components/stats/DeloadAlert.vue'
import { useUserStore } from '@/stores/useUserStore'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { useProgramStore } from '@/stores/useProgramStore'

const userStore = useUserStore()
const workoutStore = useWorkoutStore()
const programStore = useProgramStore()

const recentSessions = ref([])
const weeklyData = ref([])
const selectedExercise = ref('')
const loadingChart = ref(false)
const chartData = ref({ labels: [], values: [], exerciseName: '' })

const exercisesForChart = computed(() =>
  programStore.exercises.filter(e => !e.is_bodyweight && e.section !== 'rehab')
)

onMounted(async () => {
  if (!programStore.exercises.length) await programStore.fetchActiveProgram()
  recentSessions.value = await workoutStore.fetchHistory(30)
  weeklyData.value = await workoutStore.fetchWeeklyVolume(8)
})

async function loadWeightData() {
  if (!selectedExercise.value) return
  loadingChart.value = true

  const raw = await workoutStore.fetchWeightProgress(selectedExercise.value, 16)
  const ex = programStore.exercises.find(e => e.id === selectedExercise.value)
  const tare = ex?.bars?.weight_kg ?? 0

  const byDate = {}
  for (const log of raw) {
    const date = log.workout_sessions?.session_date
    if (!date || !log.weight_kg) continue
    const total = log.weight_kg + tare
    if (!byDate[date] || total > byDate[date]) byDate[date] = total
  }

  const sortedDates = Object.keys(byDate).sort()
  chartData.value = {
    labels: sortedDates.map(d =>
      new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
    ),
    values: sortedDates.map(d => byDate[d]),
    exerciseName: ex?.name ?? '',
  }

  loadingChart.value = false
}

const totalSessions = computed(() => recentSessions.value.filter(s => s.completed).length)

// Weekly volume chart
const weeklyChartData = computed(() => {
  const weeks = {}
  for (const s of weeklyData.value) {
    if (!s.completed) continue
    const d = new Date(s.session_date)
    const weekKey = getWeekStart(d)
    weeks[weekKey] = (weeks[weekKey] ?? 0) + 1
  }
  const labels = Object.keys(weeks).sort().slice(-8).map(k => {
    const d = new Date(k)
    return `S${getWeekNumber(d)}`
  })
  const data = Object.keys(weeks).sort().slice(-8).map(k => weeks[k])
  return { labels, data }
})

// Session type distribution
const typeDistribution = computed(() => {
  const types = { strength: 0, cardio: 0, rest: 0 }
  for (const s of recentSessions.value) {
    if (!s.completed) continue
    const t = s.program_days?.type ?? 'strength'
    types[t] = (types[t] ?? 0) + 1
  }
  return types
})

function getWeekStart(d) {
  const dt = new Date(d)
  const day = dt.getDay()
  const diff = dt.getDate() - day + (day === 0 ? -6 : 1)
  dt.setDate(diff)
  return dt.toISOString().slice(0, 10)
}

function getWeekNumber(d) {
  const onejan = new Date(d.getFullYear(), 0, 1)
  return Math.ceil((((d - onejan) / 86400000) + onejan.getDay() + 1) / 7)
}
</script>

<template>
  <div class="stats-view">
    <div class="view-header">
      <h1>Progression</h1>
    </div>

    <!-- Deload alert (renders only if signals trigger) -->
    <div class="section-block">
      <DeloadAlert />
    </div>

    <!-- Week calendar -->
    <div class="section-block">
      <div class="block-title">Cette semaine</div>
      <WeekCalendar :sessions="recentSessions" />
    </div>

    <!-- Bodyweight tracking -->
    <div class="section-block">
      <BodyweightCard />
    </div>

    <!-- Global stats -->
    <div class="section-block">
      <div class="block-title">Stats globales</div>
      <div class="stats-grid">
        <StatCard label="Séances" :value="totalSessions" icon="📋" color="#3b82f6" />
        <StatCard label="Meilleur streak" :value="userStore.streakBest" icon="🔥" color="#f59e0b" />
        <StatCard label="XP total" :value="userStore.xp" icon="⚡" color="#8b5cf6" />
        <StatCard label="Niveau" :value="userStore.currentLevel.name" icon="🏆" color="#10b981" />
      </div>
    </div>

    <!-- Weekly volume per muscle group -->
    <div class="section-block">
      <WeeklyVolumeByMuscle />
    </div>

    <!-- Weekly volume chart (sessions count over time) -->
    <div class="section-block" v-if="weeklyChartData.labels.length">
      <div class="block-title">Séances / semaine</div>
      <ProgressChart
        type="bar"
        :labels="weeklyChartData.labels"
        :datasets="[{
          label: 'Séances',
          data: weeklyChartData.data,
          backgroundColor: 'rgba(59,130,246,0.6)',
          borderColor: '#3b82f6',
          borderWidth: 1,
          borderRadius: 4,
        }]"
      />
    </div>

    <!-- Weight progression per exercise -->
    <div class="section-block">
      <div class="block-title">Progression par exercice</div>
      <select v-model="selectedExercise" class="ex-select" @change="loadWeightData">
        <option value="">Choisir un exercice…</option>
        <option v-for="ex in exercisesForChart" :key="ex.id" :value="ex.id">
          {{ ex.name }}
        </option>
      </select>
      <div v-if="loadingChart" class="chart-loading">
        <div class="spinner" />
      </div>
      <ProgressChart
        v-else-if="chartData.labels.length > 1"
        type="line"
        :labels="chartData.labels"
        :datasets="[{
          label: chartData.exerciseName,
          data: chartData.values,
          borderColor: '#3b82f6',
          backgroundColor: 'rgba(59,130,246,0.08)',
          tension: 0.3,
          fill: true,
          pointBackgroundColor: '#3b82f6',
          pointRadius: 4,
          pointHoverRadius: 6,
        }]"
      />
      <div v-else-if="selectedExercise && !loadingChart" class="chart-empty">
        Pas encore assez de données — reviens après 2 séances.
      </div>
    </div>

    <!-- Session type donut -->
    <div class="section-block" v-if="Object.values(typeDistribution).some(v => v > 0)">
      <div class="block-title">Répartition des séances</div>
      <ProgressChart
        type="doughnut"
        :labels="['Muscu', 'Cardio', 'Repos']"
        :datasets="[{
          data: [typeDistribution.strength, typeDistribution.cardio, typeDistribution.rest],
          backgroundColor: ['#3b82f6', '#f59e0b', '#374151'],
          borderWidth: 0,
        }]"
      />
    </div>

    <!-- Empty state -->
    <div v-if="!recentSessions.length" class="empty-state">
      <div class="empty-icon">📊</div>
      <p>Commence à t'entraîner pour voir tes stats ici.</p>
    </div>

    <div style="height: 80px" />
  </div>
</template>

<style scoped>
.stats-view { padding: 0 0 80px; }

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

.section-block {
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.block-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
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

.ex-select {
  width: 100%;
  background: #1f2937;
  border: 1px solid #374151;
  border-radius: 10px;
  color: #f9fafb;
  font-size: 15px;
  font-weight: 500;
  padding: 10px 12px;
  outline: none;
  cursor: pointer;
}

.ex-select:focus { border-color: #3b82f6; }

.chart-loading {
  display: flex;
  justify-content: center;
  padding: 24px;
}

.spinner {
  width: 24px;
  height: 24px;
  border: 3px solid #1f2937;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.chart-empty {
  text-align: center;
  font-size: 13px;
  color: #4b5563;
  padding: 16px 0;
}
</style>
