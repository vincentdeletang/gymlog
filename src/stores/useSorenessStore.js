import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useUserStore } from './useUserStore'
import { todayISO } from '@/lib/formatDate'

export const useSorenessStore = defineStore('soreness', () => {
  const todayLogs = ref([]) // soreness logs for today, by body_part
  const history = ref([])

  async function fetchToday() {
    const userStore = useUserStore()
    if (!userStore.user) return
    const { data } = await supabase
      .from('soreness_logs')
      .select('*')
      .eq('user_id', userStore.user.id)
      .eq('log_date', todayISO())
    todayLogs.value = data ?? []
  }

  async function fetchHistory(bodyPart, days = 90) {
    const userStore = useUserStore()
    if (!userStore.user) return []
    const since = new Date()
    since.setDate(since.getDate() - days)
    const { data } = await supabase
      .from('soreness_logs')
      .select('*')
      .eq('user_id', userStore.user.id)
      .eq('body_part', bodyPart)
      .gte('log_date', since.toISOString().slice(0, 10))
      .order('log_date', { ascending: true })
    history.value = data ?? []
    return history.value
  }

  function getTodayLevel(bodyPart) {
    return todayLogs.value.find(l => l.body_part === bodyPart)?.level ?? null
  }

  async function logToday({ bodyPart, level, notes = null }) {
    const userStore = useUserStore()
    if (!userStore.user) return null
    const payload = {
      user_id: userStore.user.id,
      log_date: todayISO(),
      body_part: bodyPart,
      level,
      notes,
    }
    const { data, error } = await supabase
      .from('soreness_logs')
      .upsert(payload, { onConflict: 'user_id,log_date,body_part' })
      .select()
      .single()
    if (error) {
      console.warn('soreness log failed', error)
      return null
    }
    const idx = todayLogs.value.findIndex(l => l.body_part === bodyPart)
    if (idx >= 0) todayLogs.value.splice(idx, 1, data)
    else todayLogs.value.push(data)
    return data
  }

  return { todayLogs, history, fetchToday, fetchHistory, getTodayLevel, logToday }
})
