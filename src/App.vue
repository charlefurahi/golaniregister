<template>
  <div class="app-shell">
    <LoginView
      v-if="view === 'welcome'"
      @admin-logged-in="handleAdminLogin"
      @continue-as-member="continueAsMember"
    />

    <div v-else-if="roleLoading" class="role-loading">
      Inatambua akaunti ya admin…
    </div>

    <AdminDashboard
      v-else-if="view === 'admin' && isAdmin && session"
      :session="session"
      @logged-out="handleLogout"
    />

    <MemberProfileView
      v-else-if="view === 'member'"
      :session="null"
      :guest-mode="true"
      @logged-out="handleLogout"
    />
  </div>
</template>

<script setup>
import { onMounted, ref, watch } from 'vue'
import { supabase } from './lib/supabase'
import LoginView from './components/LoginView.vue'
import AdminDashboard from './components/AdminDashboard.vue'
import MemberProfileView from './components/MemberProfileView.vue'

const session = ref(null)
const isAdmin = ref(false)
const roleLoading = ref(false)
const view = ref('welcome')

async function determineRole(nextSession) {
  if (!nextSession) {
    isAdmin.value = false
    roleLoading.value = false
    return
  }

  roleLoading.value = true

  try {
    const { data, error } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', nextSession.user.id)
      .maybeSingle()

    if (error) {
      console.error('Role check failed:', error)
      isAdmin.value = false
      return
    }

    isAdmin.value = !!data
  } finally {
    roleLoading.value = false
  }
}

function continueAsMember() {
  // Normal members do not need credentials. Their form opens directly.
  view.value = 'member'
}

async function handleAdminLogin(nextSession) {
  session.value = nextSession
  await determineRole(nextSession)

  if (isAdmin.value) {
    view.value = 'admin'
  } else {
    await supabase.auth.signOut()
    session.value = null
    isAdmin.value = false
    view.value = 'welcome'
  }
}

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  session.value = data.session

  supabase.auth.onAuthStateChange((_event, nextSession) => {
    session.value = nextSession
  })
})

watch(session, (nextSession) => {
  if (view.value === 'admin') determineRole(nextSession)
})

async function handleLogout() {
  if (session.value) await supabase.auth.signOut()
  session.value = null
  isAdmin.value = false
  view.value = 'welcome'
}
</script>

<style scoped>
.role-loading {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #667085;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: 14px;
}
</style>
