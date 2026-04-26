<script setup>
import { ref, computed, onMounted } from 'vue'
import ProgressChart from './ProgressChart.vue'
import { useBodyweightStore } from '@/stores/useBodyweightStore'
import { todayISO } from '@/lib/formatDate'

const bw = useBodyweightStore()

const modalOpen = ref(false)
const inputDate = ref(todayISO())
const inputWeight = ref('')
const saving = ref(false)

onMounted(() => {
  if (!bw.logs.length) bw.fetchAll()
})

const latest = computed(() => bw.logs.length ? bw.logs[bw.logs.length - 1] : null)

const trend = computed(() => {
  if (bw.logs.length < 2) return null
  const last = bw.logs[bw.logs.length - 1]
  const fourWeeksAgo = new Date(last.log_date)
  fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28)
  const ref = [...bw.logs].reverse().find(l => l.log_date <= fourWeeksAgo.toISOString().slice(0, 10))
  if (!ref) return null
  const delta = Math.round((last.weight_kg - ref.weight_kg) * 10) / 10
  return { delta, since: ref.log_date }
})

const chart = computed(() => {
  const labels = bw.logs.map(l =>
    new Date(l.log_date).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
  )
  const values = bw.logs.map(l => l.weight_kg)
  return { labels, values }
})

function openModal() {
  inputDate.value = todayISO()
  inputWeight.value = latest.value ? String(latest.value.weight_kg) : ''
  modalOpen.value = true
}

async function save() {
  const w = parseFloat(inputWeight.value)
  if (!w || w <= 0) return
  saving.value = true
  await bw.logWeight({ logDate: inputDate.value, weightKg: w })
  saving.value = false
  modalOpen.value = false
}
</script>

<template>
  <div class="bw-card">
    <div class="bw-head">
      <div class="bw-title-wrap">
        <div class="bw-title">Poids corporel</div>
        <div v-if="latest" class="bw-current">
          <strong>{{ latest.weight_kg }}</strong>kg
          <span v-if="trend" class="bw-trend" :class="{ up: trend.delta > 0, down: trend.delta < 0 }">
            {{ trend.delta > 0 ? '↑' : trend.delta < 0 ? '↓' : '=' }}
            {{ Math.abs(trend.delta) }}kg / 4 sem
          </span>
        </div>
        <div v-else class="bw-empty">Aucun relevé encore</div>
      </div>
      <button class="bw-add" @click="openModal">+ Logger</button>
    </div>

    <ProgressChart
      v-if="chart.labels.length > 1"
      type="line"
      :labels="chart.labels"
      :datasets="[{
        label: 'Poids (kg)',
        data: chart.values,
        borderColor: '#10b981',
        backgroundColor: 'rgba(16,185,129,0.08)',
        tension: 0.3,
        fill: true,
        pointBackgroundColor: '#10b981',
        pointRadius: 3,
        pointHoverRadius: 6,
      }]"
    />

    <Teleport to="body" v-if="modalOpen">
      <div class="modal-overlay" @click.self="modalOpen = false">
        <div class="modal-panel">
          <div class="modal-handle" />
          <h3>Logger ton poids</h3>

          <div class="field">
            <label>Date</label>
            <input type="date" :max="todayISO()" v-model="inputDate" class="field-input" />
          </div>

          <div class="field">
            <label>Poids (kg)</label>
            <input
              v-model="inputWeight"
              type="number"
              inputmode="decimal"
              step="0.1"
              min="20"
              max="300"
              placeholder="Ex: 135.4"
              class="field-input field-input-big"
              autofocus
            />
          </div>

          <button class="save-btn" :disabled="saving || !inputWeight" @click="save">
            {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
          </button>
          <button class="cancel-btn" @click="modalOpen = false">Annuler</button>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.bw-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.bw-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.bw-title-wrap { flex: 1; min-width: 0; }

.bw-title {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #9ca3af;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.bw-current {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  color: #f9fafb;
  margin-top: 2px;
  display: flex;
  align-items: baseline;
  gap: 8px;
  flex-wrap: wrap;
}

.bw-current strong {
  font-size: 28px;
  font-weight: 800;
  color: #10b981;
}

.bw-trend {
  font-size: 13px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 8px;
  letter-spacing: 0.3px;
}

.bw-trend.up   { color: #f59e0b; background: rgba(245,158,11,0.1); }
.bw-trend.down { color: #10b981; background: rgba(16,185,129,0.1); }

.bw-empty {
  font-size: 13px;
  color: #6b7280;
  margin-top: 4px;
}

.bw-add {
  background: rgba(16,185,129,0.12);
  border: 1px solid rgba(16,185,129,0.3);
  color: #10b981;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.5px;
  padding: 6px 12px;
  border-radius: 8px;
  cursor: pointer;
  white-space: nowrap;
  flex-shrink: 0;
}

.bw-add:active { background: rgba(16,185,129,0.2); }

/* Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10,14,23,0.7);
  z-index: 100;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  backdrop-filter: blur(4px);
}

.modal-panel {
  width: 100%;
  max-width: 480px;
  background: #0f1623;
  border-top-left-radius: 18px;
  border-top-right-radius: 18px;
  padding: 0 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  animation: slide-up 0.2s ease-out;
}

@keyframes slide-up {
  from { transform: translateY(100%); }
  to   { transform: translateY(0); }
}

.modal-handle {
  width: 40px;
  height: 4px;
  background: #374151;
  border-radius: 2px;
  margin: 12px auto 4px;
}

.modal-panel h3 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 700;
  color: #f9fafb;
  margin: 0;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field label {
  font-size: 13px;
  color: #9ca3af;
  font-weight: 500;
}

.field-input {
  background: #1f2937;
  border: 2px solid #374151;
  border-radius: 10px;
  color: #f9fafb;
  font-size: 16px;
  padding: 10px 14px;
  outline: none;
  font-family: inherit;
  transition: border-color 0.15s;
}

.field-input:focus { border-color: #10b981; }

.field-input-big {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 700;
}

.save-btn {
  background: #10b981;
  color: white;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  border: none;
  border-radius: 12px;
  padding: 14px;
  cursor: pointer;
  min-height: 52px;
  margin-top: 4px;
}

.save-btn:disabled { opacity: 0.4; }

.cancel-btn {
  background: transparent;
  border: 1px solid #1f2937;
  color: #6b7280;
  font-size: 14px;
  font-weight: 600;
  border-radius: 12px;
  padding: 10px;
  cursor: pointer;
}
</style>
