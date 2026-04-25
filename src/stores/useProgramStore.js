import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { todayISO, dayOfWeekFromISO } from '@/lib/formatDate'

export const useProgramStore = defineStore('program', () => {
  const activeProgram = ref(null)
  const programDays = ref([])
  const exercises = ref([])
  const cardioBlocks = ref([])
  const bars = ref([])
  const loading = ref(false)

  const activeDate = ref(todayISO())

  function setActiveDate(d) {
    activeDate.value = d ?? todayISO()
  }

  const activeDay = computed(() => dayOfWeekFromISO(activeDate.value))

  const activeProgramDay = computed(() =>
    programDays.value.find(d => d.day_of_week === activeDay.value) ?? null
  )

  const activeExercises = computed(() => {
    if (!activeProgramDay.value) return []
    return exercises.value
      .filter(e => e.program_day_id === activeProgramDay.value.id)
      .sort((a, b) => a.order_index - b.order_index)
  })

  const activeCardioBlocks = computed(() => {
    if (!activeProgramDay.value) return []
    return cardioBlocks.value
      .filter(b => b.program_day_id === activeProgramDay.value.id)
      .sort((a, b) => a.order_index - b.order_index)
  })

  const exercisesBySection = computed(() => {
    const rehab    = activeExercises.value.filter(e => e.section === 'rehab')
    const main     = activeExercises.value.filter(e => e.section === 'main')
    const cooldown = activeExercises.value.filter(e => e.section === 'cooldown')
    const mobility = activeExercises.value.filter(e => e.section === 'mobility')
    return { rehab, main, cooldown, mobility }
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

      const { data: barsData } = await supabase.from('bars').select('*').order('weight_kg')
      bars.value = barsData ?? []

      if (days?.length) {
        const dayIds = days.map(d => d.id)

        const [{ data: exs }, { data: cbs }] = await Promise.all([
          supabase.from('exercises').select('*, bars(id, name, weight_kg)').in('program_day_id', dayIds).order('order_index'),
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

  async function updateExerciseBar(exerciseId, barId) {
    const { error } = await supabase
      .from('exercises')
      .update({ bar_id: barId })
      .eq('id', exerciseId)
    if (!error) {
      const ex = exercises.value.find(e => e.id === exerciseId)
      if (ex) {
        ex.bar_id = barId
        ex.bars = barId ? (bars.value.find(b => b.id === barId) ?? null) : null
      }
    }
    return !error
  }

  return {
    activeProgram, programDays, exercises, cardioBlocks, bars, loading,
    activeDate, setActiveDate,
    activeDay, activeProgramDay, activeExercises, activeCardioBlocks, exercisesBySection,
    fetchActiveProgram, getProgramDayById, getExercisesForDay, getCardioBlocksForDay,
    updateExerciseBar,
  }
})
