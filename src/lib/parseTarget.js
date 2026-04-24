export function parseTimeTarget(repsTarget) {
  if (!repsTarget) return null
  const match = String(repsTarget).match(/^\s*(\d+)(?:\s*-\s*(\d+))?\s*s\b/i)
  if (!match) return null
  const min = parseInt(match[1], 10)
  const max = match[2] ? parseInt(match[2], 10) : min
  return { min, max, isRange: max > min }
}

export function isTimed(repsTarget) {
  return parseTimeTarget(repsTarget) !== null
}
