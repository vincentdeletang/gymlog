import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useUserStore = defineStore('user', () => {
  const session = ref(null)
  const userState = ref(null)
  const loading = ref(false)

  const user = computed(() => session.value?.user ?? null)
  const isAuthenticated = computed(() => !!user.value)

  const streak = computed(() => userState.value?.streak_current ?? 0)
  const streakBest = computed(() => userState.value?.streak_best ?? 0)
  const profileData = computed(() => userState.value?.profile_data ?? { profil: '', objectifs: '' })

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
      options: { emailRedirectTo: `${window.location.origin}${import.meta.env.BASE_URL}` },
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

  function daysBetween(a, b) {
    const d1 = new Date(a)
    const d2 = new Date(b)
    return Math.round(Math.abs((d2 - d1) / (1000 * 60 * 60 * 24)))
  }

  async function saveProfileData(profil, objectifs) {
    if (!user.value) return false
    const payload = { profil: profil ?? '', objectifs: objectifs ?? '' }
    const { error } = await supabase
      .from('user_state')
      .update({ profile_data: payload })
      .eq('user_id', user.value.id)
    if (error) return false
    if (userState.value) userState.value.profile_data = payload
    return true
  }

  return {
    session, userState, loading,
    user, isAuthenticated,
    streak, streakBest, profileData,
    init, sendMagicLink, signOut,
    fetchUserState, updateStreak, saveProfileData,
  }
})
