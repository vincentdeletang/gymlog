// Greedy decomposition of a total disc weight into available plates.
// Returns array of { kg, count } sorted by plate size desc, or null if exact match impossible.

export const DEFAULT_PLATES = [20, 15, 10, 5, 2.5, 1.25, 1]
const STORAGE_KEY = 'gymlog.availablePlates'
const EPSILON = 0.001

export function getAvailablePlates() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return DEFAULT_PLATES
    const parsed = JSON.parse(raw)
    if (Array.isArray(parsed) && parsed.length > 0 && parsed.every(n => typeof n === 'number' && n > 0)) {
      return parsed
    }
  } catch {}
  return DEFAULT_PLATES
}

export function setAvailablePlates(plates) {
  if (!Array.isArray(plates) || plates.length === 0) return false
  const cleaned = [...new Set(plates.filter(n => typeof n === 'number' && n > 0))]
    .sort((a, b) => b - a)
  if (cleaned.length === 0) return false
  localStorage.setItem(STORAGE_KEY, JSON.stringify(cleaned))
  return true
}

export function parsePlatesString(s) {
  if (typeof s !== 'string') return null
  const parts = s.split(/[,;\s]+/).filter(Boolean)
  const nums = parts.map(p => parseFloat(p.replace(',', '.'))).filter(n => !isNaN(n) && n > 0)
  if (!nums.length) return null
  return [...new Set(nums)].sort((a, b) => b - a)
}

export function decomposeWeight(totalKg, plates) {
  if (!totalKg || totalKg <= 0) return null
  const list = plates ?? getAvailablePlates()
  const sorted = [...list].sort((a, b) => b - a)
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
