<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import BottomNav from '@/components/shared/BottomNav.vue'
import { useUserStore } from '@/stores/useUserStore'
import { supabase } from '@/lib/supabase'

const userStore = useUserStore()
const router = useRouter()

onMounted(async () => {
  // Handle Supabase magic link callback
  // Hash router uses #/ prefix → Supabase token lands at #/access_token=...
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
</script>

<template>
  <div class="min-h-screen flex flex-col" style="background:#0a0e17">
    <router-view />
    <BottomNav v-if="userStore.isAuthenticated" />
  </div>
</template>
