<script setup>
import { ref } from 'vue'
import { useUserStore } from '@/stores/useUserStore'
import { useWorkoutStore } from '@/stores/useWorkoutStore'
import { useRouter } from 'vue-router'

const userStore = useUserStore()
const workoutStore = useWorkoutStore()
const router = useRouter()

const exporting = ref(false)
const exported = ref(false)

async function exportData() {
  exporting.value = true
  try {
    const sessions = await workoutStore.fetchHistory(500)
    const data = {
      exported_at: new Date().toISOString(),
      user_id: userStore.user?.id,
      sessions,
    }
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `gymlog-export-${new Date().toISOString().slice(0, 10)}.json`
    a.click()
    URL.revokeObjectURL(url)
    exported.value = true
    setTimeout(() => { exported.value = false }, 3000)
  } finally {
    exporting.value = false
  }
}

async function signOut() {
  await userStore.signOut()
  router.push('/auth')
}
</script>

<template>
  <div class="settings-view">
    <div class="view-header">
      <h1>Réglages</h1>
    </div>

    <!-- Profile section -->
    <div class="settings-section">
      <div class="section-label">Compte</div>
      <div class="setting-row">
        <div class="setting-info">
          <div class="setting-title">Email</div>
          <div class="setting-sub">{{ userStore.user?.email }}</div>
        </div>
      </div>
      <div class="setting-row">
        <div class="setting-info">
          <div class="setting-title">Niveau</div>
          <div class="setting-sub">{{ userStore.currentLevel.name }} · {{ userStore.xp }} XP</div>
        </div>
      </div>
      <div class="setting-row">
        <div class="setting-info">
          <div class="setting-title">Meilleur streak</div>
          <div class="setting-sub">🔥 {{ userStore.streakBest }} jours</div>
        </div>
      </div>
    </div>

    <!-- Science section -->
    <div class="settings-section">
      <div class="section-label">Science & contexte</div>
      <div class="info-card">
        <div class="info-item">
          <span class="info-icon">🧬</span>
          <div>
            <div class="info-title">RIR 2-3 optimal</div>
            <div class="info-desc">Hypertrophie maximale + protection articulaire (Refalo et al. 2024, Schoenfeld 2018). RIR 2 présélectionné par défaut.</div>
          </div>
        </div>
        <div class="info-item">
          <span class="info-icon">📊</span>
          <div>
            <div class="info-title">Volume optimal</div>
            <div class="info-desc">~60 min/semaine en résistance (méta-analyse PMC 2023)</div>
          </div>
        </div>
        <div class="info-item">
          <span class="info-icon">⚠️</span>
          <div>
            <div class="info-title">Signaux d'alerte</div>
            <div class="info-desc">RIR moyen &lt; 1 sur 3 séances → décharge. Streak &gt; 6 jours → repos.</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Export section -->
    <div class="settings-section">
      <div class="section-label">Données</div>
      <button class="action-btn" :disabled="exporting" @click="exportData">
        <span v-if="exporting">Export en cours…</span>
        <span v-else-if="exported">✓ Exporté !</span>
        <span v-else>📤 Exporter l'historique (JSON)</span>
      </button>
      <div class="action-note">Backup de toutes tes séances et sets.</div>
    </div>

    <!-- Sign out -->
    <div class="settings-section">
      <button class="signout-btn" @click="signOut">Se déconnecter</button>
    </div>

    <!-- App info -->
    <div class="app-info">
      <div>GymLog v0.1.0</div>
      <div>Vue 3 + Vite + Supabase</div>
    </div>

    <div style="height: 80px" />
  </div>
</template>

<style scoped>
.settings-view { padding: 0 0 80px; }

.view-header {
  padding: 16px 16px 8px;
}

.view-header h1 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 28px;
  font-weight: 800;
  color: #f9fafb;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.settings-section {
  padding: 8px 16px 16px;
  border-bottom: 1px solid #111827;
}

.section-label {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 11px;
  font-weight: 700;
  color: #6b7280;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  padding: 8px 0;
}

.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 0;
  border-bottom: 1px solid #111827;
}

.setting-row:last-child { border-bottom: none; }

.setting-title {
  font-size: 15px;
  color: #f9fafb;
  font-weight: 500;
}

.setting-sub {
  font-size: 13px;
  color: #9ca3af;
  margin-top: 1px;
}

.info-card {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 12px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-item {
  display: flex;
  gap: 10px;
  align-items: flex-start;
}

.info-icon { font-size: 18px; flex-shrink: 0; margin-top: 1px; }

.info-title {
  font-size: 14px;
  font-weight: 600;
  color: #f9fafb;
  margin-bottom: 2px;
}

.info-desc {
  font-size: 12px;
  color: #9ca3af;
  line-height: 1.5;
}

.action-btn {
  width: 100%;
  min-height: 48px;
  background: #1f2937;
  border: 1px solid #374151;
  border-radius: 12px;
  color: #f9fafb;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.action-btn:not(:disabled):active { background: #374151; }
.action-btn:disabled { opacity: 0.5; }

.action-note {
  font-size: 12px;
  color: #6b7280;
  margin-top: 6px;
}

.signout-btn {
  width: 100%;
  min-height: 48px;
  background: transparent;
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 12px;
  color: #ef4444;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.signout-btn:active { background: rgba(239,68,68,0.08); }

.app-info {
  padding: 16px;
  text-align: center;
  color: #374151;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
</style>
