<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  block: Object,
  existingLog: Object,
})
const emit = defineEmits(['close', 'save'])

const durationMin = ref('')
const avgHr = ref('')
const notes = ref('')

watch(() => props.existingLog, (log) => {
  if (log) {
    durationMin.value = log.duration_seconds ? String(Math.round(log.duration_seconds / 60)) : ''
    avgHr.value       = log.avg_hr ? String(log.avg_hr) : ''
    notes.value       = log.notes ?? ''
  } else {
    durationMin.value = props.block?.duration_minutes ? String(props.block.duration_minutes) : ''
    avgHr.value = ''
    notes.value = ''
  }
}, { immediate: true })

function save() {
  const minutes = parseFloat(durationMin.value)
  const hr = parseInt(avgHr.value)
  emit('save', {
    duration_seconds: minutes > 0 ? Math.round(minutes * 60) : null,
    avg_hr: hr > 0 ? hr : null,
    notes: notes.value.trim() || null,
  })
}
</script>

<template>
  <teleport to="body">
    <div class="overlay" @click.self="emit('close')">
      <div class="panel">
        <div class="handle" />

        <div class="head">
          <h3>{{ block?.name }}</h3>
          <span v-if="block?.duration_minutes" class="target">cible {{ block.duration_minutes }} min</span>
        </div>

        <div class="field">
          <label>Durée réelle (min)</label>
          <input
            v-model="durationMin"
            type="number"
            inputmode="decimal"
            step="0.5"
            min="0"
            class="input-big"
            autofocus
          />
        </div>

        <div class="field">
          <label>FC moyenne (bpm) <span class="hint">— optionnel, pour valider la zone</span></label>
          <input
            v-model="avgHr"
            type="number"
            inputmode="numeric"
            min="40"
            max="250"
            placeholder="Ex: 130"
            class="input-big"
          />
        </div>

        <div class="field">
          <label>Notes <span class="hint">— optionnel</span></label>
          <textarea
            v-model="notes"
            placeholder="Sensation, intensité, météo…"
            class="input-area"
            rows="2"
          />
        </div>

        <button class="save-btn" @click="save">
          {{ existingLog ? 'Mettre à jour' : 'Valider' }}
        </button>
        <button class="cancel-btn" @click="emit('close')">Annuler</button>
      </div>
    </div>
  </teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(10,14,23,0.7);
  backdrop-filter: blur(4px);
  z-index: 100;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.panel {
  width: 100%;
  max-width: 480px;
  background: #0f1623;
  border-top-left-radius: 18px;
  border-top-right-radius: 18px;
  padding: 0 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  animation: up 0.2s ease-out;
}

@keyframes up { from { transform: translateY(100%); } to { transform: translateY(0); } }

.handle {
  width: 40px; height: 4px; background: #374151; border-radius: 2px; margin: 12px auto 4px;
}

.head { display: flex; align-items: baseline; justify-content: space-between; gap: 10px; }
.head h3 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px; font-weight: 700; color: #f9fafb; margin: 0;
}
.target {
  font-size: 12px; color: #6b7280;
  font-family: 'Barlow Condensed', sans-serif;
  letter-spacing: 0.3px;
}

.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; color: #9ca3af; font-weight: 500; }
.hint { color: #4b5563; font-weight: 400; }

.input-big {
  background: #1f2937;
  border: 2px solid #374151;
  border-radius: 10px;
  color: #f9fafb;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 22px;
  font-weight: 700;
  padding: 10px 14px;
  outline: none;
}
.input-big:focus { border-color: #f59e0b; }

.input-area {
  background: #1f2937;
  border: 2px solid #374151;
  border-radius: 10px;
  color: #f9fafb;
  font-size: 14px;
  padding: 10px 12px;
  outline: none;
  resize: none;
  font-family: inherit;
}
.input-area:focus { border-color: #f59e0b; }

.save-btn {
  background: #f59e0b;
  color: #1a1a1a;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  border: none;
  border-radius: 12px;
  padding: 14px;
  cursor: pointer;
  min-height: 52px;
}

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
