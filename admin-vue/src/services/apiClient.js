const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

export async function apiRequest(path, options = {}) {
  const isFormData = options.body instanceof FormData
  const headers = {
    Accept: 'application/json',
    ...(!isFormData ? { 'Content-Type': 'application/json' } : {}),
    ...options.headers,
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  })

  const payload = await response.json().catch(() => ({}))

  if (!response.ok) {
    const message =
      payload.message ||
      payload.errors?.display_name?.[0] ||
      payload.errors?.contact_type?.[0] ||
      payload.errors?.email?.[0] ||
      payload.errors?.gmail_email?.[0] ||
      payload.errors?.password?.[0] ||
      payload.errors?.token?.[0] ||
      payload.errors?.body?.[0] ||
      'The request could not be completed.'

    throw new Error(message)
  }

  return payload
}
