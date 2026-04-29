<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import BottomNav from '@/components/shared/BottomNav.vue'
import { useUserStore } from '@/stores/useUserStore'
import { supabase } from '@/lib/supabase'

const userStore = useUserStore()
const router = useRouter()

// Force a full remount of BottomNav when the app returns from background.
// On Android Chrome PWAs the freeze/bfcache cycle can leave router-link
// click handlers in a dead state — only a clean remount restores them.
const navKey = ref(0)
function bumpNav() {
  if (document.visibilityState === 'visible') navKey.value++
}

onMounted(async () => {
  document.addEventListener('visibilitychange', bumpNav)
  window.addEventListener('pageshow', bumpNav)

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
  document.removeEventListener('visibilitychange', bumpNav)
  window.removeEventListener('pageshow', bumpNav)
})
</script>

<template>
  <div class="min-h-screen flex flex-col" style="background:#0a0e17">
    <router-view />
    <BottomNav v-if="userStore.isAuthenticated" :key="navKey" />
  </div>
</template>
