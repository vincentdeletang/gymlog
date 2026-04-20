import { ref, computed, onUnmounted } from 'vue'

export function useTimer(initialSeconds = 0) {
  const seconds = ref(initialSeconds)
  const running = ref(false)
  let interval = null

  const formatted = computed(() => {
    const m = Math.floor(seconds.value / 60).toString().padStart(2, '0')
    const s = (seconds.value % 60).toString().padStart(2, '0')
    return `${m}:${s}`
  })

  function start() {
    if (running.value) return
    running.value = true
    interval = setInterval(() => { seconds.value++ }, 1000)
  }

  function pause() {
    running.value = false
    clearInterval(interval)
    interval = null
  }

  function reset() {
    pause()
    seconds.value = 0
  }

  function toggle() {
    running.value ? pause() : start()
  }

  onUnmounted(() => clearInterval(interval))

  return { seconds, running, formatted, start, pause, reset, toggle }
}
