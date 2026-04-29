// Mirror de progression.js mais pour la durée cardio.
// Règle : si les 2 dernières séances ont été complétées à un même niveau (ou plus),
// on suggère le palier suivant (+ progression_step_minutes), capé au plafond.
// Sinon on tient le palier courant.
//
// previousLogs : array de cardio_block_logs filtrés sur ce bloc, plus récent en premier.
// block        : { duration_minutes, duration_target_max_minutes, progression_step_minutes }
//
// Retourne { duration, increased, atMax } — duration est la cible affichée pour ce bloc.
export function suggestedDuration(previousLogs, block) {
  if (!block) return null
  const base = block.duration_minutes ?? 0
  const max = block.duration_target_max_minutes ?? null
  const step = block.progression_step_minutes ?? 2

  const lastTwo = (previousLogs ?? [])
    .filter(l => l.duration_seconds != null)
    .slice(0, 2)
    .map(l => Math.round(l.duration_seconds / 60))

  if (lastTwo.length === 0) {
    return { duration: base, increased: false, atMax: max != null && base >= max }
  }

  // Niveau plancher tenu sur les dernières séances (ou seul log si une seule)
  const consistentLevel = lastTwo.length >= 2 ? Math.min(...lastTwo) : lastTwo[0]
  // La cible courante = max(prescription programme, niveau effectivement tenu)
  const currentTarget = Math.max(base, consistentLevel)

  // Bump si on a au moins 2 logs et qu'ils ont tous tenu currentTarget
  const ready = lastTwo.length >= 2 && lastTwo.every(d => d >= currentTarget)

  if (ready) {
    const next = max != null ? Math.min(currentTarget + step, max) : currentTarget + step
    if (next > currentTarget) {
      return { duration: next, increased: true, atMax: max != null && next >= max }
    }
  }

  return { duration: currentTarget, increased: false, atMax: max != null && currentTarget >= max }
}

// Helper pour le delta loggé vs target une fois la séance faite.
// Retourne null si pas de log ou pas de durée loggée.
export function durationDelta(loggedSeconds, targetMinutes) {
  if (loggedSeconds == null || targetMinutes == null) return null
  const loggedMin = Math.round(loggedSeconds / 60)
  return loggedMin - targetMinutes
}
