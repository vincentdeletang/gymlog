let sharedCtx = null
function ctx() {
  if (!sharedCtx) sharedCtx = new (window.AudioContext || window.webkitAudioContext)()
  if (sharedCtx.state === 'suspended') sharedCtx.resume().catch(() => {})
  return sharedCtx
}

// Un son posé à un instant précis de l'horloge audio (indépendante des timers JS,
// qui sont ralentis dès que l'écran s'éteint ou que l'onglet passe en arrière-plan).
function toneAt(c, t, { freq, duration = 0.1, startGain = 0.25, endGain = 0.001 }) {
  try {
    const osc = c.createOscillator()
    const gain = c.createGain()
    osc.connect(gain); gain.connect(c.destination)
    osc.frequency.setValueAtTime(freq, t)
    gain.gain.setValueAtTime(startGain, t)
    gain.gain.exponentialRampToValueAtTime(endGain, t + duration)
    osc.start(t)
    osc.stop(t + duration)
    return osc
  } catch { return null }
}

function tone({ delay = 0, ...opts }) {
  try {
    const c = ctx()
    toneAt(c, c.currentTime + delay, opts)
  } catch {}
}

function spawn(c, t, kind) {
  switch (kind) {
    case 'prep': return [toneAt(c, t, { freq: 600, duration: 0.08 })]
    case 'tick': return [toneAt(c, t, { freq: 700, duration: 0.08, startGain: 0.22 })]
    case 'go':   return [
      toneAt(c, t, { freq: 880, duration: 0.12, startGain: 0.3 }),
      toneAt(c, t + 0.12, { freq: 1320, duration: 0.16, startGain: 0.3 }),
    ]
    case 'complete': return [523, 659, 784, 1047].map((f, i) =>
      toneAt(c, t + i * 0.15, { freq: f, duration: 0.2, startGain: 0.3 }))
  }
  return []
}

// Programme toute une séquence de sons d'un coup sur l'horloge audio :
// events = [{ at: secondes depuis maintenant, kind: 'prep' | 'go' | 'tick' | 'complete' }].
// Les sons partent à l'heure même si le JS est ralenti ; cancel() coupe ce qui n'a pas sonné.
// Si le contexte est suspendu, on attend sa reprise avant de poser les sons, sinon tout
// se jouerait d'un bloc à la reprise (le bug « ça sonne 3 s avant la fin, pas consistent »).
export function scheduleSequence(events) {
  const nodes = []
  let cancelled = false
  const place = (c) => {
    if (cancelled) return
    const base = c.currentTime
    for (const e of events) {
      for (const n of spawn(c, base + e.at, e.kind)) if (n) nodes.push(n)
    }
  }
  try {
    const c = ctx()
    if (c.state === 'running') place(c)
    else c.resume().then(() => place(c)).catch(() => {})
  } catch {}
  return {
    cancel() {
      cancelled = true
      for (const n of nodes) { try { n.stop(0) } catch {} }
      nodes.length = 0
    },
  }
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

  return {
    playSuccess, playComplete,
    playPrepTick, playGo, playTick10,
    scheduleSequence,
    vibrate,
  }
}
