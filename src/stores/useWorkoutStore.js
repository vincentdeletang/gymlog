import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { queueSetLog, syncPendingLogs, pushSetLog, getPendingLogs, removePendingLog } from '@/lib/offlineQueue'
import { useUserStore } from './useUserStore'
import { todayISO } from '@/lib/formatDate'

export const useWorkoutStore = defineStore('workout', () => {
  const currentSession = ref(null)
  const setLogs = ref([]) // set_logs for current session, keyed by exercise_id+set_number
  const cardioLogs = ref([]) // cardio_block_logs for current session
  const loading = ref(false)

  // Previous session data per exercise (for "last time" hint in modal)
  const previousSets = ref({}) // { [exerciseId]: { [setNumber]: { weight_kg, reps_done, rir } } }

  async function startOrResumeSession(programDayId, targetDate = todayISO()) {
    const userStore = useUserStore()

    // Clear state from any previous session so stale data doesn't flash during the swap
    currentSession.value = null
    setLogs.value = []
    cardioLogs.value = []
    previousSets.value = {}

    const { data: existing } = await supabase
      .from('workout_sessions')
      .select('*')
      .eq('user_id', userStore.user.id)
      .eq('program_day_id', programDayId)
      .eq('session_date', targetDate)
      .maybeSingle()

    if (existing) {
      currentSession.value = existing
    } else {
      const { data: created } = await supabase
        .from('workout_sessions')
        .insert({ user_id: userStore.user.id, program_day_id: programDayId, session_date: targetDate })
        .select()
        .single()
      currentSession.value = created
    }

    await syncPendingLogs()
    await loadSetLogs()
    await mergePendingIntoMemory()
    await loadCardioLogs()
    await loadPreviousData(programDayId, targetDate)
    return currentSession.value
  }

  async function loadCardioLogs() {
    if (!currentSession.value) return
    const { data } = await supabase
      .from('cardio_block_logs')
      .select('*')
      .eq('session_id', currentSession.value.id)
    cardioLogs.value = data ?? []
  }

  function isCardioDone(blockId) {
    return cardioLogs.value.some(l => l.cardio_block_id === blockId)
  }

  function markCardioDone(blockId) {
    if (!currentSession.value || isCardioDone(blockId)) return
    const payload = {
      id: crypto.randomUUID(),
      session_id: currentSession.value.id,
      cardio_block_id: blockId,
      completed_at: new Date().toISOString(),
    }
    cardioLogs.value.push(payload)

    const controller = new AbortController()
    setTimeout(() => controller.abort(), 8000)
    supabase.from('cardio_block_logs').insert(payload).abortSignal(controller.signal)
      .then(({ error }) => { if (error) console.warn('cardio mark sync failed', error) })
      .catch(() => {})
  }

  function unmarkCardioDone(blockId) {
    if (!currentSession.value) return
    const log = cardioLogs.value.find(l => l.cardio_block_id === blockId)
    if (!log) return
    cardioLogs.value = cardioLogs.value.filter(l => l.cardio_block_id !== blockId)

    const controller = new AbortController()
    setTimeout(() => controller.abort(), 8000)
    supabase.from('cardio_block_logs').delete().eq('id', log.id).abortSignal(controller.signal)
      .then(({ error }) => { if (error) console.warn('cardio unmark sync failed', error) })
      .catch(() => {})
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

  async function loadPreviousData(programDayId, targetDate = todayISO()) {
    const userStore = useUserStore()

    // Last completed session for the same program_day, strictly before targetDate
    const { data: prevSession } = await supabase
      .from('workout_sessions')
      .select('id')
      .eq('user_id', userStore.user.id)
      .eq('program_day_id', programDayId)
      .eq('completed', true)
      .lt('session_date', targetDate)
      .order('session_date', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (!prevSession) {
      previousSets.value = {}
      return
    }

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

  async function deleteSetLog(exerciseId, setNumber) {
    if (!currentSession.value) return
    const entry = setLogs.value.find(
      l => l.exercise_id === exerciseId && l.set_number === setNumber
    )
    if (!entry) return

    setLogs.value = setLogs.value.filter(l => l.id !== entry.id)

    // Pull from offline queue if it never made it out
    try { await removePendingLog(entry.id) } catch { /* ignore */ }

    // Best-effort delete from Supabase (no-op if it never synced)
    const controller = new AbortController()
    setTimeout(() => controller.abort(), 8000)
    supabase.from('set_logs').delete().eq('id', entry.id).abortSignal(controller.signal)
      .then(({ error }) => { if (error) console.warn('set delete sync failed', error) })
      .catch(() => {})
  }

  async function completeSession(xpReward) {
    if (!currentSession.value) return false
    if (currentSession.value.completed) return false // already done — no double XP/streak

    const userStore = useUserStore()
    const sessionDate = currentSession.value.session_date
    const completedAt = new Date().toISOString()
    const isCatchUp = sessionDate !== todayISO()

    // Optimistic local update — show celebration immediately
    currentSession.value = { ...currentSession.value, completed: true, completed_at: completedAt }
    await userStore.addXP(xpReward)
    if (!isCatchUp) {
      await userStore.updateStreak(sessionDate)
    }

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

  async function fetchSessionCardio(session) {
    if (!session?.program_day_id) return []
    const { data: blocks } = await supabase
      .from('cardio_blocks')
      .select('*')
      .eq('program_day_id', session.program_day_id)
      .order('order_index')
    const { data: logs } = await supabase
      .from('cardio_block_logs')
      .select('cardio_block_id')
      .eq('session_id', session.id)
    const done = new Set((logs ?? []).map(l => l.cardio_block_id))
    return (blocks ?? []).map(b => ({ ...b, completed: done.has(b.id) }))
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
    currentSession, setLogs, cardioLogs, loading, previousSets,
    startOrResumeSession, loadSetLogs, logSet, deleteSetLog,
    completeSession, getSetLog, isSetLogged, getPreviousSet,
    isCardioDone, markCardioDone, unmarkCardioDone,
    fetchHistory, fetchSessionDetail, fetchSessionCardio,
    fetchWeightProgress, fetchWeeklyVolume, fetchRIRStats,
  }
})
