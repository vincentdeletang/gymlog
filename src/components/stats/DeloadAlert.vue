<script setup>
import { ref, onMounted } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'

const workoutStore = useWorkoutStore()
const candidates = ref([])
const loading = ref(true)

onMounted(async () => {
  candidates.value = await workoutStore.fetchDeloadCandidates({
    lastSessions: 3,
    threshold: 1,
    minSamples: 3,
  })
  loading.value = false
})
</script>

<template>
  <div v-if="!loading && candidates.length" class="deload-alert">
    <div class="da-head">
      <span class="da-icon">⚠️</span>
      <div class="da-text">
        <div class="da-title">Signaux de fatigue détectés</div>
        <div class="da-sub">RIR moyen {{ '<' }} 1 sur 3 dernières séances — semaine de décharge recommandée</div>
      </div>
    </div>
    <ul class="da-list">
      <li v-for="c in candidates" :key="c.exercise_id" class="da-item">
        <span class="da-name">{{ c.exercise_name }}</span>
        <span class="da-rir">RIR moy. <strong>{{ c.avg_rir }}</strong> · {{ c.count }} séries</span>
      </li>
    </ul>
    <div class="da-tip">
      💡 Décharge : −30 à −50% du volume pendant 1 semaine, garde l'intensité. Tu reviens plus fort.
    </div>
  </div>
</template>

<style scoped>
.deload-alert {
  background: rgba(245,158,11,0.08);
  border: 1px solid rgba(245,158,11,0.3);
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.da-head {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.da-icon {
  font-size: 22px;
  line-height: 1;
}

.da-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 15px;
  font-weight: 700;
  color: #fbbf24;
  letter-spacing: 0.3px;
}

.da-sub {
  font-size: 12px;
  color: #d97706;
  margin-top: 2px;
  line-height: 1.4;
}

.da-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
  background: rgba(0,0,0,0.2);
  border-radius: 8px;
  padding: 8px 10px;
}

.da-item {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 8px;
  font-size: 13px;
}

.da-name {
  color: #f9fafb;
  font-weight: 500;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.da-rir {
  font-family: 'Barlow Condensed', sans-serif;
  color: #d97706;
  font-size: 12px;
  flex-shrink: 0;
}

.da-rir strong {
  color: #fbbf24;
  font-size: 14px;
  font-weight: 800;
}

.da-tip {
  font-size: 12px;
  color: #d97706;
  line-height: 1.5;
  font-style: italic;
}
</style>
