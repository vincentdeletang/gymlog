<script setup>
import { ref } from 'vue'
import { useUserStore } from '@/stores/useUserStore'
import { useRouter } from 'vue-router'

const userStore = useUserStore()
const router = useRouter()

const email = ref('')
const sent = ref(false)
const loading = ref(false)
const error = ref('')

async function submit() {
  if (!email.value.trim()) return
  loading.value = true
  error.value = ''

  const { error: err } = await userStore.sendMagicLink(email.value.trim())
  loading.value = false

  if (err) {
    error.value = err.message
  } else {
    sent.value = true
  }
}
</script>

<template>
  <div class="auth-screen">
    <div class="auth-card">
      <div class="logo">🏋️</div>
      <h1>GymLog</h1>
      <p class="tagline">Ton suivi d'entraînement perso</p>

      <template v-if="!sent">
        <form @submit.prevent="submit" class="auth-form">
          <label class="field-label">Adresse email</label>
          <input
            v-model="email"
            type="email"
            inputmode="email"
            autocomplete="email"
            placeholder="toi@example.com"
            class="email-input"
            required
          />
          <div v-if="error" class="error-msg">{{ error }}</div>
          <button type="submit" class="submit-btn" :disabled="loading">
            <span v-if="loading">Envoi en cours…</span>
            <span v-else>Recevoir mon lien de connexion</span>
          </button>
        </form>
        <p class="auth-note">
          Un lien magique sera envoyé à ton email.<br />
          Pas de mot de passe, sécurité maximale.
        </p>
      </template>

      <template v-else>
        <div class="sent-state">
          <div class="sent-icon">📬</div>
          <h2>Email envoyé !</h2>
          <p>Vérifie ta boîte mail et clique sur le lien pour accéder à GymLog.</p>
          <button class="retry-btn" @click="sent = false">Ressaisir l'email</button>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.auth-screen {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: #0a0e17;
}

.auth-card {
  width: 100%;
  max-width: 380px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.logo {
  font-size: 56px;
  line-height: 1;
}

h1 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 40px;
  font-weight: 800;
  color: #f9fafb;
  margin: 0;
  letter-spacing: 2px;
}

.tagline {
  color: #9ca3af;
  font-size: 15px;
  margin: 0;
}

.auth-form {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 8px;
}

.field-label {
  font-size: 13px;
  color: #9ca3af;
}

.email-input {
  background: #111827;
  border: 2px solid #1f2937;
  border-radius: 12px;
  color: #f9fafb;
  font-size: 16px;
  padding: 14px 16px;
  width: 100%;
  outline: none;
  transition: border-color 0.15s;
}

.email-input:focus {
  border-color: #3b82f6;
}

.error-msg {
  color: #ef4444;
  font-size: 13px;
  padding: 8px 12px;
  background: rgba(239,68,68,0.08);
  border-radius: 8px;
}

.submit-btn {
  background: #3b82f6;
  color: white;
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  border: none;
  border-radius: 12px;
  padding: 14px;
  cursor: pointer;
  transition: background 0.15s;
  min-height: 52px;
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.submit-btn:not(:disabled):active {
  background: #2563eb;
}

.auth-note {
  font-size: 12px;
  color: #6b7280;
  text-align: center;
  line-height: 1.6;
  margin: 0;
}

.sent-state {
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.sent-icon {
  font-size: 48px;
}

.sent-state h2 {
  font-family: 'Barlow Condensed', sans-serif;
  font-size: 26px;
  font-weight: 700;
  color: #10b981;
  margin: 0;
}

.sent-state p {
  color: #9ca3af;
  font-size: 14px;
  line-height: 1.6;
  margin: 0;
}

.retry-btn {
  background: transparent;
  border: 1px solid #374151;
  color: #9ca3af;
  font-size: 14px;
  padding: 10px 20px;
  border-radius: 8px;
  cursor: pointer;
  margin-top: 8px;
}
</style>
