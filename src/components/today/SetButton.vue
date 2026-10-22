<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  setNumber: Number,
  log: Object,       // full set_log object or null
  isBodyweight: Boolean,
  isTimed: Boolean,
})

const emit = defineEmits(['click'])
const animating = ref(false)

const logged = computed(() => !!props.log)

const label = computed(() => {
  if (!props.log) return null
  if (props.isTimed) return props.log.reps_done ? `${props.log.reps_done}s` : '✓'
  if (props.isBodyweight) return props.log.reps_done ? `${props.log.reps_done} reps` : '✓'
  if (props.log.weight_kg) return `${props.log.weight_kg} kg`
  return props.log.reps_done ? `${props.log.reps_done} reps` : '✓'
})

function handleClick() {
  animating.value = true
  setTimeout(() => { animating.value = false }, 400)
  emit('click')
}
</script>

<template>
  <button
    @click="handleClick"
    class="set-btn"
    :class="{ logged, animating, timed: isTimed && !logged }"
  >
    <span class="set-num">S{{ setNumber }}</span>
    <span v-if="label" class="set-info">{{ label }}</span>
    <span v-else-if="isTimed" class="set-hint">⏱</span>
  </button>
</template>

<style scoped>
.set-btn {
  flex: 1 1 0;
  min-width: 64px;
  max-width: 128px;
  min-height: 60px;
  border-radius: 12px;
  border: 2px solid #1f2937;
  background: #111827;
  color: #9ca3af;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s;
  padding: 6px 8px;
  gap: 2px;
}

.set-btn.logged {
  border-color: #10b981;
  background: rgba(16, 185, 129, 0.12);
  color: #10b981;
}

.set-btn.timed {
  border-color: rgba(251, 191, 36, 0.45);
  background: rgba(251, 191, 36, 0.06);
  color: #fbbf24;
}

.set-num {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  line-height: 1;
}

.set-btn.logged .set-num {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  opacity: 0.75;
}

.set-info {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 800;
  line-height: 1;
  white-space: nowrap;
}

.set-hint {
  font-size: 12px;
  line-height: 1;
}

.set-btn.animating {
  transform: scale(0.94);
  border-color: #3b82f6;
  background: rgba(59, 130, 246, 0.2);
}

.set-btn:active {
  transform: scale(0.94);
}
</style>
