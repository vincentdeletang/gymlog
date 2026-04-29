<script setup>
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const tabs = [
  { path: '/today',   icon: '🏋️', label: "Aujourd'hui" },
  { path: '/history', icon: '📋', label: 'Historique' },
  { path: '/stats',   icon: '📊', label: 'Progression' },
  { path: '/settings',icon: '⚙️', label: 'Réglages' },
]

// Imperative push instead of <router-link> — vue-router's click interceptor
// can stay zombie after Chrome's bfcache cycle even when the router itself is
// alive. Calling router.push directly bypasses the interceptor entirely.
function go(path) {
  if (route.path === path) return
  router.push(path).catch(() => {})
}
</script>

<template>
  <nav class="bottom-nav">
    <button
      v-for="tab in tabs"
      :key="tab.path"
      type="button"
      class="tab-item"
      :class="{ active: route.path === tab.path }"
      @click="go(tab.path)"
    >
      <span class="tab-icon">{{ tab.icon }}</span>
      <span class="tab-label">{{ tab.label }}</span>
    </button>
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
  background: transparent;
  border: none;
  padding: 0;
  font: inherit;
  cursor: pointer;
}

.tab-item.active {
  color: #3b82f6;
}

.tab-item:active {
  background: rgba(255, 255, 255, 0.06);
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
