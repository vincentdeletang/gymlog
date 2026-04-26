import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useUserStore } from './useUserStore'

export const useBodyweightStore = defineStore('bodyweight', () => {
  const logs = ref([]) // sorted asc by log_date
  const loading = ref(false)

  async function fetchAll(limit = 365) {
    const userStore = useUserStore()
    if (!userStore.user) return
    loading.value = true
    try {
      const { data } = await supabase
        .from('bodyweight_logs')
        .select('*')
        .eq('user_id', userStore.user.id)
        .order('log_date', { ascending: true })
        .limit(limit)
      logs.value = data ?? []
    } finally {
      loading.value = false
    }
  }

  async function logWeight({ logDate, weightKg, notes = null }) {
    const userStore = useUserStore()
    if (!userStore.user) return null
    const payload = {
      user_id: userStore.user.id,
      log_date: logDate,
      weight_kg: weightKg,
      notes,
    }
    const { data, error } = await supabase
      .from('bodyweight_logs')
      .upsert(payload, { onConflict: 'user_id,log_date' })
      .select()
      .single()
    if (error) {
      console.warn('bodyweight log failed', error)
      return null
    }
    const idx = logs.value.findIndex(l => l.log_date === logDate)
    if (idx >= 0) logs.value.splice(idx, 1, data)
    else logs.value = [...logs.value, data].sort((a, b) => a.log_date.localeCompare(b.log_date))
    return data
  }

  async function deleteLog(id) {
    const { error } = await supabase.from('bodyweight_logs').delete().eq('id', id)
    if (!error) logs.value = logs.value.filter(l => l.id !== id)
    return !error
  }

  return { logs, loading, fetchAll, logWeight, deleteLog }
})
