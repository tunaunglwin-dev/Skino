import { reactive } from 'vue'
import {
  fetchAdminProfile,
  loginAdmin,
  logoutAdmin,
  requestPasswordReset as sendPasswordResetRequest,
  resetPassword as sendPasswordReset,
} from '../services/adminAuthApi'

const TOKEN_KEY = 'skin_care_admin_token'
const legacyToken = localStorage.getItem(TOKEN_KEY) || ''
if (legacyToken) {
  localStorage.removeItem(TOKEN_KEY)
}

export function useAdminAuth() {
  const state = reactive({
    token: sessionStorage.getItem(TOKEN_KEY) || legacyToken,
    user: null,
    loading: false,
    checking: true,
    error: '',
    message: '',
  })

  function setToken(token) {
    state.token = token
    sessionStorage.setItem(TOKEN_KEY, token)
  }

  function clearSession() {
    state.token = ''
    state.user = null
    sessionStorage.removeItem(TOKEN_KEY)
  }

  function resetFeedback() {
    state.error = ''
    state.message = ''
  }

  async function verifyAdmin() {
    if (!state.token) {
      state.checking = false
      return
    }

    try {
      const payload = await fetchAdminProfile(state.token)
      state.user = payload.data
    } catch {
      clearSession()
    } finally {
      state.checking = false
    }
  }

  async function login(credentials) {
    state.loading = true
    resetFeedback()

    try {
      const payload = await loginAdmin(credentials)
      setToken(payload.data.token)
      await verifyAdmin()

      if (!state.user) {
        clearSession()
        state.error = 'This account is not allowed to access the admin dashboard.'
      }
    } catch (error) {
      state.error = error.message
    } finally {
      state.loading = false
    }
  }

  async function logout() {
    state.loading = true

    try {
      await logoutAdmin(state.token)
    } catch {
      // Local logout still wins if the network is unavailable.
    } finally {
      clearSession()
      state.loading = false
    }
  }

  async function requestPasswordReset(email) {
    state.loading = true
    resetFeedback()

    try {
      const payload = await sendPasswordResetRequest(email)
      state.message = payload.message
    } catch (error) {
      state.error = error.message
    } finally {
      state.loading = false
    }
  }

  async function resetPassword(payload) {
    state.loading = true
    resetFeedback()

    try {
      const response = await sendPasswordReset(payload)
      state.message = response.message
    } catch (error) {
      state.error = error.message
    } finally {
      state.loading = false
    }
  }

  return {
    state,
    verifyAdmin,
    login,
    logout,
    requestPasswordReset,
    resetPassword,
  }
}
