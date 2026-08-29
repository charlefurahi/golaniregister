```vue
<template>
  <main class="auth-page">
    <section class="auth-card">

      <!-- Church Logo -->
      <div class="church-brand">
        <div class="church-logo-wrap">
          <img
            :src="logo"
            alt="Nembo ya Kanisa la Golani SDA"
            class="church-logo"
          />
        </div>
      </div>

      <!-- Header -->
      <div class="auth-header">
        <p class="eyebrow">GOLANI SDA CHURCH</p>

        <h1>Usajili wa Wakazi</h1>

        <p class="muted">
          Ingia kwenye mfumo kusajili na kusimamia taarifa za wakazi wa kanisa.
        </p>
      </div>

      <!-- Login Form -->
      <form
        class="form-stack"
        @submit.prevent="login"
      >
        <label>
          <span>Barua pepe</span>

          <input
            v-model.trim="email"
            type="email"
            autocomplete="username"
            required
            placeholder="admin@example.com"
          />
        </label>

        <label>
          <span>Nenosiri</span>

          <input
            v-model="password"
            type="password"
            autocomplete="current-password"
            required
            placeholder="••••••••"
          />
        </label>

        <p
          v-if="error"
          class="error"
          role="alert"
        >
          {{ error }}
        </p>

        <button
          class="primary-button"
          type="submit"
          :disabled="loading"
        >
          {{ loading ? 'Inaingia…' : 'Ingia kwenye mfumo' }}
        </button>
      </form>

      <!-- Security Notice -->
      <div class="security-note">
        <span class="security-dot"></span>
        Mfumo huu unapatikana kwa wasimamizi walioidhinishwa pekee
      </div>

    </section>
  </main>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import logo from '../assets/logo.png'

const emit = defineEmits(['logged-in'])

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function login() {
  error.value = ''
  loading.value = true

  const { data, error: authError } =
    await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    })

  loading.value = false

  if (authError) {
    error.value = 'Barua pepe au nenosiri si sahihi.'
    return
  }

  emit('logged-in', data.session)
}
</script>

<style scoped>
/* ================================
   AUTH PAGE
================================ */

.auth-page {
  min-height: 100vh;

  display: flex;
  align-items: center;
  justify-content: center;

  padding: 32px 20px;

  background:
    radial-gradient(
      circle at top,
      rgba(13, 33, 55, 0.08),
      transparent 45%
    ),
    #f5f7fa;
}


/* ================================
   LOGIN CARD
================================ */

.auth-card {
  width: 100%;
  max-width: 440px;

  padding: 42px 40px 34px;

  background: #ffffff;

  border: 1px solid rgba(13, 33, 55, 0.08);
  border-radius: 20px;

  box-shadow:
    0 24px 60px rgba(13, 33, 55, 0.12),
    0 4px 12px rgba(13, 33, 55, 0.05);
}


/* ================================
   CHURCH BRAND
================================ */

.church-brand {
  display: flex;
  align-items: center;
  justify-content: center;

  margin-bottom: 22px;
}

.church-logo-wrap {
  width: 94px;
  height: 94px;

  display: flex;
  align-items: center;
  justify-content: center;

  background: #0d2137;

  border: 2px solid #16324a;
  border-radius: 50%;

  box-shadow:
    0 12px 28px rgba(13, 33, 55, 0.22),
    0 0 0 7px rgba(13, 33, 55, 0.05);

  overflow: hidden;
}

.church-logo {
  width: 74px;
  height: 74px;

  display: block;

  object-fit: contain;
}


/* ================================
   HEADER
================================ */

.auth-header {
  text-align: center;

  margin-bottom: 30px;
}

.eyebrow {
  margin: 0 0 9px;

  color: #0d2137;

  font-size: 12px;
  font-weight: 800;

  letter-spacing: 0.16em;

  text-transform: uppercase;
}

.auth-header h1 {
  margin: 0;

  color: #0d2137;

  font-size: 28px;
  line-height: 1.2;

  font-weight: 800;

  letter-spacing: -0.025em;
}

.muted {
  max-width: 340px;

  margin: 12px auto 0;

  color: #667085;

  font-size: 14px;
  line-height: 1.6;
}


/* ================================
   FORM
================================ */

.form-stack {
  display: flex;
  flex-direction: column;

  gap: 20px;
}

.form-stack label {
  display: flex;
  flex-direction: column;

  gap: 8px;

  color: #0d2137;

  font-size: 14px;
  font-weight: 700;
}

.form-stack input {
  width: 100%;
  height: 48px;

  box-sizing: border-box;

  padding: 0 14px;

  color: #0d2137;
  background: #ffffff;

  border: 1px solid #d5dce5;
  border-radius: 10px;

  outline: none;

  font-size: 14px;

  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease,
    background 0.2s ease;
}

.form-stack input::placeholder {
  color: #98a2b3;
}

.form-stack input:hover {
  border-color: #9aa9b8;
}

.form-stack input:focus {
  border-color: #0d2137;

  box-shadow:
    0 0 0 3px rgba(13, 33, 55, 0.09);
}


/* ================================
   ERROR
================================ */

.error {
  margin: -4px 0 0;

  padding: 10px 12px;

  color: #b42318;
  background: #fef3f2;

  border: 1px solid #fecdca;
  border-radius: 8px;

  font-size: 13px;
  line-height: 1.45;
}


/* ================================
   PRIMARY BUTTON
================================ */

.primary-button {
  width: 100%;
  min-height: 50px;

  margin-top: 2px;

  color: #ffffff;
  background: #0d2137;

  border: 1px solid #0d2137;
  border-radius: 10px;

  cursor: pointer;

  font-size: 14px;
  font-weight: 800;

  letter-spacing: 0.01em;

  transition:
    transform 0.2s ease,
    background 0.2s ease,
    box-shadow 0.2s ease;
}

.primary-button:hover:not(:disabled) {
  background: #16324a;

  transform: translateY(-1px);

  box-shadow:
    0 10px 24px rgba(13, 33, 55, 0.22);
}

.primary-button:active:not(:disabled) {
  transform: translateY(0);
}

.primary-button:disabled {
  opacity: 0.65;

  cursor: not-allowed;
}


/* ================================
   SECURITY NOTE
================================ */

.security-note {
  display: flex;
  align-items: center;
  justify-content: center;

  gap: 7px;

  margin-top: 24px;

  color: #667085;

  font-size: 12px;
  font-weight: 600;

  text-align: center;
}

.security-dot {
  width: 7px;
  height: 7px;

  flex: 0 0 auto;

  background: #0d2137;

  border-radius: 50%;
}


/* ================================
   MOBILE
================================ */

@media (max-width: 640px) {
  .auth-page {
    padding: 20px 14px;
  }

  .auth-card {
    padding: 34px 22px 28px;

    border-radius: 16px;
  }

  .church-logo-wrap {
    width: 84px;
    height: 84px;
  }

  .church-logo {
    width: 66px;
    height: 66px;
  }

  .auth-header h1 {
    font-size: 24px;
  }

  .security-note {
    line-height: 1.5;
  }
}
</style>
```
