export function parseRepsTarget(target) {
  if (!target || /s$/.test(target)) return null
  const clean = target.replace(/\/.*$/, '').trim()
  const match = clean.match(/^(\d+)-(\d+)$/)
  if (match) return { min: parseInt(match[1]), max: parseInt(match[2]) }
  const single = clean.match(/^(\d+)$/)
  if (single) return { min: parseInt(single[1]), max: parseInt(single[1]) }
  return null
}

// Returns { weight, increased } — the suggested weight for next set based on last session
export function suggestedWeight(previousLog, repsTarget) {
  if (!previousLog?.weight_kg) return null
  const range = parseRepsTarget(repsTarget)
  if (!range) return { weight: previousLog.weight_kg, increased: false }
  const hitTop = previousLog.reps_done != null && previousLog.reps_done >= range.max
  const goodRIR = previousLog.rir == null || previousLog.rir >= 2
  const increased = hitTop && goodRIR
  return { weight: increased ? previousLog.weight_kg + 2 : previousLog.weight_kg, increased }
}
