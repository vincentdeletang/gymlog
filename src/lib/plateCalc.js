// Greedy decomposition of a total disc weight into available plates.
// Returns array of { kg, count } sorted by plate size desc, or null if exact match impossible.

const DEFAULT_PLATES = [20, 15, 10, 5, 2.5, 1.25, 1]
const EPSILON = 0.001

export function decomposeWeight(totalKg, plates = DEFAULT_PLATES) {
  if (!totalKg || totalKg <= 0) return null
  const sorted = [...plates].sort((a, b) => b - a)
  let remaining = totalKg
  const out = []
  for (const p of sorted) {
    if (remaining < p - EPSILON) continue
    const count = Math.floor((remaining + EPSILON) / p)
    if (count > 0) {
      out.push({ kg: p, count })
      remaining -= p * count
    }
  }
  if (remaining > EPSILON) return null
  return out
}

export function formatDecomposition(decomp) {
  if (!decomp) return null
  return decomp
    .map(d => `${d.count}×${d.kg}`)
    .join(' + ')
}
