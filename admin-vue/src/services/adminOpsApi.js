import { apiRequest } from './apiClient'

export function fetchCareRoutines(token, filters = {}) {
  return apiRequest(`/admin/care-routines${queryString(filters)}`, {
    headers: authHeader(token),
  })
}

export function fetchScanReviews(token, filters = {}) {
  return apiRequest(`/admin/scan-reviews${queryString(filters)}`, {
    headers: authHeader(token),
  })
}

function queryString(filters) {
  const params = new URLSearchParams()

  Object.entries(filters).forEach(([key, value]) => {
    if (value) {
      params.set(key, value)
    }
  })

  const query = params.toString()

  return query ? `?${query}` : ''
}

function authHeader(token) {
  return token ? { Authorization: `Bearer ${token}` } : {}
}
