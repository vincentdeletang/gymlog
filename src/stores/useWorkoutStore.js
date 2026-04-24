import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { queueSetLog, syncPendingLogs, pushSetLog, getPendingLogs } from '@/lib/offlineQueue'
import { useUserStore } from './useUserStore'

export const useWorkoutStore = defineStore('workout', () => {
  const currentSession = ref(null)
  const setLogs = ref([]) // set_logs for current session, keyed by exercise_id+set_number
  const loading = ref(false)

  // Previous session data per exercise (for "last time" hint in modal)
  const previousSets = ref({}) // { [exerciseId]: { [setNumber]: { weight_kg, reps_done, rir } } }

  async function startOrResumeSession(programDayId) {
    const userStore = useUserStore()
    const today = new Date().toISOString().slice(0, 10)

    // Check if a session already exists for today
    const { data: existing } = await supabase
      .from('workout_sessions')
      .select('*')
      .eq('user_id', userStore.user.id)
      .eq('program_day_id', programDayId)
      .eq('session_date', today)
      .maybeSingle()

    if (existing) {
      currentSession.value = existing
    } else {
      const { data: created } = await supabase
        .from('workout_sessions')
        .insert({ user_id: userStore.user.id, program_day_id: programDayId, session_date: today })
        .select()
        .single()
      currentSession.value = created
    }

    await syncPendingLogs()
    await loadSetLogs()
    await mergePendingIntoMemory()
    await loadPreviousData(programDayId)
    return currentSession.value
  }

  async function loadSetLogs() {
    if (!currentSession.value) return
    const { data } = await supabase
      .from('set_logs')
      .select('*')
      .eq('session_id', currentSession.value.id)
    setLogs.value = data ?? []
  }

  async function mergePendingIntoMemory() {
    if (!currentSession.value) return
    const pending = await getPendingLogs()
    for (const p of pending) {
      if (p.session_id !== currentSession.value.id) continue
      const { _pending, ...data } = p
      const idx = setLogs.value.findIndex(
        l => l.exercise_id === data.exercise_id && l.set_number === data.set_number
      )
      if (idx >= 0) setLogs.value.splice(idx, 1, data)
      else setLogs.value.push(data)
    }
  }

  async function loadPreviousData(programDayId) {
    const userStore = useUserStore()
    const today = new Date().toISOString().slice(0, 10)

    // Get the last completed session for the same program_day (not today)
    const { data: prevSession } = await supabase
      .from('workout_sessions')
      .select('id')
      .eq('user_id', userStore.user.id)
      .eq('program_day_id', programDayId)
      .eq('completed', true)
      .lt('session_date', today)
      .order('session_date', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (!prevSession) return

    const { data: prevLogs } = await supabase
      .from('set_logs')
      .select('*')
      .eq('session_id', prevSession.id)

    const map = {}
    for (const log of (prevLogs ?? [])) {
      if (!map[log.exercise_id]) map[log.exercise_id] = {}
      map[log.exercise_id][log.set_number] = {
        weight_kg: log.weight_kg,
        reps_done: log.reps_done,
        rir: log.rir,
      }
    }
    previousSets.value = map
  }

  async function logSet({ exerciseId, setNumber, weightKg, repsDone, rir }) {
    if (!currentSession.value) return

    const existing = setLogs.value.find(
      l => l.exercise_id === exerciseId && l.set_number === setNumber
    )

    const payload = {
      id: existing?.id ?? crypto.randomUUID(),
      session_id: currentSession.value.id,
      exercise_id: exerciseId,
      set_number: setNumber,
      weight_kg: weightKg ?? null,
      reps_done: repsDone,
      rir,
      logged_at: new Date().toISOString(),
    }

    if (existing) {
      const idx = setLogs.value.indexOf(existing)
      setLogs.value.splice(idx, 1, { ...existing, ...payload })
    } else {
      setLogs.value.push(payload)
    }

    // Always persist to IndexedDB first — durable even if tab is frozen mid-sync
    await queueSetLog(payload)

    // Background sync with timeout — do NOT await: UI must respond instantly
    // even when mobile networks or frozen sockets would otherwise hang forever
    pushSetLog(payload).catch(() => { /* stays queued, retried on resume/online */ })
  }

  async function completeSession(xpReward) {
    if (!currentSession.value) return false
    const userStore = useUserStore()
    const today = new Date().toISOString().slice(0, 10)
    const completedAt = new Date().toISOString()

    // Optimistic local update — show celebration immediately
    currentSession.value = { ...currentSession.value, completed: true, completed_at: completedAt }
    await userStore.addXP(xpReward)
    await userStore.updateStreak(today)

    // Sync to Supabase in background
    supabase
      .from('workout_sessions')
      .update({ completed: true, completed_at: completedAt })
      .eq('id', currentSession.value.id)
      .then(({ error }) => {
        if (error) console.error('Session sync failed, will retry on next load', error)
      })

    syncPendingLogs()
    return true
  }

  function getSetLog(exerciseId, setNumber) {
    return setLogs.value.find(
      l => l.exercise_id === exerciseId && l.set_number === setNumber
    ) ?? null
  }

  function isSetLogged(exerciseId, setNumber) {
    return !!getSetLog(exerciseId, setNumber)
  }

  function getPreviousSet(exerciseId, setNumber) {
    return previousSets.value[exerciseId]?.[setNumber] ?? null
  }

  // History
  async function fetchHistory(limit = 20) {
    const userStore = useUserStore()
    const { data } = await supabase
      .from('workout_sessions')
      .select('*, program_days(name, type, day_of_week, xp_reward)')
      .eq('user_id', userStore.user.id)
      .order('session_date', { ascending: false })
      .limit(limit)
    return data ?? []
  }

  async function fetchSessionDetail(sessionId) {
    const { data } = await supabase
      .from('set_logs')
      .select('*, exercises(name, section, is_bodyweight, bars(weight_kg))')
      .eq('session_id', sessionId)
      .order('logged_at')
    return data ?? []
  }

  // Stats helpers
  async function fetchWeightProgress(exerciseId, weeks = 8) {
    const userStore = useUserStore()
    const since = new Date()
    since.setDate(since.getDate() - weeks * 7)

    const { data } = await supabase
      .from('set_logs')
      .select('weight_kg, logged_at, set_number, workout_sessions!inner(user_id, session_date)')
      .eq('workout_sessions.user_id', userStore.user.id)
      .eq('exercise_id', exerciseId)
      .gte('workout_sessions.session_date', since.toISOString().slice(0, 10))
      .order('logged_at')
    return data ?? []
  }

  async function fetchWeeklyVolume(weeks = 8) {
    const userStore = useUserStore()
    const since = new Date()
    since.setDate(since.getDate() - weeks * 7)

    const { data } = await supabase
      .from('workout_sessions')
      .select('session_date, completed, program_days(type)')
      .eq('user_id', userStore.user.id)
      .gte('session_date', since.toISOString().slice(0, 10))
      .order('session_date')
    return data ?? []
  }

  async function fetchRIRStats(exerciseId, lastN = 4) {
    const userStore = useUserStore()
    const { data: sessions } = await supabase
      .from('workout_sessions')
      .select('id')
      .eq('user_id', userStore.user.id)
      .eq('completed', true)
      .order('session_date', { ascending: false })
      .limit(lastN)

    if (!sessions?.length) return []
    const sessionIds = sessions.map(s => s.id)

    const { data } = await supabase
      .from('set_logs')
      .select('rir, logged_at')
      .eq('exercise_id', exerciseId)
      .in('session_id', sessionIds)
    return data ?? []
  }

  return {
    currentSession, setLogs, loading, previousSets,
    startOrResumeSession, loadSetLogs, logSet,
    completeSession, getSetLog, isSetLogged, getPreviousSet,
    fetchHistory, fetchSessionDetail,
    fetchWeightProgress, fetchWeeklyVolume, fetchRIRStats,
  }
})
