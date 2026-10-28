<script setup>
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

// Pictos SVG inline (trait = currentColor, donc bleu sur l'onglet actif) : les emojis se
// rendaient différemment selon le téléphone et faisaient bricolé.
const tabs = [
  { path: '/today',   label: "Aujourd'hui",
    icon: '<path d="M6 7v10M18 7v10M3 10v4M21 10v4M6 12h12"/>' },
  { path: '/history', label: 'Historique',
    icon: '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 3h6v3H9zM9 11h6M9 15h4"/>' },
  { path: '/stats',   label: 'Progression',
    icon: '<path d="M4 20h16M7 16v-5M12 16V7M17 16V9"/>' },
  { path: '/settings',label: 'Réglages',
    icon: '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>' },
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
      <svg class="tab-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
           stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" v-html="tab.icon" />
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
  width: 22px;
  height: 22px;
}

.tab-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}
</style>
