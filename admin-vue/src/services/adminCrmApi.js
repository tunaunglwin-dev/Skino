import { apiRequest } from './apiClient'

export function fetchCrmRecords(token, filters = {}) {
  const params = new URLSearchParams()

  Object.entries(filters).forEach(([key, value]) => {
    if (value) {
      params.set(key, value)
    }
  })

  const query = params.toString()

  return apiRequest(`/admin/crm-records${query ? `?${query}` : ''}`, {
    headers: authHeader(token),
  })
}

export function fetchCrmRecord(token, recordId) {
  return apiRequest(`/admin/crm-records/${recordId}`, {
    headers: authHeader(token),
  })
}

export function createCrmRecord(token, payload) {
  return apiRequest('/admin/crm-records', {
    method: 'POST',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

export function updateCrmRecord(token, recordId, payload) {
  return apiRequest(`/admin/crm-records/${recordId}`, {
    method: 'PUT',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

export function addCrmNote(token, recordId, payload) {
  return apiRequest(`/admin/crm-records/${recordId}/notes`, {
    method: 'POST',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

function authHeader(token) {
  return token ? { Authorization: `Bearer ${token}` } : {}
}
