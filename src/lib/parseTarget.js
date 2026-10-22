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

// « 8-12/jambe, jusqu'à 2 en réserve » → range « 8-12/jambe », cue « jusqu'à 2 en réserve ».
// Un premier segment d'un seul mot après le « / » est une unité (jambe, côté), il reste
// collé à la plage ; le reste est la consigne libre, affichée sous le nom de l'exo.
export function splitTarget(repsTarget) {
  const raw = String(repsTarget ?? '').trim()
  const i = raw.indexOf('/')
  if (i === -1) return { range: raw, cue: '' }
  let range = raw.slice(0, i).trim()
  const segments = raw.slice(i + 1).split(',').map(s => s.trim()).filter(Boolean)
  if (segments.length && !/\s/.test(segments[0])) range += '/' + segments.shift()
  return { range, cue: segments.join(', ') }
}
