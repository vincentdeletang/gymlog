<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import BottomNav from '@/components/shared/BottomNav.vue'
import { useUserStore } from '@/stores/useUserStore'

const userStore = useUserStore()
const router = useRouter()

onMounted(async () => {
  await userStore.init()
})
</script>

<template>
  <div class="min-h-screen flex flex-col" style="background:#0a0e17">
    <router-view />
    <BottomNav v-if="userStore.isAuthenticated" />
  </div>
</template>
