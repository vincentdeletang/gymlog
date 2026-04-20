<script setup>
import { ref, computed } from 'vue'
import { useTimer } from '@/composables/useTimer'

const props = defineProps({
  block: Object,
  index: Number,
})

const emit = defineEmits(['done'])
const { seconds, running, formatted, toggle, reset } = useTimer()

const done = ref(false)

const targetSeconds = computed(() => props.block.duration_minutes * 60)
const progress = computed(() => Math.min((seconds.value / targetSeconds.value) * 100, 100))

function markDone() {
  done.value = true
  if (running.value) toggle()
  emit('done', seconds.value)
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
      <div v-if="done" class="done-badge">✓ Terminé</div>
    </div>

    <div v-if="block.notes" class="block-notes">💡 {{ block.notes }}</div>

    <div class="timer-display">{{ formatted }}</div>

    <div class="progress-bar">
      <div class="progress-fill" :style="{ width: progress + '%' }" />
    </div>

    <div class="timer-controls" v-if="!done">
      <button class="ctrl-btn secondary" @click="reset">↺</button>
      <button class="ctrl-btn primary" @click="toggle">
        {{ running ? '⏸ Pause' : '▶ Start' }}
      </button>
      <button class="ctrl-btn success" @click="markDone">✓ Terminé</button>
    </div>
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
}

.block-info {
  display: flex;
  align-items: center;
  gap: 10px;
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

.done-badge {
  color: #10b981;
  font-size: 13px;
  font-weight: 700;
}

.block-notes {
  font-size: 12px;
  color: #9ca3af;
}

.timer-display {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 48px;
  font-weight: 800;
  color: #f59e0b;
  text-align: center;
  letter-spacing: 2px;
}

.progress-bar {
  height: 4px;
  background: #1f2937;
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #f59e0b, #ef4444);
  border-radius: 2px;
  transition: width 1s linear;
}

.timer-controls {
  display: grid;
  grid-template-columns: 44px 1fr 1fr;
  gap: 8px;
}

.ctrl-btn {
  height: 44px;
  border-radius: 10px;
  border: none;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s;
}

.ctrl-btn.secondary {
  background: #1f2937;
  color: #9ca3af;
}

.ctrl-btn.primary {
  background: #f59e0b;
  color: #0a0e17;
}

.ctrl-btn.success {
  background: rgba(16, 185, 129, 0.15);
  color: #10b981;
  border: 1px solid rgba(16, 185, 129, 0.3);
}

.ctrl-btn:active {
  transform: scale(0.96);
}
</style>
