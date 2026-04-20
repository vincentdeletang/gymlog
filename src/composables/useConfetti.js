import confetti from 'canvas-confetti'

export function useConfetti() {
  function celebrate() {
    const duration = 3000
    const end = Date.now() + duration

    const colors = ['#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ef4444']

    ;(function frame() {
      confetti({
        particleCount: 5,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors,
      })
      confetti({
        particleCount: 5,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors,
      })
      if (Date.now() < end) requestAnimationFrame(frame)
    })()
  }

  return { celebrate }
}
