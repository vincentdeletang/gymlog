<script setup>
import { computed } from 'vue'
import { Line, Bar, Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'

ChartJS.register(
  CategoryScale, LinearScale, PointElement, LineElement,
  BarElement, ArcElement, Title, Tooltip, Legend, Filler
)

const props = defineProps({
  type: { type: String, default: 'line' }, // 'line' | 'bar' | 'doughnut'
  labels: Array,
  datasets: Array,
  title: String,
})

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: props.type === 'doughnut',
      labels: { color: '#9ca3af', font: { family: 'Barlow', size: 12 } },
    },
    title: {
      display: !!props.title,
      text: props.title,
      color: '#9ca3af',
      font: { family: 'Barlow Condensed', size: 14, weight: '700' },
    },
    tooltip: {
      backgroundColor: '#1f2937',
      titleColor: '#f9fafb',
      bodyColor: '#9ca3af',
      borderColor: '#374151',
      borderWidth: 1,
    },
  },
  scales: props.type !== 'doughnut' ? {
    x: {
      grid: { color: 'rgba(31,41,55,0.8)' },
      ticks: { color: '#6b7280', font: { family: 'Barlow', size: 11 } },
    },
    y: {
      grid: { color: 'rgba(31,41,55,0.8)' },
      ticks: { color: '#6b7280', font: { family: 'Barlow', size: 11 } },
    },
  } : undefined,
}))

const chartData = computed(() => ({
  labels: props.labels,
  datasets: props.datasets ?? [],
}))
</script>

<template>
  <div class="chart-wrap">
    <Line v-if="type === 'line'" :data="chartData" :options="chartOptions" />
    <Bar v-else-if="type === 'bar'" :data="chartData" :options="chartOptions" />
    <Doughnut v-else-if="type === 'doughnut'" :data="chartData" :options="chartOptions" />
  </div>
</template>

<style scoped>
.chart-wrap {
  height: 180px;
  position: relative;
}
</style>
