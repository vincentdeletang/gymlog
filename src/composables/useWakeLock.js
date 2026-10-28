// Écran allumé tant qu'une séance est en cours (QoL du 28/10/2026).
// Sans ça, l'écran se verrouille entre deux séries, et au retour App.vue recharge toute la page
// (contournement du renderer Android gelé) : déverrouiller + recharger à chaque série.
// Le navigateur relâche le verrou quand la page passe en arrière-plan : on le redemande au retour.

import { watch, onUnmounted } from 'vue'

export function useWakeLock(activeRef) {
  let sentinel = null

  async function acquire() {
    if (sentinel || !('wakeLock' in navigator) || document.visibilityState !== 'visible') return
    try {
      sentinel = await navigator.wakeLock.request('screen')
      sentinel.addEventListener?.('release', () => { sentinel = null })
    } catch { sentinel = null }
  }

  function release() {
    try { sentinel?.release?.() } catch {}
    sentinel = null
  }

  function onVisibility() {
    if (document.visibilityState === 'visible' && activeRef.value) acquire()
  }

  document.addEventListener('visibilitychange', onVisibility)
  watch(activeRef, (on) => { on ? acquire() : release() }, { immediate: true })

  onUnmounted(() => {
    document.removeEventListener('visibilitychange', onVisibility)
    release()
  })
}
