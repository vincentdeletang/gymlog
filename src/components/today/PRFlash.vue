<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  exerciseName: String,
  prevBest: Number,
  newE1RM: Number,
  deltaKg: Number,
})
const emit = defineEmits(['close'])

const { playComplete, vibrate } = useAudio()

let timer = null
onMounted(() => {
  playComplete()
  vibrate([60, 40, 60, 40, 120])
  timer = setTimeout(() => emit('close'), 3500)
})
onUnmounted(() => { if (timer) clearTimeout(timer) })

function fmt(n) { return Math.round(n * 10) / 10 }
</script>

<template>
  <div class="pr-flash" @click="emit('close')">
    <div class="pr-content">
      <div class="pr-icon">🏆</div>
      <div class="pr-text">
        <div class="pr-title">NOUVEAU PR</div>
        <div class="pr-name">{{ exerciseName }}</div>
        <div class="pr-delta">
          {{ fmt(prevBest) }}kg → <strong>{{ fmt(newE1RM) }}kg</strong>
          <span class="pr-plus">+{{ fmt(deltaKg) }}kg</span>
        </div>
        <div class="pr-sub">1RM estimé</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pr-flash {
  position: fixed;
  top: calc(env(safe-area-inset-top) + 12px);
  left: 12px;
  right: 12px;
  z-index: 200;
  background: linear-gradient(135deg, rgba(245,158,11,0.95), rgba(251,191,36,0.95));
  border: 1px solid rgba(245,158,11,0.6);
  border-radius: 14px;
  box-shadow: 0 8px 32px rgba(245,158,11,0.4);
  padding: 14px 16px;
  cursor: pointer;
  animation: pr-in 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes pr-in {
  from { transform: translateY(-120%) scale(0.9); opacity: 0; }
  to   { transform: translateY(0) scale(1); opacity: 1; }
}

.pr-content {
  display: flex;
  align-items: center;
  gap: 14px;
}

.pr-icon {
  font-size: 38px;
  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
  animation: pr-bounce 0.6s ease-in-out;
}

@keyframes pr-bounce {
  0%, 100% { transform: scale(1); }
  50%      { transform: scale(1.2) rotate(-8deg); }
}

.pr-text {
  flex: 1;
  min-width: 0;
}

.pr-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 2.5px;
  color: #1a1a1a;
}

.pr-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  color: #1a1a1a;
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-top: 1px;
}

.pr-delta {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 600;
  color: rgba(26,26,26,0.85);
  margin-top: 2px;
}

.pr-delta strong {
  font-size: 16px;
  font-weight: 800;
  color: #1a1a1a;
}

.pr-plus {
  display: inline-block;
  margin-left: 6px;
  background: rgba(26,26,26,0.18);
  color: #1a1a1a;
  font-weight: 800;
  padding: 1px 7px;
  border-radius: 8px;
  font-size: 12px;
}

.pr-sub {
  font-size: 11px;
  color: rgba(26,26,26,0.6);
  font-weight: 600;
  margin-top: 1px;
}
</style>
