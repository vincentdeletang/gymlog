<script setup>
import { useUserStore } from '@/stores/useUserStore'

const userStore = useUserStore()
</script>

<template>
  <div class="level-bar" v-if="userStore.userState">
    <div class="level-info">
      <span class="level-name">{{ userStore.currentLevel.name }}</span>
      <span class="xp-text">{{ userStore.xp }} XP</span>
    </div>
    <div class="progress-track">
      <div
        class="progress-fill"
        :style="{ width: userStore.levelProgress + '%' }"
      />
    </div>
    <div class="streak" v-if="userStore.streak > 0">
      🔥 {{ userStore.streak }} jours
    </div>
  </div>
</template>

<style scoped>
.level-bar {
  padding: 8px 16px 4px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.level-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.level-name {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  color: #3b82f6;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.xp-text {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  color: #9ca3af;
}

.progress-track {
  height: 4px;
  background: #1f2937;
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #8b5cf6);
  border-radius: 2px;
  transition: width 0.5s ease;
}

.streak {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  color: #f59e0b;
  font-weight: 600;
  align-self: flex-end;
}
</style>
