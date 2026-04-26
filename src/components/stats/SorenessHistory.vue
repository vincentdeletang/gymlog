<script setup>
import { ref, computed, onMounted } from 'vue'
import ProgressChart from './ProgressChart.vue'
import { useSorenessStore } from '@/stores/useSorenessStore'

const props = defineProps({
  bodyPart: { type: String, default: 'shoulder_left' },
  label: { type: String, default: 'Épaule gauche' },
  days: { type: Number, default: 60 },
})

const soreness = useSorenessStore()
const logs = ref([])
const loading = ref(true)

onMounted(async () => {
  logs.value = await soreness.fetchHistory(props.bodyPart, props.days)
  loading.value = false
})

const stats = computed(() => {
  if (!logs.value.length) return null
  const total = logs.value.length
  const sum = logs.value.reduce((s, l) => s + l.level, 0)
  const avg = sum / total
  const goodDays = logs.value.filter(l => l.level <= 1).length
  const flareDays = logs.value.filter(l => l.level >= 2).length
  return { total, avg: Math.round(avg * 10) / 10, goodDays, flareDays }
})

const chart = computed(() => {
  const labels = logs.value.map(l =>
    new Date(l.log_date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
  )
  const values = logs.value.map(l => l.level)
  return { labels, values }
})

function pointColor(level) {
  if (level === 0) return '#10b981'
  if (level === 1) return '#84cc16'
  if (level === 2) return '#f59e0b'
  return '#ef4444'
}
</script>

<template>
  <div class="sh-card">
    <div class="sh-head">
      <div class="sh-title">{{ label }} — historique douleur</div>
      <div v-if="stats" class="sh-stats">
        <span class="sh-stat sh-good">{{ stats.goodDays }} bons jours</span>
        <span class="sh-stat sh-flare" v-if="stats.flareDays > 0">{{ stats.flareDays }} flares</span>
      </div>
    </div>

    <div v-if="loading" class="sh-loading">…</div>

    <ProgressChart
      v-else-if="chart.labels.length > 1"
      type="line"
      :labels="chart.labels"
      :y-min="0"
      :y-max="3"
      :y-step="1"
      :datasets="[{
        label: 'Douleur (0-3)',
        data: chart.values,
        borderColor: '#f59e0b',
        backgroundColor: 'rgba(245,158,11,0.08)',
        tension: 0.2,
        fill: true,
        stepped: false,
        pointBackgroundColor: chart.values.map(pointColor),
        pointBorderColor: chart.values.map(pointColor),
        pointRadius: 4,
        pointHoverRadius: 6,
      }]"
    />

    <div v-else-if="!logs.length" class="sh-empty">
      Pas encore de check-in. Le bouton apparaît au début de chaque jour muscu.
    </div>
    <div v-else class="sh-empty">
      Reviens après 2-3 check-ins pour voir la tendance.
    </div>
  </div>
</template>

<style scoped>
.sh-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sh-head { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; flex-wrap: wrap; }

.sh-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.sh-stats { display: flex; gap: 6px; }

.sh-stat {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 11px;
  font-weight: 700;
  padding: 1px 8px;
  border-radius: 6px;
  letter-spacing: 0.3px;
}

.sh-good  { background: rgba(16,185,129,0.1); color: #10b981; }
.sh-flare { background: rgba(245,158,11,0.1); color: #fbbf24; }

.sh-loading, .sh-empty {
  text-align: center;
  color: #6b7280;
  padding: 20px;
  font-size: 13px;
}
</style>
