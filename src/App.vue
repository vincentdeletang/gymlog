<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import BottomNav from '@/components/shared/BottomNav.vue'
import SyncBadge from '@/components/shared/SyncBadge.vue'
import { useUserStore } from '@/stores/useUserStore'
import { supabase } from '@/lib/supabase'

const userStore = useUserStore()
const router = useRouter()

// Android Chrome PWAs suspend the renderer after ~1s in background, leaving
// vue-router in a zombie state where pushes don't trigger re-renders. The
// only reliable recovery is a full reload — session + workout state are in
// Supabase/localStorage so nothing is lost.
const navKey = ref(0)
let hiddenAt = null
const RELOAD_AFTER_MS = 1000

function onVisibility() {
  if (document.visibilityState === 'hidden') {
    hiddenAt = Date.now()
    return
  }
  if (document.visibilityState !== 'visible') return
  const elapsed = hiddenAt ? Date.now() - hiddenAt : 0
  hiddenAt = null
  if (elapsed > RELOAD_AFTER_MS) {
    window.location.reload()
    return
  }
  navKey.value++
}

function onPageShow(event) {
  if (event.persisted) window.location.reload()
}

onMounted(async () => {
  document.addEventListener('visibilitychange', onVisibility)
  window.addEventListener('pageshow', onPageShow)

  const hash = window.location.hash
  if (hash.includes('access_token=')) {
    const hashStr = hash.startsWith('#/') ? hash.substring(2) : hash.substring(1)
    const params = new URLSearchParams(hashStr)
    const accessToken = params.get('access_token')
    const refreshToken = params.get('refresh_token')

    if (accessToken && refreshToken) {
      await supabase.auth.setSession({ access_token: accessToken, refresh_token: refreshToken })
      window.history.replaceState(null, '', window.location.pathname)
      await userStore.init()
      router.replace('/today')
      return
    }
  }

  await userStore.init()
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibility)
  window.removeEventListener('pageshow', onPageShow)
})
</script>

<template>
  <div class="min-h-screen flex flex-col" style="background:#0a0e17">
    <router-view />
    <SyncBadge v-if="userStore.isAuthenticated" />
    <BottomNav v-if="userStore.isAuthenticated" :key="navKey" />
  </div>
</template>
