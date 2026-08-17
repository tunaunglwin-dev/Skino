import { apiRequest } from './apiClient'

export function fetchAdminProfile(token) {
  return apiRequest('/admin/me', {
    headers: authHeader(token),
  })
}

export function loginAdmin(credentials) {
  return apiRequest('/auth/login', {
    method: 'POST',
    body: JSON.stringify(credentials),
  })
}

export function logoutAdmin(token) {
  return apiRequest('/auth/logout', {
    method: 'POST',
    headers: authHeader(token),
  })
}

export function requestPasswordReset(email) {
  return apiRequest('/auth/forgot-password', {
    method: 'POST',
    body: JSON.stringify({ email }),
  })
}

export function resetPassword(payload) {
  return apiRequest('/auth/reset-password', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

function authHeader(token) {
  return token ? { Authorization: `Bearer ${token}` } : {}
}

