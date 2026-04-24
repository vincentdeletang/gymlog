let sharedCtx = null
function ctx() {
  if (!sharedCtx) sharedCtx = new (window.AudioContext || window.webkitAudioContext)()
  if (sharedCtx.state === 'suspended') sharedCtx.resume().catch(() => {})
  return sharedCtx
}

function tone({ freq, duration = 0.1, startGain = 0.25, endGain = 0.001, delay = 0 }) {
  try {
    const c = ctx()
    const osc = c.createOscillator()
    const gain = c.createGain()
    osc.connect(gain); gain.connect(c.destination)
    const t = c.currentTime + delay
    osc.frequency.setValueAtTime(freq, t)
    gain.gain.setValueAtTime(startGain, t)
    gain.gain.exponentialRampToValueAtTime(endGain, t + duration)
    osc.start(t)
    osc.stop(t + duration)
  } catch {}
}

function vibrate(pattern) {
  try { navigator.vibrate?.(pattern) } catch {}
}

export function useAudio() {
  function playSuccess() {
    try {
      const c = ctx()
      const osc = c.createOscillator()
      const gain = c.createGain()
      osc.connect(gain); gain.connect(c.destination)
      osc.frequency.setValueAtTime(880, c.currentTime)
      osc.frequency.exponentialRampToValueAtTime(1320, c.currentTime + 0.1)
      gain.gain.setValueAtTime(0.3, c.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.3)
      osc.start(c.currentTime)
      osc.stop(c.currentTime + 0.3)
    } catch {}
  }

  function playComplete() {
    try {
      const c = ctx()
      const notes = [523, 659, 784, 1047]
      notes.forEach((freq, i) => {
        const osc = c.createOscillator()
        const gain = c.createGain()
        osc.connect(gain); gain.connect(c.destination)
        const t = c.currentTime + i * 0.15
        osc.frequency.setValueAtTime(freq, t)
        gain.gain.setValueAtTime(0.3, t)
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2)
        osc.start(t)
        osc.stop(t + 0.2)
      })
    } catch {}
  }

  function playPrepTick() { tone({ freq: 600, duration: 0.08 }) }

  function playGo() {
    tone({ freq: 880, duration: 0.12, startGain: 0.3 })
    tone({ freq: 1320, duration: 0.16, startGain: 0.3, delay: 0.12 })
  }

  function playTick10() { tone({ freq: 700, duration: 0.08, startGain: 0.22 }) }
  function playTickHalf() { tone({ freq: 480, duration: 0.28, startGain: 0.3 }) }
  function playTickFinal() { tone({ freq: 1100, duration: 0.08, startGain: 0.28 }) }

  return {
    playSuccess, playComplete,
    playPrepTick, playGo, playTick10, playTickHalf, playTickFinal,
    vibrate,
  }
}
