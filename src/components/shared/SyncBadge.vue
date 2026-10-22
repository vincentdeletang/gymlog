<script setup>
import { computed } from 'vue'
import { useOnline } from '@vueuse/core'
import { pendingCount, syncState } from '@/lib/offlineQueue'

const online = useOnline()

// 'synced'  → tout est passé chez Supabase : rien à afficher
// 'syncing' → envoi en cours
// 'pending' → des logs attendent (erreur de sync)
// 'offline' → pas de réseau, les logs partiront au retour
const state = computed(() => {
  if (!online.value) return 'offline'
  if (syncState.value === 'syncing') return 'syncing'
  if (pendingCount.value > 0) return 'pending'
  return 'synced'
})

const label = computed(() => {
  if (state.value === 'offline') return pendingCount.value > 0 ? `Hors ligne · ${pendingCount.value} en attente` : 'Hors ligne'
  if (state.value === 'syncing') return 'Sync…'
  if (state.value === 'pending') return `${pendingCount.value} en attente`
  return ''
})
</script>

<template>
  <transition name="fade">
    <div v-if="state !== 'synced'" class="sync-badge" :class="state" role="status" aria-live="polite">
      <span v-if="state === 'syncing'" class="spinner" aria-hidden="true"></span>
      <span v-else class="icon" aria-hidden="true">{{ state === 'offline' ? '⇅' : '⚠' }}</span>
      <span class="txt">{{ label }}</span>
    </div>
  </transition>
</template>

<style scoped>
.sync-badge {
  position: fixed;
  top: env(safe-area-inset-top);
  right: 8px;
  margin-top: 6px;
  z-index: 20;
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 5px 10px;
  border-radius: 999px;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  line-height: 1;
  pointer-events: none;
}

.sync-badge.syncing {
  background: rgba(59, 130, 246, 0.18);
  color: #60a5fa;
}

.sync-badge.pending {
  background: rgba(245, 158, 11, 0.2);
  color: #fbbf24;
}

.sync-badge.offline {
  background: #374151;
  color: #f9fafb;
}

.icon { font-size: 13px; }

.spinner {
  width: 11px;
  height: 11px;
  border: 2px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: sync-spin 0.7s linear infinite;
}

@keyframes sync-spin {
  to { transform: rotate(360deg); }
}
</style>
