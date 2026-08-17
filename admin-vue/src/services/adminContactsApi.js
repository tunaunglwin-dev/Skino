import { apiRequest } from './apiClient'

export function fetchContacts(token, filters = {}) {
  const params = new URLSearchParams()

  Object.entries(filters).forEach(([key, value]) => {
    if (value) {
      params.set(key, value)
    }
  })

  const query = params.toString()

  return apiRequest(`/admin/contacts${query ? `?${query}` : ''}`, {
    headers: authHeader(token),
  })
}

export function fetchContact(token, contactId) {
  return apiRequest(`/admin/contacts/${contactId}`, {
    headers: authHeader(token),
  })
}

export function createContact(token, payload) {
  return apiRequest('/admin/contacts', {
    method: 'POST',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

export function updateContact(token, contactId, payload) {
  return apiRequest(`/admin/contacts/${contactId}`, {
    method: 'PUT',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

export function addContactNote(token, contactId, payload) {
  return apiRequest(`/admin/contacts/${contactId}/notes`, {
    method: 'POST',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

export function uploadContactAvatar(token, contactId, file) {
  const form = new FormData()
  form.append('avatar', file)

  return apiRequest(`/admin/contacts/${contactId}/avatar`, {
    method: 'POST',
    headers: authHeader(token),
    body: form,
  })
}

function authHeader(token) {
  return token ? { Authorization: `Bearer ${token}` } : {}
}
