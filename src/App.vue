<template>
  <div class="app-shell">
    <LoginView v-if="!session" @logged-in="session = $event" />
    <AdminDashboard v-else :session="session" @logged-out="handleLogout" />
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { supabase } from './lib/supabase'
import LoginView from './components/LoginView.vue'
import AdminDashboard from './components/AdminDashboard.vue'

const session = ref(null)

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  session.value = data.session

  supabase.auth.onAuthStateChange((_event, nextSession) => {
    session.value = nextSession
  })
})

async function handleLogout() {
  await supabase.auth.signOut()
  session.value = null
}
</script>