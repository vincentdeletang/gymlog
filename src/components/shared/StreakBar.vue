<script setup>
import { useUserStore } from '@/stores/useUserStore'

const userStore = useUserStore()
</script>

<template>
  <div class="streak-bar" v-if="userStore.userState && userStore.streak > 0">
    <span class="streak">🔥 {{ userStore.streak }} jours de suite</span>
  </div>
</template>

<style scoped>
.streak-bar {
  padding: 8px 16px 4px;
}

.streak {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 14px;
  color: #f59e0b;
  font-weight: 700;
  letter-spacing: 0.5px;
}
</style>
