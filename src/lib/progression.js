export const MODE_WEIGHT = 'weight'
export const MODE_REPS = 'reps'

// Plafond du mode reps : au-delà, la série devient trop longue pour rester un bon
// stimulus d'hypertrophie. On arrête de proposer +1 rep et on suggère la charge.
export const REPS_CEILING = 20

export function parseRepsTarget(target) {
  if (!target || /s$/.test(target)) return null
  const clean = target.replace(/\/.*$/, '').trim()
  const match = clean.match(/^(\d+)-(\d+)$/)
  if (match) return { min: parseInt(match[1]), max: parseInt(match[2]) }
  const single = clean.match(/^(\d+)$/)
  if (single) return { min: parseInt(single[1]), max: parseInt(single[1]) }
  return null
}

export function progressionMode(exercise) {
  return exercise?.progression_mode === MODE_REPS ? MODE_REPS : MODE_WEIGHT
}

// Cible de la prochaine séance, selon le mode de progression de l'exo.
//   mode 'weight' : reps plafonnées par reps_target, la CHARGE monte de 2kg
//   mode 'reps'   : charge figée, les REPS montent de 1
// Retourne { mode, weight, reps, increased, atCeiling } ou null si pas d'historique.
export function nextTarget(previousLog, exercise) {
  if (!previousLog) return null
  const mode = progressionMode(exercise)
  const goodRIR = previousLog.rir == null || previousLog.rir >= 2

  if (mode === MODE_REPS) {
    if (previousLog.reps_done == null) return null
    const hold = exercise?.hold_weight_kg
    // Charge figée en dessous du dernier log : les reps de l'ancienne charge ne disent
    // rien sur la nouvelle, on repart sur la plage reps_target.
    if (hold != null && Number(hold) !== Number(previousLog.weight_kg)) {
      return { mode: MODE_REPS, weight: Number(hold), reps: null, increased: false, atCeiling: false, reset: true }
    }
    const atCeiling = previousLog.reps_done >= REPS_CEILING
    const increased = goodRIR && !atCeiling
    return {
      mode: MODE_REPS,
      weight: hold != null ? Number(hold) : (previousLog.weight_kg ?? null),
      reps: increased ? previousLog.reps_done + 1 : previousLog.reps_done,
      increased,
      atCeiling,
    }
  }

  if (!previousLog.weight_kg) return null
  const range = parseRepsTarget(exercise?.reps_target)
  if (!range) return { mode: MODE_WEIGHT, weight: previousLog.weight_kg, reps: null, increased: false, atCeiling: false }

  const hitTop = previousLog.reps_done != null && previousLog.reps_done >= range.max
  const increased = hitTop && goodRIR
  return {
    mode: MODE_WEIGHT,
    weight: increased ? previousLog.weight_kg + 2 : previousLog.weight_kg,
    reps: null,
    increased,
    atCeiling: false,
  }
}

// Reps attendues pour la série 1 d'une nouvelle séance, pré-remplies dans la modal
// (demande du 22/10/2026 : « généralement c'est ce que je fais »).
//   mode 'reps'   : l'objectif de nextTarget, ou le bas de la plage après un reset
//   mode 'weight' : bas de la plage si la charge vient de monter, +1 rep tant qu'on est
//                   sous le haut de la plage avec un RIR correct, sinon ce qui a été fait
export function expectedReps(previousLog, exercise) {
  if (previousLog?.reps_done == null) return null
  const next = nextTarget(previousLog, exercise)
  const range = parseRepsTarget(exercise?.reps_target)
  if (next?.mode === MODE_REPS) return next.reps ?? range?.min ?? null
  if (!range) return previousLog.reps_done
  if (next?.increased) return range.min
  if (previousLog.reps_done >= range.max) return previousLog.reps_done
  const goodRIR = previousLog.rir == null || previousLog.rir >= 2
  return goodRIR ? Math.min(previousLog.reps_done + 1, range.max) : previousLog.reps_done
}
