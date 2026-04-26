<script setup>
import { ref, onMounted } from 'vue'
import { useWorkoutStore } from '@/stores/useWorkoutStore'

const workoutStore = useWorkoutStore()

const prs = ref([])
const loading = ref(true)

onMounted(async () => {
  prs.value = await workoutStore.fetchAllTimePRs()
  loading.value = false
})

function fmtDate(s) {
  if (!s) return ''
  return new Date(s).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
}

function totalWeight(pr) {
  return Math.round((pr.weight_kg + (pr.tare ?? 0)) * 10) / 10
}

function fmtE1rm(e) {
  return Math.round(e * 10) / 10
}
</script>

<template>
  <div class="pr-card">
    <div class="pr-head">
      <div class="pr-title">🏆 Records personnels</div>
      <div class="pr-sub">1RM estimé (Epley) — meilleure série toutes séances confondues</div>
    </div>

    <div v-if="loading" class="pr-loading">…</div>

    <div v-else-if="prs.length" class="pr-list">
      <div v-for="pr in prs" :key="pr.exercise_id" class="pr-row">
        <div class="pr-info">
          <div class="pr-name">{{ pr.exercise_name }}</div>
          <div class="pr-detail">
            {{ totalWeight(pr) }}kg × {{ pr.reps_done }} reps
            <span class="pr-date">· {{ fmtDate(pr.session_date) }}</span>
          </div>
        </div>
        <div class="pr-e1rm">
          <span class="pr-e1rm-val">{{ fmtE1rm(pr.e1rm) }}</span>
          <span class="pr-e1rm-lbl">kg 1RM</span>
        </div>
      </div>
    </div>

    <div v-else class="pr-empty">
      Pas encore de PR — termine ta première séance avec poids.
    </div>
  </div>
</template>

<style scoped>
.pr-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.pr-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.pr-sub {
  font-size: 11px;
  color: #6b7280;
  margin-top: 2px;
}

.pr-loading, .pr-empty {
  text-align: center;
  color: #6b7280;
  padding: 20px;
  font-size: 13px;
}

.pr-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.pr-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 10px;
  padding: 9px 12px;
}

.pr-info { flex: 1; min-width: 0; }

.pr-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 700;
  color: #f9fafb;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.pr-detail {
  font-size: 12px;
  color: #9ca3af;
  margin-top: 1px;
}

.pr-date { color: #6b7280; }

.pr-e1rm {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  flex-shrink: 0;
}

.pr-e1rm-val {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 800;
  color: #f59e0b;
  line-height: 1;
  letter-spacing: 0.3px;
}

.pr-e1rm-lbl {
  font-size: 9px;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 600;
}
</style>
