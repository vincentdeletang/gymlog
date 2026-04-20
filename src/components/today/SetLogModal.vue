<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  exercise: Object,
  setNumber: Number,
  existingLog: Object,   // this specific set already logged (edit mode)
  sessionPrevSet: Object, // set N-1 of same exercise in current session (pre-fill)
  previousLog: Object,   // last session hint (display only)
})

const emit = defineEmits(['close', 'save'])

const weightKg = ref('')
const repsDone = ref('')
const rir = ref(2)

const RIR_OPTIONS = [
  { value: 0, label: '0', sub: 'À bloc',   color: '#ef4444' },
  { value: 1, label: '1', sub: '+1',        color: '#f59e0b' },
  { value: 2, label: '2', sub: 'Optimal ✓', color: '#10b981' },
  { value: 3, label: '3', sub: 'Safe',      color: '#10b981' },
  { value: 4, label: '4+', sub: 'Léger',   color: '#6b7280' },
]

watch([() => props.existingLog, () => props.sessionPrevSet], ([log, prev]) => {
  if (log) {
    // Editing an already-logged set → load its values
    weightKg.value = log.weight_kg ?? ''
    repsDone.value = log.reps_done ?? ''
    rir.value = log.rir ?? 2
  } else if (prev) {
    // New set → pre-fill from previous set of this exercise in current session
    weightKg.value = prev.weight_kg ?? ''
    repsDone.value = prev.reps_done ?? ''
    rir.value = prev.rir ?? 2
  } else {
    weightKg.value = ''
    repsDone.value = ''
    rir.value = 2
  }
}, { immediate: true })

function save() {
  emit('save', {
    weightKg: props.exercise?.is_bodyweight ? null : (parseFloat(weightKg.value) || null),
    repsDone: parseInt(repsDone.value) || null,
    rir: rir.value,
  })
}
</script>

<template>
  <teleport to="body">
    <transition name="fade">
      <div class="sheet-overlay" @click.self="emit('close')" />
    </transition>
    <transition name="slide-up">
      <div class="sheet-panel">
        <!-- Handle -->
        <div class="handle" />

        <div class="modal-content">
          <div class="modal-header">
            <h3>{{ exercise?.name }}</h3>
            <span class="set-badge">Série {{ setNumber }}</span>
          </div>

          <!-- Previous hint -->
          <div v-if="previousLog" class="hint">
            <span class="hint-label">Dernière fois :</span>
            <span class="hint-val">
              <template v-if="!exercise?.is_bodyweight && previousLog.weight_kg">
                {{ previousLog.weight_kg }}kg ×
              </template>
              {{ previousLog.reps_done }} reps
              <span v-if="previousLog.rir != null"> · RIR {{ previousLog.rir }}</span>
            </span>
          </div>

          <!-- Weight field (hidden if bodyweight) -->
          <div v-if="!exercise?.is_bodyweight" class="field">
            <label>Poids (kg)</label>
            <input
              v-model="weightKg"
              type="number"
              inputmode="decimal"
              step="0.5"
              min="0"
              placeholder="Ex: 20"
              class="field-input"
            />
          </div>

          <!-- Reps -->
          <div class="field">
            <label>
              Reps réalisés
              <span class="target" v-if="exercise?.reps_target">
                (cible : {{ exercise.reps_target }})
              </span>
            </label>
            <input
              v-model="repsDone"
              type="number"
              inputmode="numeric"
              min="0"
              placeholder="Ex: 10"
              class="field-input"
            />
          </div>

          <!-- RIR selector -->
          <div class="field">
            <label>RIR — Reps en réserve</label>
            <div class="rir-grid">
              <button
                v-for="opt in RIR_OPTIONS"
                :key="opt.value"
                class="rir-btn"
                :class="{ selected: rir === opt.value }"
                :style="rir === opt.value ? { borderColor: opt.color, background: opt.color + '22' } : {}"
                @click="rir = opt.value"
              >
                <span class="rir-val" :style="rir === opt.value ? { color: opt.color } : {}">{{ opt.label }}</span>
                <span class="rir-sub">{{ opt.sub }}</span>
              </button>
            </div>
          </div>

          <!-- Notes -->
          <div v-if="exercise?.notes" class="notes">
            💡 {{ exercise.notes }}
          </div>

          <button class="save-btn" @click="save">
            Valider la série
          </button>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<style scoped>
.handle {
  width: 40px;
  height: 4px;
  background: #374151;
  border-radius: 2px;
  margin: 12px auto 0;
}

.modal-content {
  padding-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.modal-header h3 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 700;
  margin: 0;
  color: #f9fafb;
}

.set-badge {
  background: #1f2937;
  color: #9ca3af;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 20px;
  white-space: nowrap;
}

.hint {
  background: #1f2937;
  border-radius: 8px;
  padding: 8px 12px;
  display: flex;
  gap: 8px;
  align-items: center;
  font-size: 14px;
}

.hint-label {
  color: #9ca3af;
  font-size: 12px;
}

.hint-val {
  color: #60a5fa;
  font-weight: 600;
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

.target {
  color: #6b7280;
}

.field-input {
  background: #1f2937;
  border: 2px solid #374151;
  border-radius: 10px;
  color: #f9fafb;
  font-size: 22px;
  font-family: 'Barlow Condensed', sans-serif;
  font-weight: 700;
  padding: 10px 14px;
  width: 100%;
  outline: none;
  transition: border-color 0.15s;
}

.field-input:focus {
  border-color: #3b82f6;
}

.rir-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 6px;
}

.rir-btn {
  background: #1f2937;
  border: 2px solid #374151;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 4px;
  cursor: pointer;
  transition: all 0.15s;
  min-height: 56px;
}

.rir-val {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 800;
  color: #9ca3af;
  line-height: 1;
}

.rir-sub {
  font-size: 10px;
  color: #6b7280;
  text-align: center;
  margin-top: 2px;
  line-height: 1.2;
}

.notes {
  background: rgba(59, 130, 246, 0.08);
  border: 1px solid rgba(59, 130, 246, 0.2);
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #93c5fd;
}

.save-btn {
  background: #3b82f6;
  color: white;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  border: none;
  border-radius: 12px;
  padding: 14px;
  cursor: pointer;
  transition: background 0.15s, transform 0.1s;
  width: 100%;
  min-height: 52px;
  margin-top: 4px;
}

.save-btn:active {
  background: #2563eb;
  transform: scale(0.98);
}
</style>
