<script setup>
import { ref } from 'vue'

defineProps({
  markdown: String,
})
const emit = defineEmits(['close'])

const copied = ref(false)

async function copyFromButton(text) {
  try {
    await navigator.clipboard.writeText(text)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch {
    copied.value = false
  }
}
</script>

<template>
  <div class="export-overlay" @click.self="emit('close')">
    <div class="export-panel">
      <div class="export-header">
        <h3>Export pour analyse IA</h3>
        <button class="close-btn" @click="emit('close')">✕</button>
      </div>

      <p class="export-hint">
        Copie le bloc ci-dessous et colle-le dans Claude / ChatGPT pour obtenir une analyse de ton programme.
      </p>

      <pre class="export-md">{{ markdown }}</pre>

      <div class="export-actions">
        <button class="copy-btn" @click="copyFromButton(markdown)">
          <span v-if="copied">✓ Copié</span>
          <span v-else>📋 Copier le markdown</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.export-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 14, 23, 0.85);
  backdrop-filter: blur(4px);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}

.export-panel {
  width: 100%;
  max-width: 560px;
  max-height: 90vh;
  background: #0f1623;
  border: 1px solid #1f2937;
  border-radius: 14px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
}

.export-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.export-header h3 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 20px;
  font-weight: 800;
  color: #f9fafb;
  margin: 0;
  letter-spacing: 0.5px;
}

.close-btn {
  background: transparent;
  border: none;
  color: #6b7280;
  font-size: 18px;
  cursor: pointer;
  padding: 4px 8px;
}

.close-btn:active { color: #f9fafb; }

.export-hint {
  font-size: 13px;
  color: #9ca3af;
  margin: 0;
  line-height: 1.4;
}

.export-md {
  flex: 1;
  overflow: auto;
  background: #0a0e17;
  border: 1px solid #1f2937;
  border-radius: 10px;
  color: #e5e7eb;
  font-family: 'SF Mono', Menlo, monospace;
  font-size: 11px;
  line-height: 1.5;
  padding: 12px;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  max-height: 50vh;
}

.export-actions {
  display: flex;
  gap: 8px;
}

.copy-btn {
  flex: 1;
  min-height: 48px;
  background: #3b82f6;
  border: none;
  border-radius: 12px;
  color: white;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 1px;
  cursor: pointer;
  transition: background 0.15s, transform 0.1s;
}

.copy-btn:active {
  background: #2563eb;
  transform: scale(0.98);
}
</style>
