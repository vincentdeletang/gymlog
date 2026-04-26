<script setup>
import { ref, computed, onMounted } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'

const workoutStore = useWorkoutStore()

const counts = ref({})
const loading = ref(true)

// Hypertrophy targets per Schoenfeld et al. — MEV / MAV ranges
const MUSCLES = [
  { key: 'chest',      label: 'Pectoraux',  min: 10, max: 20, color: '#3b82f6' },
  { key: 'back',       label: 'Dos',        min: 10, max: 20, color: '#0ea5e9' },
  { key: 'shoulders',  label: 'Épaules',    min: 10, max: 20, color: '#06b6d4' },
  { key: 'biceps',     label: 'Biceps',     min: 8,  max: 18, color: '#8b5cf6' },
  { key: 'triceps',    label: 'Triceps',    min: 8,  max: 18, color: '#a855f7' },
  { key: 'quads',      label: 'Quadriceps', min: 8,  max: 16, color: '#10b981' },
  { key: 'hamstrings', label: 'Ischios',    min: 8,  max: 16, color: '#22c55e' },
  { key: 'glutes',     label: 'Fessiers',   min: 6,  max: 14, color: '#84cc16' },
  { key: 'core',       label: 'Core',       min: 6,  max: 14, color: '#f59e0b' },
]

onMounted(async () => {
  counts.value = await workoutStore.fetchCurrentWeekVolumeByMuscle()
  loading.value = false
})

const tracked = computed(() => {
  return MUSCLES
    .map(m => ({ ...m, count: counts.value[m.key] ?? 0 }))
    .filter(m => m.count > 0 || m.min > 0)
    .sort((a, b) => b.count - a.count)
})

function statusFor(m) {
  if (m.count === 0)   return { label: '–', color: '#4b5563' }
  if (m.count < m.min) return { label: 'Sous MEV', color: '#f59e0b' }
  if (m.count > m.max) return { label: 'Au-dessus MAV', color: '#ef4444' }
  return { label: '✓ Zone', color: '#10b981' }
}

function pct(m) {
  return Math.min(100, Math.round((m.count / m.max) * 100))
}
</script>

<template>
  <div class="vbm-card">
    <div class="vbm-head">
      <div class="vbm-title">Volume hebdo par muscle</div>
      <div class="vbm-sub">Cette semaine · cible 10-20 sets / muscle</div>
    </div>

    <div v-if="loading" class="vbm-loading">…</div>

    <div v-else class="muscle-list">
      <div
        v-for="m in tracked"
        :key="m.key"
        class="muscle-row"
      >
        <div class="muscle-line">
          <span class="muscle-name">{{ m.label }}</span>
          <span class="muscle-count">
            <strong>{{ m.count }}</strong> / {{ m.max }} sets
          </span>
          <span class="muscle-status" :style="{ color: statusFor(m).color, background: statusFor(m).color + '11', borderColor: statusFor(m).color + '33' }">
            {{ statusFor(m).label }}
          </span>
        </div>
        <div class="muscle-bar">
          <div
            class="muscle-fill"
            :style="{ width: pct(m) + '%', background: m.color }"
          />
          <div
            class="muscle-mev"
            :style="{ left: (m.min / m.max * 100) + '%' }"
            :title="`MEV ${m.min}`"
          />
        </div>
      </div>

      <div v-if="!tracked.length" class="vbm-empty">
        Pas encore de données. Lance ta première séance.
      </div>
    </div>
  </div>
</template>

<style scoped>
.vbm-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.vbm-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.vbm-sub {
  font-size: 11px;
  color: #6b7280;
  margin-top: 2px;
}

.vbm-loading {
  text-align: center;
  color: #6b7280;
  padding: 16px;
  font-size: 14px;
}

.vbm-empty {
  text-align: center;
  color: #4b5563;
  padding: 24px;
  font-size: 13px;
}

.muscle-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.muscle-row {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.muscle-line {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.muscle-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 700;
  color: #f9fafb;
  letter-spacing: 0.3px;
  text-transform: uppercase;
  flex: 1;
  min-width: 0;
}

.muscle-count {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  color: #9ca3af;
  flex-shrink: 0;
}

.muscle-count strong {
  font-size: 16px;
  font-weight: 800;
  color: #f9fafb;
}

.muscle-status {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 10px;
  font-weight: 700;
  padding: 1px 6px;
  border: 1px solid;
  border-radius: 6px;
  letter-spacing: 0.3px;
  flex-shrink: 0;
}

.muscle-bar {
  position: relative;
  height: 6px;
  background: #1f2937;
  border-radius: 3px;
  overflow: visible;
}

.muscle-fill {
  height: 100%;
  border-radius: inherit;
  transition: width 0.4s ease;
}

.muscle-mev {
  position: absolute;
  top: -2px;
  bottom: -2px;
  width: 2px;
  background: rgba(245,158,11,0.7);
  pointer-events: none;
}
</style>
