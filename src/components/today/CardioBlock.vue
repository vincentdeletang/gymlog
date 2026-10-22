<script setup>
import { computed, ref } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { suggestedDuration, durationDelta } from '@/lib/cardioProgression'
import CardioDetailModal from './CardioDetailModal.vue'

const props = defineProps({
  block: Object,
  index: Number,
})

const workoutStore = useWorkoutStore()
const done = computed(() => workoutStore.isCardioDone(props.block.id))
const log  = computed(() => workoutStore.getCardioLog(props.block.id))
const detailOpen = ref(false)

const suggestion = computed(() =>
  suggestedDuration(workoutStore.getPreviousCardioLogs(props.block.id), props.block)
)

const targetMin = computed(() => suggestion.value?.duration ?? props.block.duration_minutes)

const loggedMin = computed(() =>
  log.value?.duration_seconds ? Math.round(log.value.duration_seconds / 60) : null
)

const delta = computed(() => durationDelta(log.value?.duration_seconds, targetMin.value))

// Un tap logue la durée cible : c'est le cas de 9 séances sur 10. L'autre durée
// passe par la modal.
function toggleDone() {
  if (done.value) workoutStore.unmarkCardioDone(props.block.id)
  else workoutStore.markCardioDone(props.block.id, { duration_seconds: targetMin.value * 60 })
}

function onDetailSave(details) {
  workoutStore.markCardioDone(props.block.id, details)
  detailOpen.value = false
}
</script>

<template>
  <div class="cardio-block" :class="{ done }">
    <div class="block-header">
      <span class="block-index">{{ index + 1 }}</span>
      <div class="block-text">
        <div class="block-name">{{ block.name }}</div>
        <div class="block-target">
          <span class="target-min">{{ targetMin }} min</span>
          <span v-if="suggestion?.increased" class="cardio-suggestion increased">
            ↑ +{{ block.progression_step_minutes ?? 2 }} min
          </span>
          <span v-else-if="suggestion?.atMax && !suggestion?.increased" class="cardio-suggestion atmax">
            🎯 max
          </span>
          <span v-if="done && loggedMin != null && delta" class="block-actual" :class="{ over: delta > 0, under: delta < 0 }">
            · fait {{ loggedMin }} min
          </span>
        </div>
      </div>
    </div>

    <div class="block-actions">
      <button class="done-btn" :class="{ active: done }" @click="toggleDone">
        <template v-if="done">✓ {{ loggedMin ?? targetMin }} min</template>
        <template v-else>Fait · {{ targetMin }} min</template>
      </button>
      <button class="edit-btn" @click="detailOpen = true">
        {{ done ? 'Modifier' : 'Autre durée' }}
      </button>
    </div>

    <div v-if="block.notes" class="block-notes">💡 {{ block.notes }}</div>

    <CardioDetailModal
      v-if="detailOpen"
      :block="block"
      :existing-log="log"
      @close="detailOpen = false"
      @save="onDetailSave"
    />
  </div>
</template>

<style scoped>
.cardio-block {
  background: #111827;
  border: 1px solid #1f2937;
  border-left: 3px solid #f59e0b;
  border-radius: 12px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: border-color 0.2s;
}

.cardio-block.done {
  border-left-color: #10b981;
}

.block-header {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.block-index {
  width: 28px;
  height: 28px;
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
  font-family: 'Barlow Condensed', sans-serif;
  font-weight: 800;
  font-size: 16px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.block-text { min-width: 0; }

.block-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 19px;
  font-weight: 700;
  color: #f9fafb;
  line-height: 1.15;
}

.block-target {
  font-size: 13px;
  color: #9ca3af;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 2px;
}

.target-min {
  font-weight: 600;
}

.cardio-suggestion {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.5px;
  padding: 1px 6px;
  border-radius: 5px;
}

.cardio-suggestion.increased {
  color: #10b981;
  background: rgba(16, 185, 129, 0.12);
}

.cardio-suggestion.atmax {
  color: #f59e0b;
  background: rgba(245, 158, 11, 0.12);
}

.block-actual {
  color: #10b981;
  font-weight: 600;
}

.block-actual.under {
  color: #f59e0b;
}

.block-actions {
  display: flex;
  gap: 8px;
}

.done-btn {
  flex: 1;
  min-height: 52px;
  padding: 0 14px;
  background: #1f2937;
  color: #e5e7eb;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  border: 2px solid #374151;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.15s;
}

.done-btn.active {
  background: rgba(16, 185, 129, 0.15);
  border-color: #10b981;
  color: #10b981;
}

.done-btn:active { transform: scale(0.97); }

.edit-btn {
  min-height: 52px;
  padding: 0 14px;
  background: transparent;
  border: 1px solid #374151;
  color: #9ca3af;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px;
  font-weight: 600;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.15s;
}

.edit-btn:active { background: #1f2937; color: #f9fafb; }

.block-notes {
  font-size: 13px;
  color: #9ca3af;
  line-height: 1.45;
}
</style>
