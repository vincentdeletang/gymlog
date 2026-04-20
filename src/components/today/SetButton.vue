<script setup>
import { ref } from 'vue'

const props = defineProps({
  setNumber: Number,
  logged: Boolean,
  ripple: { type: Boolean, default: false },
})

const emit = defineEmits(['click'])
const animating = ref(false)

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
    :class="{ logged, animating }"
    :aria-label="`Série ${setNumber}`"
  >
    <span class="set-num">S{{ setNumber }}</span>
    <span v-if="logged" class="check">✓</span>
  </button>
</template>

<style scoped>
.set-btn {
  min-width: 48px;
  min-height: 48px;
  border-radius: 10px;
  border: 2px solid #1f2937;
  background: #111827;
  color: #9ca3af;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s;
  position: relative;
  overflow: hidden;
  padding: 4px 8px;
  gap: 1px;
}

.set-btn.logged {
  border-color: #10b981;
  background: rgba(16, 185, 129, 0.12);
  color: #10b981;
}

.set-num {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 700;
  line-height: 1;
}

.check {
  font-size: 11px;
  line-height: 1;
}

.set-btn.animating {
  transform: scale(0.9);
  border-color: #3b82f6;
  background: rgba(59, 130, 246, 0.2);
}

.set-btn:active {
  transform: scale(0.92);
}
</style>
