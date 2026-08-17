import { apiRequest } from './apiClient'

export function fetchTrainingSamples(token, filters = {}) {
  const params = new URLSearchParams()

  Object.entries(filters).forEach(([key, value]) => {
    if (value) {
      params.set(key, value)
    }
  })

  const query = params.toString()

  return apiRequest(`/admin/training-samples${query ? `?${query}` : ''}`, {
    headers: authHeader(token),
  })
}

export function reviewTrainingSample(token, sampleId, payload) {
  return apiRequest(`/admin/training-samples/${sampleId}/review`, {
    method: 'POST',
    headers: authHeader(token),
    body: JSON.stringify(payload),
  })
}

function authHeader(token) {
  return token ? { Authorization: `Bearer ${token}` } : {}
}
