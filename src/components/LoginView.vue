<template>
  <main class="auth-page">
    <section class="auth-card">
      <div class="church-brand">
        <div class="church-logo-wrap">
          <img :src="logo" alt="Nembo ya Kanisa la Golani SDA" class="church-logo" />
        </div>
      </div>

      <div class="auth-header">
<<<<<<< HEAD
        <p class="eyebrow">Kanisa la Waadventista wa Sabato Golani</p>

=======
        <p class="eyebrow">KANISA LA WAADVENTISTA WA SABATO GOLANI</p>
>>>>>>> 8c73d91 (adding functionalities for member login with no authentication)
        <h1>Usajili wa Washiriki na Waumini</h1>
        <p class="muted">
<<<<<<< HEAD
          Ingia kwenye mfumo kusajili na kusimamia taarifa za washiriki na waumini wa kanisa.
        </p>
=======
          Ingia kama msimamizi wa mfumo</p>
>>>>>>> 8c73d91 (adding functionalities for member login with no authentication)
      </div>

      <div class="admin-login-label">
        <span></span>
        <strong>ADMIN LOGIN</strong>
        <span></span>
      </div>

      <form class="form-stack" @submit.prevent="login">
        <label>
          <span>Barua pepe</span>
          <input v-model.trim="email" type="email" autocomplete="username" required placeholder="johndoe@mfano.com" />
        </label>

        <label>
          <span>Nenosiri</span>
          <input v-model="password" type="password" autocomplete="current-password" required placeholder="••••••••" />
        </label>

        <p v-if="error" class="error" role="alert">{{ error }}</p>

        <button class="primary-button" type="submit" :disabled="loading">
          {{ loading ? 'Inaingia…' : 'Ingia' }}
        </button>
      </form>

      <div class="member-divider"><span>AU</span></div>

      <button class="member-button" type="button" @click="$emit('continue-as-member')">
        <span class="member-button-icon">→</span>
        <span>
          <strong>Endelea kama Mtumiaji wa kawaida</strong>
          <small>Ingia kwenye mfumo na ujaze taarifa zako</small>
        </span>
      </button>

      <div class="security-note">
        <span class="security-dot"></span>
        
      </div>
    </section>
  </main>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import logo from '../assets/logo.png'

const emit = defineEmits(['admin-logged-in', 'continue-as-member'])
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase()
}

async function login() {
  error.value = ''
  loading.value = true

  try {
    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email: normalizeEmail(email.value),
      password: password.value,
    })

    if (authError || !data?.session) {
      error.value = 'Barua pepe au nenosiri la admin si sahihi.'
      return
    }

    const { data: adminRecord, error: roleError } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', data.session.user.id)
      .maybeSingle()

    if (roleError || !adminRecord) {
      await supabase.auth.signOut()
      error.value = 'Akaunti hii haina ruhusa ya kuingia kama admin. Tumia “Continue as Normal Member”.'
      return
    }

    emit('admin-logged-in', data.session)
  } catch (err) {
    console.error('Unexpected admin login error:', err)
    error.value = 'Imeshindikana kuingia kwa sasa. Jaribu tena.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  padding: 32px 20px; background: radial-gradient(circle at top, rgba(13,33,55,.08), transparent 45%), #f5f7fa;
}
.auth-card { width: 100%; max-width: 460px; padding: 42px 40px 34px; background: #fff; border: 1px solid rgba(13,33,55,.08); border-radius: 20px; box-shadow: 0 24px 60px rgba(13,33,55,.12), 0 4px 12px rgba(13,33,55,.05); }
.church-brand { display:flex; justify-content:center; margin-bottom:22px; }
.church-logo-wrap { width:94px; height:94px; display:flex; align-items:center; justify-content:center; background:#0d2137; border:2px solid #16324a; border-radius:50%; overflow:hidden; }
.church-logo { width:74px; height:74px; object-fit:contain; }
.auth-header { text-align:center; margin-bottom:24px; }
.eyebrow { margin:0 0 7px; color:#d4af1f; font-size:11px; font-weight:800; letter-spacing:.16em; }
h1 { margin:0; color:#0d2137; font-size:25px; } .muted { color:#667085; line-height:1.6; font-size:14px; }
.admin-login-label { display:flex; align-items:center; gap:10px; margin:20px 0; color:#0d2137; font-size:11px; letter-spacing:.12em; }
.admin-login-label span { height:1px; flex:1; background:#e5e7eb; }
.form-stack { display:grid; gap:16px; } label { display:grid; gap:7px; color:#0d2137; font-size:13px; font-weight:700; }
input { width:100%; min-height:46px; padding:10px 12px; border:1px solid #dfe4ea; border-radius:10px; outline:none; } input:focus { border-color:#d4af1f; box-shadow:0 0 0 3px rgba(244,208,63,.15); }
.primary-button { width:100%; min-height:47px; border:0; border-radius:10px; background:#0d2137; color:#fff; font-weight:800; cursor:pointer; } .primary-button:disabled { opacity:.65; cursor:not-allowed; }
.member-divider { display:flex; align-items:center; gap:12px; margin:24px 0 16px; color:#98a2b3; font-size:11px; font-weight:800; } .member-divider:before,.member-divider:after { content:''; height:1px; flex:1; background:#e5e7eb; }
.member-button { width:100%; display:flex; align-items:center; gap:12px; text-align:left; padding:14px; border:1px solid #d4af1f; border-radius:12px; background:#fffdf4; color:#0d2137; cursor:pointer; transition:.2s ease; } .member-button:hover { transform:translateY(-1px); box-shadow:0 10px 22px rgba(212,175,31,.12); }
.member-button-icon { width:38px; height:38px; flex:0 0 38px; display:grid; place-items:center; border-radius:50%; background:#f4d03f; font-size:20px; font-weight:900; }
.member-button strong,.member-button small { display:block; } .member-button small { margin-top:3px; color:#667085; line-height:1.35; }
.error { margin:0; padding:11px 13px; border-radius:9px; font-size:13px; color:#8a2430; background:#fff1f2; }
.security-note { display:flex; align-items:center; gap:8px; margin-top:20px; color:#667085; font-size:12px; line-height:1.5; } .security-dot { width:8px; height:8px; border-radius:50%; background:#22a06b; }
@media (max-width:640px) { .auth-card { padding:30px 22px; } h1 { font-size:22px; } }
</style>
