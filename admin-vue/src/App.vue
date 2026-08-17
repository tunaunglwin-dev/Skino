<script setup>
import { computed, onMounted, ref } from 'vue'
import BootScreen from './components/BootScreen.vue'
import DashboardScreen from './components/DashboardScreen.vue'
import LoginScreen from './components/LoginScreen.vue'
import PasswordResetScreen from './components/PasswordResetScreen.vue'
import { useAdminAuth } from './composables/useAdminAuth'

const auth = useAdminAuth()
const screen = ref(window.location.pathname === '/reset-password' ? 'reset-password' : 'login')
const isAuthenticated = computed(() => Boolean(auth.state.token && auth.state.user))

function openLogin() {
  screen.value = 'login'
  window.history.replaceState({}, '', '/')
}

function openPasswordReset() {
  screen.value = 'reset-password'
  window.history.replaceState({}, '', '/reset-password')
}

onMounted(auth.verifyAdmin)
</script>

<template>
  <main class="admin-shell">
    <BootScreen v-if="auth.state.checking" />

    <template v-else-if="!isAuthenticated">
      <PasswordResetScreen
        v-if="screen === 'reset-password'"
        :loading="auth.state.loading"
        :error="auth.state.error"
        :message="auth.state.message"
        @request-reset="auth.requestPasswordReset"
        @reset-password="auth.resetPassword"
        @back-to-login="openLogin"
      />

      <LoginScreen
        v-else
        :loading="auth.state.loading"
        :error="auth.state.error"
        @login="auth.login"
        @forgot-password="openPasswordReset"
      />
    </template>

    <DashboardScreen
      v-else
      :user="auth.state.user"
      :token="auth.state.token"
      :loading="auth.state.loading"
      @logout="auth.logout"
    />
  </main>
</template>
