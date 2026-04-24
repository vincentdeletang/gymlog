<script setup>
import { computed } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'

const props = defineProps({
  block: Object,
  index: Number,
})

const workoutStore = useWorkoutStore()
const done = computed(() => workoutStore.isCardioDone(props.block.id))

function toggleDone() {
  if (done.value) workoutStore.unmarkCardioDone(props.block.id)
  else workoutStore.markCardioDone(props.block.id)
}
</script>

<template>
  <div class="cardio-block" :class="{ done }">
    <div class="block-header">
      <div class="block-info">
        <span class="block-index">{{ index + 1 }}</span>
        <div>
          <div class="block-name">{{ block.name }}</div>
          <div class="block-target">{{ block.duration_minutes }} min</div>
        </div>
      </div>
      <button class="done-btn" :class="{ active: done }" @click="toggleDone">
        {{ done ? '✓ Fait' : 'Marquer fait' }}
      </button>
    </div>

    <div v-if="block.notes" class="block-notes">💡 {{ block.notes }}</div>
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
  gap: 10px;
  transition: border-color 0.2s;
}

.cardio-block.done {
  border-left-color: #10b981;
  opacity: 0.7;
}

.block-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.block-info {
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

.block-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 700;
  color: #f9fafb;
}

.block-target {
  font-size: 12px;
  color: #9ca3af;
}

.done-btn {
  flex-shrink: 0;
  min-height: 36px;
  padding: 0 14px;
  background: #1f2937;
  color: #9ca3af;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 1px;
  border: 1px solid #1f2937;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.15s;
}

.done-btn.active {
  background: rgba(16, 185, 129, 0.15);
  border-color: rgba(16, 185, 129, 0.4);
  color: #10b981;
}

.done-btn:active {
  transform: scale(0.96);
}

.block-notes {
  font-size: 12px;
  color: #9ca3af;
}
</style>
