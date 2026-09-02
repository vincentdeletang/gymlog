<script setup>
import { ref, computed, watch, onUnmounted } from 'vue'
import { nextTarget, progressionMode, parseRepsTarget, MODE_WEIGHT, MODE_REPS, REPS_CEILING } from '@/lib/progression'
import { useProgramStore } from '@/stores/useProgramStore'
import { decomposeWeight, formatDecomposition } from '@/lib/plateCalc'
import ExerciseNotes from '@/components/shared/ExerciseNotes.vue'

const props = defineProps({
  exercise: Object,
  setNumber: Number,
  existingLog: Object,   // this specific set already logged (edit mode)
  sessionPrevSet: Object, // set N-1 of same exercise in current session (pre-fill)
  previousLog: Object,   // last session hint (display only)
})

const emit = defineEmits(['close', 'save', 'delete'])

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


watch([() => props.existingLog, () => props.sessionPrevSet, () => props.previousLog], ([log, prev, last]) => {
  if (log) {
    weightKg.value = log.weight_kg ?? ''
    repsDone.value = log.reps_done ?? ''
    rir.value = log.rir ?? 2
  } else if (prev) {
    weightKg.value = prev.weight_kg ?? ''
    repsDone.value = prev.reps_done ?? ''
    rir.value = prev.rir ?? 2
  } else if (last?.weight_kg) {
    // First set of session → charge pré-remplie selon la progression.
    // Les reps ne sont JAMAIS pré-remplies, même en mode reps : la charge se vérifie
    // sur la barre, les reps se comptent. Pré-remplir un objectif de reps le
    // transformerait en donnée tapée par réflexe, et c'est cette donnée qui pilote
    // toute la progression. L'objectif est affiché dans le badge à la place.
    const next = nextTarget(last, props.exercise)
    weightKg.value = String(next?.weight ?? last.weight_kg)
    repsDone.value = ''
    rir.value = 2
  } else {
    weightKg.value = ''
    repsDone.value = ''
    rir.value = 2
  }
}, { immediate: true })

const totalWeight = computed(() => {
  const discs = parseFloat(weightKg.value)
  const tare = props.exercise?.bars?.weight_kg ?? 0
  if (!discs || !tare) return null
  return discs + tare
})

const plateBreakdown = computed(() => {
  const discs = parseFloat(weightKg.value)
  if (!discs || discs <= 0) return null
  const hasBar = !!props.exercise?.bars
  const perSide = hasBar ? discs / 2 : discs
  const decomp = decomposeWeight(perSide)
  if (!decomp) return null
  const formatted = formatDecomposition(decomp)
  return hasBar ? `${formatted} kg par côté` : `${formatted} kg`
})

const mode = computed(() => progressionMode(props.exercise))
const canSwitchMode = computed(() =>
  props.exercise?.section === 'main' && !!props.previousLog
)

const progression = computed(() => {
  if (!props.previousLog) return null
  const prev = props.previousLog
  const next = nextTarget(prev, props.exercise)
  if (!next) return null

  const load = prev.weight_kg != null ? `${prev.weight_kg}kg × ` : ''

  if (next.mode === MODE_REPS) {
    if (next.reset) {
      return {
        icon: '🔒',
        text: `Charge figée à ${next.weight}kg — repars sur ${props.exercise.reps_target} reps`,
        color: '#3b82f6',
      }
    }
    if (next.atCeiling) {
      return {
        icon: '🏁',
        text: `${load}${prev.reps_done} reps — plafond atteint. Reste ici, ou +2kg et tu repars plus bas.`,
        color: '#f59e0b',
      }
    }
    if (!next.increased) {
      return {
        icon: '⚠️',
        text: `${load}${prev.reps_done} reps à RIR ${prev.rir} — maintiens ${prev.reps_done}`,
        color: '#f59e0b',
      }
    }
    return {
      icon: '🎯',
      text: `${load}${prev.reps_done} reps — Objectif : ${next.reps} reps`,
      color: '#10b981',
    }
  }

  if (props.exercise?.is_bodyweight) return null

  const range = parseRepsTarget(props.exercise?.reps_target)
  if (!range) return { icon: '📊', text: `Dernière fois : ${prev.weight_kg}kg`, color: '#9ca3af' }

  if (next.increased) {
    return {
      icon: '🚀',
      text: `${prev.weight_kg}kg × ${prev.reps_done} reps — Augmente → ${next.weight}kg`,
      color: '#10b981',
    }
  }
  if (prev.reps_done != null && prev.reps_done >= range.max) {
    return {
      icon: '⚠️',
      text: `${prev.weight_kg}kg × ${prev.reps_done} reps mais RIR ${prev.rir} — maintiens`,
      color: '#f59e0b',
    }
  }
  return {
    icon: '↗',
    text: `${prev.weight_kg}kg × ${prev.reps_done ?? '?'} reps — vise ${range.max} reps avant d'augmenter`,
    color: '#3b82f6',
  }
})

async function switchMode() {
  const programStore = useProgramStore()
  const target = mode.value === MODE_REPS ? MODE_WEIGHT : MODE_REPS
  const w = props.previousLog?.weight_kg
  const msg = target === MODE_REPS
    ? `Passer « ${props.exercise.name} » en progression REPS ?\n\nLa charge reste à ${w ?? '?'}kg et l'objectif monte d'1 rep par séance (plafond ${REPS_CEILING}).`
    : `Repasser « ${props.exercise.name} » en progression CHARGE ?\n\nLes reps repassent sur la plage ${props.exercise.reps_target} et la charge remonte de 2kg quand tu tapes le haut.`
  if (!window.confirm(msg)) return
  await programStore.updateProgressionMode(props.exercise.id, target)
}

function save() {
  emit('save', {
    weightKg: props.exercise?.is_bodyweight ? null : (parseFloat(weightKg.value) || null),
    repsDone: parseInt(repsDone.value) || null,
    rir: rir.value,
  })
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
        <!-- Handle -->
        <div class="handle" />

        <div class="modal-content">
          <div class="modal-header">
            <h3>{{ exercise?.name }}</h3>
            <span class="set-badge">Série {{ setNumber }}</span>
          </div>

          <!-- Previous session block -->
          <div v-if="previousLog" class="prev-block">
            <div class="prev-row">
              <span class="prev-label">Dernière fois</span>
              <span class="prev-vals">
                <template v-if="!exercise?.is_bodyweight && previousLog.weight_kg">
                  <strong>{{ previousLog.weight_kg }}kg</strong> ×
                </template>
                {{ previousLog.reps_done }} reps
                <span v-if="previousLog.rir != null" class="prev-rir">RIR {{ previousLog.rir }}</span>
              </span>
            </div>
            <div v-if="progression" class="progression-badge" :style="{ color: progression.color, borderColor: progression.color + '44', background: progression.color + '11' }">
              {{ progression.icon }} {{ progression.text }}
            </div>
            <button v-if="canSwitchMode" type="button" class="mode-switch" @click="switchMode">
              <template v-if="mode === MODE_REPS">
                Progression <strong>reps</strong> — charge figée · <span class="mode-alt">passer en charge</span>
              </template>
              <template v-else>
                Progression <strong>charge</strong> — +2kg au max de la plage · <span class="mode-alt">figer la charge</span>
              </template>
            </button>
          </div>

          <!-- Weight field (hidden if bodyweight) -->
          <div v-if="!exercise?.is_bodyweight" class="field">
            <label>
              Disques (kg)
              <span v-if="exercise?.bars" class="target">+ {{ exercise.bars.weight_kg }}kg {{ exercise.bars.name }}</span>
            </label>
            <input
              v-model="weightKg"
              type="number"
              inputmode="decimal"
              step="0.5"
              min="0"
              placeholder="Ex: 20"
              class="field-input"
            />
            <div v-if="plateBreakdown" class="plates-hint">
              <span class="plates-icon">⚖️</span> {{ plateBreakdown }}
            </div>
            <div v-if="totalWeight" class="total-hint">→ {{ totalWeight }} kg charge totale</div>
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

          <!-- Notes (repliées par défaut, dépliables à la demande) -->
          <div v-if="exercise?.notes" class="notes">
            <ExerciseNotes :notes="exercise.notes" />
          </div>

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

.prev-block {
  background: #1f2937;
  border-radius: 10px;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.prev-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.prev-label {
  font-size: 11px;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 600;
}

.prev-vals {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  color: #e5e7eb;
  font-weight: 600;
}

.prev-vals strong {
  color: #60a5fa;
  font-size: 18px;
}

.prev-rir {
  font-size: 12px;
  color: #9ca3af;
  margin-left: 4px;
}

.progression-badge {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  font-weight: 700;
  padding: 6px 10px;
  border-radius: 8px;
  border: 1px solid;
  letter-spacing: 0.3px;
}

.mode-switch {
  width: 100%;
  margin-top: 6px;
  background: transparent;
  border: 1px dashed #374151;
  border-radius: 8px;
  padding: 6px 10px;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  color: #9ca3af;
  text-align: left;
  cursor: pointer;
}

.mode-switch strong {
  color: #e5e7eb;
}

.mode-alt {
  color: #60a5fa;
  text-decoration: underline;
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

.total-hint {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #6b7280;
  letter-spacing: 0.3px;
}

.plates-hint {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #60a5fa;
  letter-spacing: 0.3px;
  background: rgba(59,130,246,0.08);
  border: 1px solid rgba(59,130,246,0.2);
  border-radius: 6px;
  padding: 4px 8px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  align-self: flex-start;
}

.plates-icon {
  font-size: 13px;
}

.notes {
  background: #1f2937;
  border: 1px solid #374151;
  border-radius: 8px;
  padding: 8px 12px;
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
