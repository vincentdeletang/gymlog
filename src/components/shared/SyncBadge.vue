<script setup>
import { computed } from 'vue'
import { pendingCount, syncState } from '@/lib/offlineQueue'

// 'synced'  → tout est passé chez Supabase
// 'syncing' → envoi en cours
// 'pending' → des logs attendent (offline, ou erreur de sync)
const state = computed(() => {
  if (syncState.value === 'syncing') return 'syncing'
  if (pendingCount.value > 0) return 'pending'
  return 'synced'
})

const label = computed(() => {
  if (state.value === 'syncing') return 'Sync…'
  if (state.value === 'pending') return `${pendingCount.value} en attente`
  return 'Sync'
})
</script>

<template>
  <div class="sync-badge" :class="state" role="status" aria-live="polite">
    <span v-if="state === 'syncing'" class="spinner" aria-hidden="true"></span>
    <span v-else class="icon" aria-hidden="true">{{ state === 'synced' ? '✓' : '⚠' }}</span>
    <span class="txt">{{ label }}</span>
  </div>
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
  padding: 4px 9px;
  border-radius: 999px;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  line-height: 1;
  pointer-events: none;
  transition: opacity 0.2s, background 0.2s, color 0.2s;
}

/* Synced: discret, vert, semi-transparent — juste une confirmation passive */
.sync-badge.synced {
  background: rgba(16, 185, 129, 0.12);
  color: #34d399;
  opacity: 0.6;
}

/* En cours d'envoi: bleu */
.sync-badge.syncing {
  background: rgba(59, 130, 246, 0.18);
  color: #60a5fa;
}

/* En attente / erreur: ambre, bien visible */
.sync-badge.pending {
  background: rgba(245, 158, 11, 0.2);
  color: #fbbf24;
  opacity: 1;
}

.icon { font-size: 12px; }

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
