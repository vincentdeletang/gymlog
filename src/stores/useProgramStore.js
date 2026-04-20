import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useProgramStore = defineStore('program', () => {
  const activeProgram = ref(null)
  const programDays = ref([])
  const exercises = ref([])
  const cardioBlocks = ref([])
  const loading = ref(false)

  const todayDay = computed(() => new Date().getDay()) // 0=Sun..6=Sat

  const todayProgramDay = computed(() =>
    programDays.value.find(d => d.day_of_week === todayDay.value) ?? null
  )

  const todayExercises = computed(() => {
    if (!todayProgramDay.value) return []
    return exercises.value
      .filter(e => e.program_day_id === todayProgramDay.value.id)
      .sort((a, b) => a.order_index - b.order_index)
  })

  const todayCardioBlocks = computed(() => {
    if (!todayProgramDay.value) return []
    return cardioBlocks.value
      .filter(b => b.program_day_id === todayProgramDay.value.id)
      .sort((a, b) => a.order_index - b.order_index)
  })

  const exercisesBySection = computed(() => {
    const rehab = todayExercises.value.filter(e => e.section === 'rehab')
    const main  = todayExercises.value.filter(e => e.section === 'main')
    return { rehab, main }
  })

  async function fetchActiveProgram() {
    loading.value = true
    try {
      const { data: prog } = await supabase
        .from('programs')
        .select('*')
        .eq('is_active', true)
        .single()

      if (!prog) return
      activeProgram.value = prog

      const { data: days } = await supabase
        .from('program_days')
        .select('*')
        .eq('program_id', prog.id)
        .order('day_of_week')

      programDays.value = days ?? []

      if (days?.length) {
        const dayIds = days.map(d => d.id)

        const [{ data: exs }, { data: cbs }] = await Promise.all([
          supabase.from('exercises').select('*').in('program_day_id', dayIds).order('order_index'),
          supabase.from('cardio_blocks').select('*').in('program_day_id', dayIds).order('order_index'),
        ])

        exercises.value = exs ?? []
        cardioBlocks.value = cbs ?? []
      }
    } finally {
      loading.value = false
    }
  }

  function getProgramDayById(id) {
    return programDays.value.find(d => d.id === id) ?? null
  }

  function getExercisesForDay(dayId) {
    return exercises.value
      .filter(e => e.program_day_id === dayId)
      .sort((a, b) => a.order_index - b.order_index)
  }

  function getCardioBlocksForDay(dayId) {
    return cardioBlocks.value
      .filter(b => b.program_day_id === dayId)
      .sort((a, b) => a.order_index - b.order_index)
  }

  return {
    activeProgram, programDays, exercises, cardioBlocks, loading,
    todayDay, todayProgramDay, todayExercises, todayCardioBlocks, exercisesBySection,
    fetchActiveProgram, getProgramDayById, getExercisesForDay, getCardioBlocksForDay,
  }
})
