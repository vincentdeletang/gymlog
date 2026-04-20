<script setup>
import { onMounted } from 'vue'
import { useConfetti } from '@/composables/useConfetti'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  xpEarned: Number,
  streakCount: Number,
})

const emit = defineEmits(['close'])
const { celebrate } = useConfetti()
const { playComplete } = useAudio()

const MESSAGES = [
  'SÉANCE VALIDÉE 💪',
  'BEAST MODE ON 🔥',
  'EN ROUTE VERS LA LÉGENDE ⚡',
  'PROGRESSIF ALWAYS 📈',
  'CHAQUE RÉPÉTITION COMPTE 🎯',
]

const message = MESSAGES[Math.floor(Math.random() * MESSAGES.length)]

onMounted(() => {
  celebrate()
  playComplete()
})
</script>

<template>
  <teleport to="body">
    <div class="celebration-overlay" @click="emit('close')">
      <div class="celebration-card">
        <div class="trophy">🏆</div>
        <h2 class="message">{{ message }}</h2>
        <div class="xp-earned">+{{ xpEarned }} XP</div>
        <div v-if="streakCount > 1" class="streak-info">
          🔥 {{ streakCount }} jours de suite
        </div>
        <p class="tap-hint">Tap pour continuer</p>
      </div>
    </div>
  </teleport>
</template>

<style scoped>
.celebration-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 14, 23, 0.92);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.celebration-card {
  text-align: center;
  padding: 40px 32px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.trophy {
  font-size: 72px;
  animation: bounce 0.6s ease infinite alternate;
}

@keyframes bounce {
  from { transform: translateY(0); }
  to { transform: translateY(-12px); }
}

.message {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 32px;
  font-weight: 800;
  color: #f9fafb;
  letter-spacing: 1px;
  margin: 0;
  text-transform: uppercase;
}

.xp-earned {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 52px;
  font-weight: 800;
  color: #f59e0b;
  letter-spacing: 2px;
  line-height: 1;
}

.streak-info {
  font-size: 20px;
  color: #f59e0b;
  font-weight: 600;
}

.tap-hint {
  font-size: 13px;
  color: #4b5563;
  margin: 0;
  margin-top: 8px;
}
</style>
