<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useSorenessStore } from '@/stores/useSorenessStore'

const props = defineProps({
  bodyPart: { type: String, default: 'shoulder_left' },
  label: { type: String, default: 'Épaule gauche' },
})

const soreness = useSorenessStore()
const collapsed = ref(false)

watch(() => soreness.getTodayLevel(props.bodyPart), (level) => {
  if (level != null) collapsed.value = true
}, { immediate: true })

const LEVELS = [
  { value: 0, emoji: '😊', label: 'Nickel',   color: '#10b981' },
  { value: 1, emoji: '🙂', label: 'Léger',    color: '#84cc16' },
  { value: 2, emoji: '😐', label: 'Inconfort', color: '#f59e0b' },
  { value: 3, emoji: '😣', label: 'Douleur',  color: '#ef4444' },
]

const currentLevel = computed(() => soreness.getTodayLevel(props.bodyPart))
const currentLevelObj = computed(() => LEVELS.find(l => l.value === currentLevel.value))

onMounted(() => {
  if (!soreness.todayLogs.length) soreness.fetchToday()
})

async function pick(level) {
  await soreness.logToday({ bodyPart: props.bodyPart, level })
  collapsed.value = true
}

function expand() { collapsed.value = false }
</script>

<template>
  <!-- Compact view once logged -->
  <div v-if="currentLevelObj && collapsed" class="checkin-compact" @click="expand">
    <span class="cmp-emoji">{{ currentLevelObj.emoji }}</span>
    <span class="cmp-text">
      {{ label }} : <strong>{{ currentLevelObj.label }}</strong>
    </span>
    <span class="cmp-edit">Modifier</span>
  </div>

  <!-- Full picker -->
  <div v-else class="checkin">
    <div class="checkin-head">
      <span class="checkin-icon">🩺</span>
      <div class="checkin-text">
        <div class="checkin-title">Comment va ton {{ label.toLowerCase() }} ?</div>
        <div class="checkin-sub">Avant d'attaquer la séance</div>
      </div>
    </div>
    <div class="level-grid">
      <button
        v-for="l in LEVELS"
        :key="l.value"
        class="level-btn"
        :class="{ selected: currentLevel === l.value }"
        :style="currentLevel === l.value ? { borderColor: l.color, background: l.color + '22' } : {}"
        @click="pick(l.value)"
      >
        <span class="level-emoji">{{ l.emoji }}</span>
        <span class="level-label" :style="currentLevel === l.value ? { color: l.color } : {}">{{ l.label }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.checkin {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 12px;
  padding: 12px 14px;
  margin-bottom: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.checkin-head {
  display: flex;
  align-items: center;
  gap: 10px;
}

.checkin-icon {
  font-size: 22px;
  line-height: 1;
}

.checkin-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: #f9fafb;
  letter-spacing: 0.3px;
}

.checkin-sub {
  font-size: 11px;
  color: #6b7280;
  margin-top: 1px;
}

.level-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
}

.level-btn {
  background: #1f2937;
  border: 2px solid #374151;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 8px 4px;
  cursor: pointer;
  transition: all 0.15s;
  min-height: 60px;
}

.level-btn:active { transform: scale(0.96); }

.level-emoji {
  font-size: 22px;
  line-height: 1;
}

.level-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 11px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

/* Compact */
.checkin-compact {
  display: flex;
  align-items: center;
  gap: 10px;
  background: rgba(16,185,129,0.08);
  border: 1px solid rgba(16,185,129,0.2);
  border-radius: 10px;
  padding: 8px 12px;
  margin-bottom: 12px;
  cursor: pointer;
}

.cmp-emoji { font-size: 18px; line-height: 1; }

.cmp-text {
  flex: 1;
  font-size: 13px;
  color: #9ca3af;
}

.cmp-text strong {
  color: #f9fafb;
  font-weight: 600;
}

.cmp-edit {
  font-size: 11px;
  color: #6b7280;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
</style>
