<script setup>
import { computed } from 'vue'
import { useProgramStore } from '@/stores/useProgramStore'

const props = defineProps({
  sessions: { type: Array, default: () => [] },
})

const programStore = useProgramStore()

const DAYS = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
const TYPE_COLOR = {
  strength: '#3b82f6',
  cardio: '#f59e0b',
  rest: '#374151',
}

const weekDays = computed(() => {
  const today = new Date()
  const todayDow = today.getDay()
  const startOfWeek = new Date(today)
  startOfWeek.setDate(today.getDate() - todayDow)

  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(startOfWeek)
    d.setDate(startOfWeek.getDate() + i)
    const dateStr = d.toISOString().slice(0, 10)
    const dow = d.getDay()
    const programDay = programStore.programDays.find(pd => pd.day_of_week === dow)
    const session = props.sessions.find(s => s.session_date === dateStr)
    const isToday = dow === todayDow && d.toDateString() === today.toDateString()
    return { day: DAYS[dow], date: d.getDate(), dateStr, programDay, session, isToday, dow }
  })
})
</script>

<template>
  <div class="week-calendar">
    <div
      v-for="day in weekDays"
      :key="day.dateStr"
      class="day-cell"
      :class="{
        today: day.isToday,
        completed: day.session?.completed,
        abandoned: day.session && !day.session.completed,
      }"
    >
      <span class="day-name">{{ day.day }}</span>
      <span class="day-date">{{ day.date }}</span>
      <div
        class="day-dot"
        :style="{ background: day.programDay ? TYPE_COLOR[day.programDay.type] : '#1f2937' }"
      />
    </div>
  </div>
</template>

<style scoped>
.week-calendar {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}

.day-cell {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 4px;
  gap: 3px;
  position: relative;
  overflow: hidden;
}

.day-cell.today {
  border-color: #3b82f6;
}

.day-cell.completed::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(16, 185, 129, 0.08);
}

.day-cell.abandoned::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(156, 163, 175, 0.06);
}

.day-name {
  font-size: 10px;
  color: #6b7280;
  font-weight: 600;
  text-transform: uppercase;
}

.day-date {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  color: #f9fafb;
  line-height: 1;
}

.day-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}
</style>
