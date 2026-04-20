<script setup>
import { useRoute } from 'vue-router'

const route = useRoute()

const tabs = [
  { path: '/today',   icon: '🏋️', label: "Aujourd'hui" },
  { path: '/history', icon: '📋', label: 'Historique' },
  { path: '/stats',   icon: '📊', label: 'Progression' },
  { path: '/settings',icon: '⚙️', label: 'Réglages' },
]
</script>

<template>
  <nav class="bottom-nav">
    <router-link
      v-for="tab in tabs"
      :key="tab.path"
      :to="tab.path"
      class="tab-item"
      :class="{ active: route.path === tab.path }"
    >
      <span class="tab-icon">{{ tab.icon }}</span>
      <span class="tab-label">{{ tab.label }}</span>
    </router-link>
  </nav>
</template>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 64px;
  background: #111827;
  border-top: 1px solid #1f2937;
  display: flex;
  align-items: stretch;
  z-index: 30;
  padding-bottom: env(safe-area-inset-bottom);
}

.tab-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  text-decoration: none;
  color: #9ca3af;
  transition: color 0.15s;
  min-height: 44px;
}

.tab-item.active {
  color: #3b82f6;
}

.tab-icon {
  font-size: 20px;
  line-height: 1;
}

.tab-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}
</style>
