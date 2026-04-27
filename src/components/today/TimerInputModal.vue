<script setup>
import { ref, watch, onUnmounted } from 'vue'

const props = defineProps({
  exercise: Object,
  setNumber: Number,
  targetSeconds: Number,
  targetMax: Number,
  isRange: Boolean,
  existingLog: Object,
})

const emit = defineEmits(['close', 'save', 'delete'])

const seconds = ref('')
const perSide = () => !!props.exercise?.is_per_side

watch(() => [props.existingLog, props.targetSeconds], ([log, target]) => {
  if (log?.reps_done != null) seconds.value = String(log.reps_done)
  else if (target) seconds.value = String(perSide() ? target * 2 : target)
  else seconds.value = ''
}, { immediate: true })

const targetLabel = () => {
  if (!props.targetSeconds) return ''
  const base = props.isRange ? `${props.targetSeconds}-${props.targetMax}s` : `${props.targetSeconds}s`
  return perSide() ? `${base} × 2 côtés` : base
}

function save() {
  const s = parseInt(seconds.value)
  if (!s || s <= 0) return
  emit('save', { seconds: s })
}

function confirmDelete() {
  if (window.confirm('Supprimer cette série ?')) emit('delete')
}

onUnmounted(() => {
  document.querySelectorAll('body > .sheet-overlay, body > .sheet-panel').forEach(el => el.remove())
})
</script>

<template>
  <teleport to="body">
    <transition name="fade">
      <div class="sheet-overlay" @click.self="emit('close')" />
    </transition>
    <transition name="slide-up">
      <div class="sheet-panel">
        <div class="handle" />
        <div class="modal-content">
          <div class="modal-header">
            <h3>{{ exercise?.name }}</h3>
            <span class="set-badge">Série {{ setNumber }}</span>
          </div>

          <div class="field">
            <label>
              Durée tenue (secondes)
              <span class="target" v-if="targetSeconds">(cible : {{ targetLabel() }})</span>
            </label>
            <input
              v-model="seconds"
              type="number"
              inputmode="numeric"
              min="1"
              placeholder="Ex: 30"
              class="field-input"
              autofocus
            />
          </div>

          <div v-if="exercise?.notes" class="notes">💡 {{ exercise.notes }}</div>

          <button class="save-btn" @click="save">
            {{ existingLog ? 'Mettre à jour' : 'Valider la série' }}
          </button>

          <button v-if="existingLog" class="delete-btn" @click="confirmDelete">
            🗑 Supprimer cette série
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

.target { color: #6b7280; }

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

.field-input:focus { border-color: #3b82f6; }

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

.delete-btn {
  background: transparent;
  color: #ef4444;
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 12px;
  padding: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  width: 100%;
  min-height: 44px;
  margin-top: 4px;
  transition: background 0.15s;
}

.delete-btn:active {
  background: rgba(239,68,68,0.08);
}
</style>
