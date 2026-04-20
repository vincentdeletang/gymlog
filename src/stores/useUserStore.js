import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

const LEVELS = [
  { name: 'Recrue',   min: 0 },
  { name: 'Rookie',   min: 500 },
  { name: 'Guerrier', min: 1200 },
  { name: 'Champion', min: 2500 },
  { name: 'Élite',    min: 4500 },
  { name: 'Légende',  min: 8000 },
]

export const useUserStore = defineStore('user', () => {
  const session = ref(null)
  const userState = ref(null)
  const loading = ref(false)

  const user = computed(() => session.value?.user ?? null)
  const isAuthenticated = computed(() => !!user.value)

  const xp = computed(() => userState.value?.xp_total ?? 0)
  const streak = computed(() => userState.value?.streak_current ?? 0)
  const streakBest = computed(() => userState.value?.streak_best ?? 0)

  const currentLevel = computed(() => {
    const x = xp.value
    let lvl = LEVELS[0]
    for (const l of LEVELS) {
      if (x >= l.min) lvl = l
    }
    return lvl
  })

  const nextLevel = computed(() => {
    const idx = LEVELS.findIndex(l => l.name === currentLevel.value.name)
    return LEVELS[idx + 1] ?? null
  })

  const levelProgress = computed(() => {
    if (!nextLevel.value) return 100
    const curr = currentLevel.value.min
    const next = nextLevel.value.min
    return Math.round(((xp.value - curr) / (next - curr)) * 100)
  })

  async function init() {
    const { data: { session: s } } = await supabase.auth.getSession()
    session.value = s
    if (s) await fetchUserState()

    supabase.auth.onAuthStateChange(async (_event, s) => {
      session.value = s
      if (s) await fetchUserState()
      else userState.value = null
    })
  }

  async function sendMagicLink(email) {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/gymlog/` },
    })
    return { error }
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  async function fetchUserState() {
    if (!user.value) return
    const { data } = await supabase
      .from('user_state')
      .select('*')
      .eq('user_id', user.value.id)
      .single()
    if (data) userState.value = data
    else await ensureUserState()
  }

  async function ensureUserState() {
    if (!user.value) return
    const { data } = await supabase
      .from('user_state')
      .upsert({ user_id: user.value.id }, { onConflict: 'user_id' })
      .select()
      .single()
    if (data) userState.value = data
  }

  async function addXP(amount) {
    if (!userState.value) return
    const newXP = (userState.value.xp_total ?? 0) + amount
    const newLevel = computeLevel(newXP)
    const updates = { xp_total: newXP, level: newLevel }
    await supabase.from('user_state').update(updates).eq('user_id', user.value.id)
    userState.value = { ...userState.value, ...updates }
  }

  async function updateStreak(sessionDate) {
    if (!userState.value) return
    const last = userState.value.last_session_date
    const today = sessionDate
    let streak = userState.value.streak_current ?? 0

    if (last) {
      const diff = daysBetween(last, today)
      if (diff === 1 || diff === 0) streak++
      else if (diff === 2) streak++ // tolerate 1 rest day
      else streak = 1
    } else {
      streak = 1
    }

    const best = Math.max(streak, userState.value.streak_best ?? 0)
    const updates = { streak_current: streak, streak_best: best, last_session_date: today }
    await supabase.from('user_state').update(updates).eq('user_id', user.value.id)
    userState.value = { ...userState.value, ...updates }
    return streak
  }

  function computeLevel(xpTotal) {
    let lvl = 1
    for (let i = LEVELS.length - 1; i >= 0; i--) {
      if (xpTotal >= LEVELS[i].min) { lvl = i + 1; break }
    }
    return lvl
  }

  function daysBetween(a, b) {
    const d1 = new Date(a)
    const d2 = new Date(b)
    return Math.round(Math.abs((d2 - d1) / (1000 * 60 * 60 * 24)))
  }

  return {
    session, userState, loading,
    user, isAuthenticated,
    xp, streak, streakBest,
    currentLevel, nextLevel, levelProgress,
    LEVELS,
    init, sendMagicLink, signOut,
    fetchUserState, addXP, updateStreak,
  }
})
