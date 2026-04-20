<script setup>
import { computed } from 'vue'
import SetButton from './SetButton.vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { suggestedWeight } from '@/lib/progression'

const props = defineProps({
  exercise: Object,
})

const emit = defineEmits(['openSet'])

const workoutStore = useWorkoutStore()

const sets = computed(() =>
  Array.from({ length: props.exercise.sets_target }, (_, i) => i + 1)
)

const allLogged = computed(() =>
  sets.value.every(s => workoutStore.isSetLogged(props.exercise.id, s))
)

const suggestion = computed(() => {
  if (props.exercise.is_bodyweight || props.exercise.section === 'rehab') return null
  const prev = workoutStore.getPreviousSet(props.exercise.id, 1)
  return suggestedWeight(prev, props.exercise.reps_target)
})

const SECTION_BADGE = {
  rehab:  { label: 'REHAB',  color: '#f59e0b' },
  main:   { label: 'MAIN',   color: '#3b82f6' },
  cardio: { label: 'CARDIO', color: '#10b981' },
}
</script>

<template>
  <div class="exercise-row" :class="{ done: allLogged }">
    <div class="ex-header">
      <div class="ex-name-wrap">
        <span
          class="section-dot"
          :style="{ background: SECTION_BADGE[exercise.section]?.color }"
        />
        <span class="ex-name">{{ exercise.name }}</span>
      </div>
      <div class="ex-meta">
        <span class="ex-sets">{{ exercise.sets_target }}×{{ exercise.reps_target }}</span>
        <span v-if="exercise.is_bodyweight" class="bw-badge">BW</span>
        <span v-if="suggestion" class="weight-suggestion" :class="{ increased: suggestion.increased }">
          {{ suggestion.increased ? '↑' : '=' }} {{ suggestion.weight }}kg
        </span>
      </div>
    </div>

    <div v-if="exercise.notes" class="ex-notes">{{ exercise.notes }}</div>

    <div class="sets-row">
      <SetButton
        v-for="s in sets"
        :key="s"
        :set-number="s"
        :log="workoutStore.getSetLog(exercise.id, s)"
        :is-bodyweight="exercise.is_bodyweight"
        @click="emit('openSet', { exercise, setNumber: s })"
      />
    </div>
  </div>
</template>

<style scoped>
.exercise-row {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  transition: border-color 0.2s;
}

.exercise-row.done {
  border-color: rgba(16, 185, 129, 0.3);
  background: rgba(16, 185, 129, 0.04);
}

.ex-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.ex-name-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.section-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.ex-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 700;
  color: #f9fafb;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.ex-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.ex-sets {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  color: #9ca3af;
}

.bw-badge {
  background: #1f2937;
  color: #f59e0b;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 4px;
}

.weight-suggestion {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 800;
  color: #60a5fa;
  background: rgba(59, 130, 246, 0.1);
  padding: 2px 8px;
  border-radius: 6px;
  letter-spacing: 0.5px;
}

.weight-suggestion.increased {
  color: #10b981;
  background: rgba(16, 185, 129, 0.1);
}

.ex-notes {
  font-size: 12px;
  color: #6b7280;
  font-style: italic;
}

.sets-row {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
</style>
