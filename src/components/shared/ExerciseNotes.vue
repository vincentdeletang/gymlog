<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  notes: { type: String, default: '' },
})

const expanded = ref(false)

// Heuristique sans mesure DOM (robuste) : une note "longue" = multi-paragraphes ou
// dépasse ~2 lignes. Les cues courts (rehab/cardio) s'affichent en entier, sans bouton.
const hasMore = computed(() => {
  const n = props.notes || ''
  return n.includes('\n') || n.length > 90
})
</script>

<template>
  <div v-if="notes" class="ex-notes">
    <div class="notes-text" :class="{ clamp: hasMore && !expanded, full: expanded }">{{ notes }}</div>
    <button v-if="hasMore" type="button" class="notes-toggle" @click.stop="expanded = !expanded">
      {{ expanded ? '▴ Réduire' : 'ⓘ Détails' }}
    </button>
  </div>
</template>

<style scoped>
.ex-notes {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
}

.notes-text {
  font-size: 12px;
  color: #6b7280;
  line-height: 1.45;
}

.notes-text.clamp {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  overflow: hidden;
}

.notes-text.full {
  white-space: pre-line;
}

.notes-toggle {
  background: none;
  border: none;
  padding: 2px 0;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.3px;
  color: #60a5fa;
  cursor: pointer;
}

.notes-toggle:active {
  color: #3b82f6;
}
</style>
