// Enchaînement des séries et matériel à préparer (QoL du 28/10/2026).
// Fonctions pures : tout ce qui touche au store passe en paramètre (isLogged).

import { isTimed } from './parseTarget.js'
import { nextTarget } from './progression.js'
import { decomposeWeight, formatDecomposition } from './plateCalc.js'

// Les exos du même jour qui partagent superset_group, dans l'ordre du programme.
export function groupOf(exercise, dayExercises) {
  if (!exercise?.superset_group) return [exercise]
  return dayExercises
    .filter(e => e.superset_group === exercise.superset_group && e.section === exercise.section)
    .sort((a, b) => a.order_index - b.order_index)
}

// Après une série fraîchement loguée : le partenaire à faire tout de suite (même numéro de
// série, pas encore logué), en partant de l'exo suivant dans la paire. null = la paire est
// bouclée pour ce tour, le repos peut partir.
export function partnerAfter(exercise, setNumber, dayExercises, isLogged) {
  const group = groupOf(exercise, dayExercises)
  if (group.length < 2) return null
  const i = group.findIndex(e => e.id === exercise.id)
  for (let k = 1; k < group.length; k++) {
    const p = group[(i + k) % group.length]
    if (setNumber <= p.sets_target && !isLogged(p.id, setNumber)) return p
  }
  return null
}

// À la fin du repos : la prochaine série à ouvrir. Paire → le 1er exo de la paire qui a encore
// une série au tour suivant ; exo seul → sa série suivante. On ne saute jamais d'exo.
export function nextAfterRest(exercise, setNumber, dayExercises, isLogged) {
  const group = groupOf(exercise, dayExercises)
  for (let n = setNumber + 1; n <= Math.max(...group.map(e => e.sets_target)); n++) {
    const e = group.find(g => n <= g.sets_target && !isLogged(g.id, n))
    if (e) return { exercise: e, setNumber: n }
  }
  return null
}

// Une série qui s'ouvre seule doit être une modale (charge + reps) : un chrono démarrerait son
// compte à rebours avant que tu sois en position, une case de prévention n'a rien à remplir.
export function canAutoOpen(exercise) {
  return exercise?.section === 'main' && !isTimed(exercise.reps_target)
}

// La ligne « à préparer » : le matériel de chaque exo (colonne setup) et les charges du jour,
// dans l'ordre de la séance, sans doublon (curl et overhead partagent la même barre).
export function prepItems(exercises, getPreviousSet, plates) {
  const out = []
  const seen = new Set()
  const push = (s) => { if (s && !seen.has(s)) { seen.add(s); out.push(s) } }
  for (const ex of exercises) {
    if (ex.bars?.name && !ex.is_bodyweight) {
      const prev = getPreviousSet(ex.id, 1)
      const w = ex.hold_weight_kg != null
        ? Number(ex.hold_weight_kg)
        : (nextTarget(prev, ex)?.weight ?? prev?.weight_kg ?? null)
      if (w) {
        const perSide = decomposeWeight(w / 2, plates)
        const detail = perSide ? ` (${formatDecomposition(perSide)} par côté)` : ''
        push(`${ex.bars.name} : ${w} kg de disques${detail}`)
      } else {
        push(ex.bars.name)
      }
    }
    push(ex.setup)
  }
  return out
}
