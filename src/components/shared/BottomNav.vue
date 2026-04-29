<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const navEl = ref(null)

const tabs = [
  { path: '/today',   icon: '🏋️', label: "Aujourd'hui" },
  { path: '/history', icon: '📋', label: 'Historique' },
  { path: '/stats',   icon: '📊', label: 'Progression' },
  { path: '/settings',icon: '⚙️', label: 'Réglages' },
]

// iOS/Android standalone PWAs can lose hit-testing on fixed-position elements
// after returning from background — the nav renders but taps fall through.
// Toggling display + reading offsetHeight forces a layout pass that restores it.
function onVisibility() {
  if (document.visibilityState !== 'visible' || !navEl.value) return
  const el = navEl.value
  el.style.display = 'none'
  void el.offsetHeight
  el.style.display = ''
}

onMounted(() => {
  document.addEventListener('visibilitychange', onVisibility)
  window.addEventListener('pageshow', onVisibility)
})
onUnmounted(() => {
  document.removeEventListener('visibilitychange', onVisibility)
  window.removeEventListener('pageshow', onVisibility)
})
</script>

<template>
  <nav ref="navEl" class="bottom-nav">
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
  transform: translateZ(0);
  will-change: transform;
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
