<script setup>
import { ref, computed, watch } from 'vue'
import SetButton from './SetButton.vue'
import ExerciseNotes from '@/components/shared/ExerciseNotes.vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { suggestedWeight } from '@/lib/progression'
import { isTimed as isTimedTarget } from '@/lib/parseTarget'

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

// QoL : replier un exo dès que toutes ses sets sont faites (moins de scroll en séance).
// Se déplie tout seul si une set est dé-loggée ; l'en-tête permet de basculer à la main.
const collapsed = ref(false)
watch(allLogged, (done) => { collapsed.value = done }, { immediate: true })
function toggleCollapse() {
  if (!allLogged.value) return
  collapsed.value = !collapsed.value
}

const timed = computed(() => isTimedTarget(props.exercise.reps_target))

const suggestion = computed(() => {
  if (props.exercise.is_bodyweight || props.exercise.section === 'rehab') return null
  const prev = workoutStore.getPreviousSet(props.exercise.id, 1)
  return suggestedWeight(prev, props.exercise.reps_target)
})

const SECTION_BADGE = {
  rehab:    { label: 'PRÉVENTION', color: '#f59e0b' },
  main:     { label: 'MUSCU',      color: '#3b82f6' },
  cardio:   { label: 'CARDIO',     color: '#10b981' },
  cooldown: { label: 'RÉCUP',      color: '#8b5cf6' },
  mobility: { label: 'MOBILITÉ',   color: '#06b6d4' },
}
</script>

<template>
  <div class="exercise-row" :class="{ done: allLogged, collapsed }">
    <div class="ex-header" :class="{ clickable: allLogged }" @click="toggleCollapse">
      <div class="ex-name-wrap">
        <span
          class="section-dot"
          :style="{ background: SECTION_BADGE[exercise.section]?.color }"
        />
        <span class="ex-name">{{ exercise.name }}</span>
      </div>
      <div class="ex-meta">
        <span v-if="collapsed" class="done-check">✓</span>
        <span class="ex-sets">{{ exercise.sets_target }}×{{ exercise.reps_target }}</span>
        <span v-if="!collapsed && exercise.is_bodyweight" class="bw-badge">BW</span>
        <span v-if="!collapsed && suggestion" class="weight-suggestion" :class="{ increased: suggestion.increased }">
          {{ suggestion.increased ? '↑' : '=' }} {{ suggestion.weight }}kg
        </span>
        <span v-if="allLogged" class="collapse-chevron" :class="{ open: !collapsed }">▾</span>
      </div>
    </div>

    <transition name="collapse">
      <div v-if="!collapsed" class="ex-body">
        <ExerciseNotes :notes="exercise.notes" />

        <div class="sets-row">
          <SetButton
            v-for="s in sets"
            :key="s"
            :set-number="s"
            :log="workoutStore.getSetLog(exercise.id, s)"
            :is-bodyweight="exercise.is_bodyweight"
            :is-timed="timed"
            @click="emit('openSet', { exercise, setNumber: s })"
          />
        </div>
      </div>
    </transition>
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

.exercise-row.collapsed {
  padding: 10px 14px;
  gap: 0;
}

.ex-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.ex-header.clickable {
  cursor: pointer;
  user-select: none;
}

.ex-body {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.done-check {
  color: #10b981;
  font-weight: 800;
  font-size: 14px;
}

.collapse-chevron {
  color: #6b7280;
  font-size: 11px;
  transition: transform 0.2s;
  transform: rotate(-90deg);
}

.collapse-chevron.open {
  transform: rotate(0deg);
}

.collapse-enter-active,
.collapse-leave-active {
  transition: opacity 0.18s ease;
}

.collapse-enter-from,
.collapse-leave-to {
  opacity: 0;
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

.sets-row {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
</style>
