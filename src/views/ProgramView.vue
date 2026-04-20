<script setup>
import { computed, onMounted } from 'vue'
import { useProgramStore } from '@/stores/useProgramStore'

const programStore = useProgramStore()

onMounted(() => {
  if (!programStore.activeProgram) programStore.fetchActiveProgram()
})

const DAYS = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
const TYPE_COLOR = { strength: '#3b82f6', cardio: '#f59e0b', rest: '#6b7280' }
const TYPE_ICON  = { strength: '💪', cardio: '🏃', rest: '😴' }

const sortedDays = computed(() =>
  [...programStore.programDays].sort((a, b) => {
    const order = [1,2,3,4,5,6,0]
    return order.indexOf(a.day_of_week) - order.indexOf(b.day_of_week)
  })
)
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

    <div v-else-if="!programStore.activeProgram" class="empty-state">
      <p>Aucun programme actif.</p>
    </div>

    <div v-else class="days-list">
      <div
        v-for="day in sortedDays"
        :key="day.id"
        class="day-card"
        :style="{ borderLeftColor: TYPE_COLOR[day.type] }"
      >
        <div class="day-header">
          <div class="day-label">
            <span class="day-short">{{ DAYS[day.day_of_week] }}</span>
            <span class="day-icon">{{ TYPE_ICON[day.type] }}</span>
            <span class="day-name">{{ day.name }}</span>
          </div>
          <div class="day-meta">
            <span class="xp-badge" v-if="day.xp_reward">+{{ day.xp_reward }} XP</span>
          </div>
        </div>

        <!-- Exercises -->
        <div class="exercises-list" v-if="programStore.getExercisesForDay(day.id).length">
          <div
            v-for="ex in programStore.getExercisesForDay(day.id)"
            :key="ex.id"
            class="ex-item"
            :class="ex.section"
          >
            <span class="ex-name">{{ ex.name }}</span>
            <span class="ex-sets">{{ ex.sets_target }}×{{ ex.reps_target }}</span>
          </div>
        </div>

        <!-- Cardio blocks -->
        <div class="cardio-list" v-if="programStore.getCardioBlocksForDay(day.id).length">
          <div
            v-for="cb in programStore.getCardioBlocksForDay(day.id)"
            :key="cb.id"
            class="cardio-item"
          >
            <span>🏃 {{ cb.name }}</span>
            <span class="cardio-dur">{{ cb.duration_minutes }} min</span>
          </div>
        </div>
      </div>
    </div>

    <div style="height: 80px" />
  </div>
</template>

<style scoped>
.program-view { padding: 0 0 80px; }

.view-header {
  padding: 16px 16px 12px;
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
  color: #9ca3af;
  margin-top: 2px;
}

.loading {
  display: flex;
  justify-content: center;
  padding: 40px;
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

.empty-state {
  text-align: center;
  padding: 48px;
  color: #6b7280;
}

.days-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 16px;
}

.day-card {
  background: #111827;
  border: 1px solid #1f2937;
  border-left-width: 3px;
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.day-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.day-label {
  display: flex;
  align-items: center;
  gap: 8px;
}

.day-short {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  background: #1f2937;
  padding: 2px 8px;
  border-radius: 4px;
  min-width: 32px;
  text-align: center;
}

.day-icon { font-size: 16px; }

.day-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 17px;
  font-weight: 700;
  color: #f9fafb;
}

.xp-badge {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  color: #f59e0b;
  font-weight: 700;
}

.exercises-list, .cardio-list {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.ex-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 0;
  border-bottom: 1px solid #1a2235;
  font-size: 13px;
}

.ex-item:last-child { border-bottom: none; }

.ex-item.rehab .ex-name { color: #fbbf24; }
.ex-item.main  .ex-name { color: #e5e7eb; }

.ex-sets {
  color: #9ca3af;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 600;
  flex-shrink: 0;
}

.cardio-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13px;
  color: #e5e7eb;
  padding: 3px 0;
}

.cardio-dur {
  color: #f59e0b;
  font-family: 'Barlow Condensed', sans-serif;
  font-weight: 700;
}
</style>
