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

  // Best e1RM per exercise across all completed sessions BEFORE this session — immutable during session
  const priorBestE1RM = ref({}) // { [exerciseId]: number }
  // Exercises that have already triggered a PR flash this session (avoid spam)
  const prFlashedExercises = ref(new Set())

  function epleyE1RM(weightKg, reps) {
    if (!weightKg || !reps) return 0
    return weightKg * (1 + reps / 30)
  }

  async function startOrResumeSession(programDayId, targetDate = todayISO()) {
    const userStore = useUserStore()

    // Clear state from any previous session so stale data doesn't flash during the swap
    currentSession.value = null
    setLogs.value = []
    cardioLogs.value = []
    previousSets.value = {}
    priorBestE1RM.value = {}
    prFlashedExercises.value = new Set()

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
    await loadPriorBestE1RM(targetDate)
    prFlashedExercises.value = new Set()
    return currentSession.value
  }

  async function loadPriorBestE1RM(beforeDate) {
    const userStore = useUserStore()
    const { data } = await supabase
      .from('set_logs')
      .select('exercise_id, weight_kg, reps_done, workout_sessions!inner(user_id, completed, session_date)')
      .eq('workout_sessions.user_id', userStore.user.id)
      .eq('workout_sessions.completed', true)
      .lt('workout_sessions.session_date', beforeDate)
      .not('weight_kg', 'is', null)
      .not('reps_done', 'is', null)

    const map = {}
    for (const log of (data ?? [])) {
      const e = epleyE1RM(log.weight_kg, log.reps_done)
      if (!map[log.exercise_id] || e > map[log.exercise_id]) {
        map[log.exercise_id] = e
      }
    }
    priorBestE1RM.value = map
  }

  // Returns PR payload only if (a) we have prior data for this exercise,
  // (b) the new set beats it, (c) we haven't already flashed this exercise this session.
  function checkAndRecordPR(exerciseId, weightKg, repsDone) {
    if (!weightKg || !repsDone) return null
    if (prFlashedExercises.value.has(exerciseId)) return null
    const prev = priorBestE1RM.value[exerciseId]
    if (!prev) return null
    const newE1RM = epleyE1RM(weightKg, repsDone)
    if (newE1RM <= prev) return null
    prFlashedExercises.value = new Set([...prFlashedExercises.value, exerciseId])
    return {
      isPR: true,
      prevBest: prev,
      newE1RM,
      deltaKg: Math.round((newE1RM - prev) * 10) / 10,
    }
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

  function getCardioLog(blockId) {
    return cardioLogs.value.find(l => l.cardio_block_id === blockId) ?? null
  }

  function markCardioDone(blockId, details = null) {
    if (!currentSession.value) return
    const existing = getCardioLog(blockId)

    const payload = existing
      ? { ...existing, ...(details ?? {}) }
      : {
          id: crypto.randomUUID(),
          session_id: currentSession.value.id,
          cardio_block_id: blockId,
          completed_at: new Date().toISOString(),
          duration_seconds: details?.duration_seconds ?? null,
          avg_hr: details?.avg_hr ?? null,
          notes: details?.notes ?? null,
        }

    if (existing) {
      const idx = cardioLogs.value.indexOf(existing)
      cardioLogs.value.splice(idx, 1, payload)
    } else {
      cardioLogs.value.push(payload)
    }

    const controller = new AbortController()
    setTimeout(() => controller.abort(), 8000)
    const op = existing
      ? supabase.from('cardio_block_logs').update({
          duration_seconds: payload.duration_seconds,
          avg_hr: payload.avg_hr,
          notes: payload.notes,
        }).eq('id', payload.id).abortSignal(controller.signal)
      : supabase.from('cardio_block_logs').insert(payload).abortSignal(controller.signal)

    op.then(({ error }) => { if (error) console.warn('cardio sync failed', error) })
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

  // Aggregate stats for the current session — used by completion overlay & history detail.
  // exercisesById should map exercise_id → { section, is_bodyweight, bars: { weight_kg } }
  // so we can include bar tare in tonnage and filter to main-section work.
  function computeSessionStats(exercisesById) {
    const logs = setLogs.value
    if (!logs.length) return null

    let tonnage = 0
    let rirSum = 0
    let rirCount = 0
    let firstAt = null
    let lastAt = null

    for (const log of logs) {
      const ex = exercisesById?.[log.exercise_id]
      const isMain = !ex || ex.section === 'main'

      if (isMain && log.weight_kg != null && log.reps_done != null) {
        const tare = ex?.bars?.weight_kg ?? 0
        tonnage += (log.weight_kg + tare) * log.reps_done
      }
      if (isMain && log.rir != null) {
        rirSum += log.rir
        rirCount++
      }
      if (log.logged_at) {
        const t = new Date(log.logged_at).getTime()
        if (firstAt == null || t < firstAt) firstAt = t
        if (lastAt == null  || t > lastAt)  lastAt = t
      }
    }

    return {
      setsDone: logs.length,
      tonnage: Math.round(tonnage),
      avgRir: rirCount > 0 ? Math.round((rirSum / rirCount) * 10) / 10 : null,
      durationSec: firstAt && lastAt ? Math.round((lastAt - firstAt) / 1000) : null,
      prCount: prFlashedExercises.value.size,
    }
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
      .select('*, exercises(name, section, order_index, is_bodyweight, bars(weight_kg))')
      .eq('session_id', sessionId)
    if (!data) return []
    const SECTION_ORDER = { rehab: 0, main: 1, cooldown: 2, mobility: 3, cardio: 4 }
    return [...data].sort((a, b) => {
      const sa = SECTION_ORDER[a.exercises?.section] ?? 99
      const sb = SECTION_ORDER[b.exercises?.section] ?? 99
      if (sa !== sb) return sa - sb
      const oa = a.exercises?.order_index ?? 0
      const ob = b.exercises?.order_index ?? 0
      if (oa !== ob) return oa - ob
      return (a.set_number ?? 0) - (b.set_number ?? 0)
    })
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
      .select('cardio_block_id, duration_seconds, avg_hr, notes')
      .eq('session_id', session.id)
    const logByBlock = {}
    for (const l of (logs ?? [])) logByBlock[l.cardio_block_id] = l
    return (blocks ?? []).map(b => {
      const log = logByBlock[b.id]
      return {
        ...b,
        completed: !!log,
        duration_seconds: log?.duration_seconds ?? null,
        avg_hr: log?.avg_hr ?? null,
        log_notes: log?.notes ?? null,
      }
    })
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

  async function fetchCurrentWeekVolumeByMuscle() {
    const userStore = useUserStore()
    // Monday of current week (week starts Monday)
    const now = new Date()
    const day = now.getDay()
    const diff = now.getDate() - day + (day === 0 ? -6 : 1)
    const monday = new Date(now)
    monday.setHours(0, 0, 0, 0)
    monday.setDate(diff)
    const mondayISO = monday.toISOString().slice(0, 10)

    const { data } = await supabase
      .from('set_logs')
      .select('id, reps_done, exercises!inner(muscle_group, section), workout_sessions!inner(user_id, session_date)')
      .eq('workout_sessions.user_id', userStore.user.id)
      .gte('workout_sessions.session_date', mondayISO)
      .not('reps_done', 'is', null)

    const counts = {}
    for (const log of (data ?? [])) {
      const mg = log.exercises?.muscle_group
      if (!mg) continue
      if (log.exercises?.section !== 'main') continue
      counts[mg] = (counts[mg] ?? 0) + 1
    }
    return counts
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

  // Returns [{ exercise_id, exercise_name, avg_rir, count }] for exercises whose RIR average over the last N sessions is below threshold.
  // Used to surface deload candidates: low RIR sustained = chronic high effort = fatigue accumulation.
  async function fetchDeloadCandidates({ lastSessions = 3, threshold = 1, minSamples = 3 } = {}) {
    const userStore = useUserStore()
    const { data: sessions } = await supabase
      .from('workout_sessions')
      .select('id')
      .eq('user_id', userStore.user.id)
      .eq('completed', true)
      .order('session_date', { ascending: false })
      .limit(lastSessions)

    if (!sessions?.length) return []
    const sessionIds = sessions.map(s => s.id)

    const { data: logs } = await supabase
      .from('set_logs')
      .select('exercise_id, rir, exercises(name, section, is_bodyweight)')
      .in('session_id', sessionIds)
      .not('rir', 'is', null)

    const byExercise = {}
    for (const log of (logs ?? [])) {
      // Skip rehab/cooldown/mobility — those aren't supposed to be intensity-driven.
      const section = log.exercises?.section
      if (section && section !== 'main') continue
      if (!byExercise[log.exercise_id]) {
        byExercise[log.exercise_id] = {
          exercise_id: log.exercise_id,
          exercise_name: log.exercises?.name ?? '?',
          rirs: [],
        }
      }
      byExercise[log.exercise_id].rirs.push(log.rir)
    }

    const candidates = []
    for (const ex of Object.values(byExercise)) {
      if (ex.rirs.length < minSamples) continue
      const avg = ex.rirs.reduce((s, r) => s + r, 0) / ex.rirs.length
      if (avg < threshold) {
        candidates.push({
          exercise_id: ex.exercise_id,
          exercise_name: ex.exercise_name,
          avg_rir: Math.round(avg * 10) / 10,
          count: ex.rirs.length,
        })
      }
    }
    candidates.sort((a, b) => a.avg_rir - b.avg_rir)
    return candidates
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
    currentSession, setLogs, cardioLogs, loading, previousSets, priorBestE1RM,
    startOrResumeSession, loadSetLogs, logSet, deleteSetLog,
    completeSession, getSetLog, isSetLogged, getPreviousSet,
    isCardioDone, markCardioDone, unmarkCardioDone, getCardioLog,
    checkAndRecordPR, epleyE1RM, computeSessionStats,
    fetchHistory, fetchSessionDetail, fetchSessionCardio,
    fetchWeightProgress, fetchWeeklyVolume, fetchRIRStats,
    fetchCurrentWeekVolumeByMuscle, fetchDeloadCandidates,
  }
})
