<script setup>
import { computed, onMounted } from 'vue'
import { useConfetti } from '@/composables/useConfetti'
import { useAudio } from '@/composables/useAudio'

const props = defineProps({
  xpEarned: Number,
  streakCount: Number,
  stats: Object, // { setsDone, tonnage, avgRir, durationSec, prCount }
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

const durationLabel = computed(() => {
  const s = props.stats?.durationSec
  if (!s) return null
  const m = Math.floor(s / 60)
  return m < 60 ? `${m} min` : `${Math.floor(m / 60)}h${String(m % 60).padStart(2, '0')}`
})

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

        <div v-if="stats" class="stats-grid">
          <div v-if="stats.tonnage > 0" class="stat-cell">
            <div class="stat-val">{{ stats.tonnage.toLocaleString('fr-FR') }}</div>
            <div class="stat-lbl">kg de tonnage</div>
          </div>
          <div class="stat-cell">
            <div class="stat-val">{{ stats.setsDone }}</div>
            <div class="stat-lbl">séries</div>
          </div>
          <div v-if="durationLabel" class="stat-cell">
            <div class="stat-val">{{ durationLabel }}</div>
            <div class="stat-lbl">durée</div>
          </div>
          <div v-if="stats.avgRir != null" class="stat-cell">
            <div class="stat-val">{{ stats.avgRir }}</div>
            <div class="stat-lbl">RIR moyen</div>
          </div>
        </div>

        <div v-if="stats?.prCount > 0" class="pr-banner">
          🏆 {{ stats.prCount }} {{ stats.prCount > 1 ? 'records battus' : 'record battu' }}
        </div>

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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
  width: 100%;
  max-width: 320px;
  margin-top: 4px;
}

.stat-cell {
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 10px;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.stat-val {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 800;
  color: #f9fafb;
  line-height: 1;
  letter-spacing: 0.3px;
}

.stat-lbl {
  font-size: 10px;
  color: #9ca3af;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 600;
}

.pr-banner {
  background: linear-gradient(135deg, rgba(245,158,11,0.2), rgba(251,191,36,0.2));
  border: 1px solid rgba(245,158,11,0.4);
  color: #fbbf24;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 700;
  padding: 8px 14px;
  border-radius: 10px;
  letter-spacing: 0.5px;
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
